desc "Deletes events from the database that are more than a week expired"
task delete_expired_events: :environment do
  count = Event.expired.delete_all
  puts("Deleted #{count} expired events")
rescue StandardError => e
  error_subject = "Delete expired events rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end
