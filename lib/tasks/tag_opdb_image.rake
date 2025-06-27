desc "Tags machines with opdb data"
task tag_opdb_image: :environment do
  response = Net::HTTP.get_response(URI("https://mp-data.sfo3.cdn.digitaloceanspaces.com/latest-opdb.json"))
  Machine.tag_with_opdb_image_json(response.body)
rescue StandardError => e
  error_subject = "Tag OPDB image rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end
