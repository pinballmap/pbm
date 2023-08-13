desc 'Tags machines with opdb data'
task tag_opdb: :environment do
  response = Net::HTTP.get_response(URI("https://opdb.org/api/export?api_token=#{ENV['OPDB_KEY']}"))
  Machine.tag_with_opdb_json(response.body)
rescue StandardError => e
  Pony.mail(
    to: 'admin@pinballmap.com',
    from: 'admin@pinballmap.com',
    subject: "Pbm Rake Task Error - Tag OPDB - #{Date.today.strftime('%m/%d/%Y')}",
    body: "Tag OPDB rake task error\n\n" + e.to_s
  )
end
