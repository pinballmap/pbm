desc 'Deletes empty locations from regions that have opted-in to this functionality'
task delete_opted_in_empty_locations: :environment do
  puts('Deleting opted-in regions with empty locations')
  Region.all.each(&:delete_all_empty_locations)

  puts('Deleting empty_regionless locations')
  Region.delete_empty_regionless_locations
end
