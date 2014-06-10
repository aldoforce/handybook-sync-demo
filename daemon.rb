require 'faye'
require 'pry'

#declare lib folder
$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), 'lib' ) )
require 'Salesforce_Connector'

$stdout.sync = true

class Daemon
  def initialize()
    #define salesforce connector
    @sfdc = Salesforce_Connector.new
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

      candidate = @sfdc.get_candidate(accountID)
      
      puts "    Sending to external Database: #{candidate.Id}"

      #destroy log
      @sfdc.destroy_log(logID)

      puts "    log entry deleted"
    rescue Exception => ex
      raise ex
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

# Main process
puts "Daemon init"
d = Daemon.new
d.resume_processing
d.kickoff