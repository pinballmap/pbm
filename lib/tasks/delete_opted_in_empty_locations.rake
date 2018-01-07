desc 'Deletes empty locations from regions that have opted-in to this functionality'
task delete_opted_in_empty_locations: :environment do
  if Time.now.sunday?
    puts('Deleting opted-in regions with empty locations')
    Region.all.each(&:delete_all_empty_locations)
  end
end
