desc "Tags machines with opdb changelog data"
task tag_opdb_changelog: :environment do
  response = Net::HTTP.get_response(URI("https://opdb.org/api/changelog"))
  Machine.tag_with_opdb_changelog_json(response.body)
rescue StandardError => e
  error_subject = "Tag OPDB changelog rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end
