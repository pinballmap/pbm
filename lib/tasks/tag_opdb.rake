desc 'Tags machines with opdb data'
task tag_opdb: :environment do
  response = Net::HTTP.get_response(URI("https://opdb.org/api/export?api_token=#{ENV['OPDB_KEY']}"))
  Machine.tag_with_opdb_json(response.body)
rescue StandardError => e
  error_subject = 'Tag OPDB rake task error'
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end
