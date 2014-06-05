require 'restforce'
require 'faye'

$stdout.sync = true

begin

  Restforce.log = true

  # Initialize a client with your username/password.
   client = Restforce.new :host           => 'login.salesforce.com',
                          :username       => 'drogershb@ramseysolutions.com',
                          :password       => 'ramsey76',
                          :security_token => '',
                          :client_id      => '3MVG9JZ_r.QzrS7gUwHFeB4xA.wcDH3RA5OCJXGNhB3W1urP6vCvZ_WI.2BhACyYs7jtjdT8LkWpvUT4DOcz8', 
                          :client_secret  => '8099833096990361315' 

  # simply for debugging
  puts client

  client.authenticate!
  puts 'Successfully authenticated to salesforce.com'

  EM.run do
    puts "inside EM.run"

    # Subscribe to the PushTopic.
    client.subscribe 'LogEntries' do |message|
      puts message.inspect
      
    end 
  end

rescue
   puts "Could not authenticate. Not listening for streaming events."
end