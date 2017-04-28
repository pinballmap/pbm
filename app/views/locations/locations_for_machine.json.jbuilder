json.data do
  json.locations do
    if @locations &
      @locations.each do |location|
        cloned_location = location.clone
        json.location do
          json.id cloned_location.id
          json.name cloned_location.name
          json.zoneNo cloned_location.zone_id
          json.zone cloned_location.zone.nil? ? '' : cloned_location.zone.short_name
          json.neighborhood cloned_location.zone.nil? ? '' : cloned_location.zone.short_name
          json.lat cloned_location.lat
          json.lon cloned_location.lon
          json.street1 cloned_location.street
          json.street2
          json.city cloned_location.city
          json.state cloned_location.state
          json.zip cloned_location.zip
          json.phone cloned_location.phone
          json.numMachines cloned_location.machines.size
        end
        cloned_location = nil
      end
    end
  end
end
