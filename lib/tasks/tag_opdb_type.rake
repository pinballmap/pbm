desc "Tags machines with opdb type and display data"
task tag_opdb_type: :environment do
  response = Net::HTTP.get_response(URI("https://mp-data.sfo3.cdn.digitaloceanspaces.com/latest-opdb.json"))
  Machine.tag_with_opdb_type_json(response.body)
end
