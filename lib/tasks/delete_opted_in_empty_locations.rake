desc 'Deletes empty locations from regions that have opted-in to this functionality'
task delete_opted_in_empty_locations: :environment do
  puts('Deleting opted-in regions with empty locations')
  Region.all.each(&:delete_all_empty_locations)

  puts('Deleting empty_regionless locations')
  Region.delete_empty_regionless_locations
rescue StandardError => e
  Pony.mail(
    to: 'admin@pinballmap.com',
    from: 'Pinball Map <admin@pinballmap.com>',
    subject: "Pbm Rake Task Error - Delete Empty Locations - #{Date.today.strftime('%m/%d/%Y')}",
    body: "Delete empty locations rake task error\n\n" + e.to_s
  )
end
