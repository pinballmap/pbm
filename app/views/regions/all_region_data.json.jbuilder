json.data do
  json.region do
    json.name @region.name
    json.fullName @region.full_name
    json.lat @region.lat
    json.lon @region.lon
    json.locations @region.locations.each do |location|
      json.location do
        json.name location.name
        json.lat location.lat
        json.lon location.lon
        json.street location.street
        json.city location.city
        json.state location.state
        json.zip location.zip
        json.phone location.phone
        json.numMachines location.machines.size
        json.machines location.machines.sort_by(&:name).each do |machine|
          json.machine do
            json.name machine.name
          end
        end
      end
    end
    json.machines @region.machines.each do |machine|
      json.machine do
        json.id machine.id
        json.name machine.name
        json.numLocations LocationMachineXref.count_by_sql "select count(*) from location_machine_xrefs lmx inner join locations l on (lmx.location_id = l.id) where l.region_id=#{@region.id} and lmx.machine_id=#{machine.id}"
      end
    end
    json.zones @region.zones.each do |zone|
      json.zone do
        json.id zone.id
        json.name zone.name
        json.shortName zone.short_name
        json.isPrimary zone.is_primary ? 1 : 0
      end
    end
    json.events @region.events.each do |event|
      json.event do
        json.id event.id
        json.name event.name
        json.longDesc event.long_desc
        json.link event.external_link
        json.categoryNo event.category_no
        json.startDate event.start_date
        json.locationNo event.location_id
      end
    end
  end
end
