class DatabaseLayer
	def initialize
	end

	#update or insert a row using candidate.Id as the primary key. Do whatever you want with other fields
	def upsert_candidate(candidate)
		puts "DB::upsert #{candidate.Id} (#{candidate.FirstName} #{candidate.LastName})"
		puts "..."
	end

	#delete the row using candidate.Id as primary key
	def delete_candidate(accountID)
		puts "DB::delete #{accountID}"
	end

end