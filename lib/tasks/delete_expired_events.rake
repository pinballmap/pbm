desc 'Deletes events from the database that are more than a week expired'
task delete_expired_events: :environment do
  puts('Deleting all expired events')
  Region.all.each(&:delete_all_expired_events)
rescue StandardError => e
  Pony.mail(
    to: 'admin@pinballmap.com',
    from: 'admin@pinballmap.com',
    subject: "Pbm Rake Task Error - Delete Expired Events - #{Date.today.strftime('%m/%d/%Y')}",
    body: "Delete expired events rake task error\n\n" + e.to_s
  )
end
