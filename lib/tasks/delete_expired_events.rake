desc 'Deletes events from the database that are more than a week expired'
task delete_expired_events: :environment do
  puts('Deleting all expired events')
  Region.all.each(&:delete_all_expired_events)

  puts('Deleting all regionless events')
  Region.delete_all_regionless_events
rescue StandardError => e
  error_subject = 'Delete expired events rake task error'
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_now
end
