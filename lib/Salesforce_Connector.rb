require 'restforce'

class Salesforce_Connector
	attr_accessor :client
	
	def initialize
		Restforce.log = ENV['SF_RESTFORCE_DEBUG'] == "false" ? false : true
		@client = Restforce.new :host 					=> ENV['SF_LOGIN_HOST'],
														:username 			=> ENV['SF_USERNAME'],
													  :password       => ENV['SF_PASSWORD'],
													  :security_token => ENV['SF_TOKEN'],
													  :client_id      => ENV['SF_EXTERNAL_APP_CLIENT_ID'], 
													  :client_secret  => ENV['SF_EXTERNAL_APP_CLIENT_SECRET'] 
	end

	def destroy_log(logID)
		@client.destroy('Log_Entry__c', logID)
	end

	def get_candidate(accountID)		
		@client.select(
			'Account', 
			accountID,
			[
				"Id", "FirstName", "LastName", "PersonEmail", "Phone", "Location__c", "Apply_as__c", 
				"BillingStreet", "BillingCity", "BillingState", "BillingPostalCode",
				"Receive_Packages_at_this_Address__c", "Status__c", "Encoded_Id__c" 
			]
		)
	end
end