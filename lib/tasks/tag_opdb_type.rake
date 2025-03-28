desc "Tags machines with opdb type and display data"
task tag_opdb_type: :environment do
  response = Net::HTTP.get_response(URI("https://opdb.org/api/export?api_token=#{ENV['OPDB_KEY']}"))
  Machine.tag_with_opdb_type_json(response.body)
end
