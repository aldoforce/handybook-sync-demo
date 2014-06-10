require 'faye'
require 'pry'
require 'rufus-scheduler'

#declare lib folder
$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), 'lib' ) )
require 'Salesforce_Connector'
require 'database_layer'

#display logs
$stdout.sync = true

class Daemon
  def initialize()
    #define salesforce connector
    @sfdc = Salesforce_Connector.new

    #database abstract layer
    @db = DatabaseLayer.new
  end

  def kickoff
    begin
      credentials = @sfdc.client.authenticate!
      puts 'Successfully authenticated to salesforce.com'
     
      #set variables
      server        = credentials.instance_url
      topic         = 'LogEntries'
      access_token  = credentials.access_token
      token_type    = 'OAuth'

      #custom Faye client
      client = Faye::Client.new("#{server}/cometd/27.0/")
      client.set_header('Authorization', "#{token_type} #{access_token}")

      puts "Starting event machine loop..."
      #Event Machine loop
      EM.run do
        client.subscribe("/topic/#{topic}") do |message|
          sobjectID = message["sobject"]["SObjectID__c"]
          logID     = message["sobject"]["Id"]

          #process event
          self.request_update(logID, sobjectID)
        end 
      end
    rescue Exception => e
       puts "Could not authenticate. Not listening for streaming events."
       puts e
    end
  end

  def request_update(logID, accountID)
    begin
      puts "  Processing logID:#{logID} accountID:#{accountID}"

      #get candidate
      candidate = @sfdc.get_candidate(accountID)      
      
      puts "    Sending to external Database: #{candidate.Id}"

      #upsert
      @db.upsert_candidate(candidate)

      #destroy log
      @sfdc.destroy_log(logID)

      puts "    log entry deleted"
    rescue Faraday::Error::ResourceNotFound => not_found
      puts "The candidate was not found because it was deleted."
      puts "Deleting on external Database: #{accountID}"     
      
      #delete
      @db.delete_candidate(accountID)

      #destroy log
      @sfdc.destroy_log(logID)
    rescue Exception => ex
      puts ex
    end
  end

  def resume_processing
    puts "Processing pending transactions..."
    logs = @sfdc.client.query("SELECT Id, SObjectID__c FROM Log_Entry__c ORDER BY createddate")

    puts "  #{logs.size} transactions found."
    logs.each do |log|
      self.request_update(log.Id, log.SObjectID__c)
    end

    puts "Finished pending transactions, system in-sync again."
  end
end


# Scheduler
scheduler = Rufus::Scheduler.new

# Main process, repeat each 2hrs
scheduler.every '2h', :first_in => '1s' do
  # init
  puts "Daemon init"
  d = Daemon.new

  # resume pending
  d.resume_processing

  # kick off listener
  d.kickoff  
end

#submit thread
scheduler.join

