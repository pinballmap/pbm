desc 'Tags machines with opdb data'
task tag_opdb: :environment do
  if Time.now.monday?
    response = Net::HTTP.get_response(URI("https://opdb.org/api/export?api_token=#{ENV['OPDB_KEY']}"))
    Machine.tag_with_opdb_json(response.body)
  end
end
