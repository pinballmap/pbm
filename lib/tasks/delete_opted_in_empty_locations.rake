desc 'Deletes empty locations from regions that have opted-in to this functionality'
task delete_opted_in_empty_locations: :environment do
  puts('Deleting opted-in regions with empty locations')
  Region.all.each(&:delete_all_empty_locations)

  puts('Deleting empty_regionless locations')
  Region.delete_empty_regionless_locations
rescue StandardError => e
  error_subject = 'Delete empty locations rake task error'
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end
