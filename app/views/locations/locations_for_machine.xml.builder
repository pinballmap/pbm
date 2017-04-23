xml.instruct! :xml, version: '1.0'
xml.data do
  xml.locations do
    if @locations &
      @locations.each do |location|
        cloned_location = location.clone
        xml.location do
          xml.id cloned_location.id
          xml.name cloned_location.name
          xml.zoneNo cloned_location.zone_id
          xml.zone cloned_location.zone.nil? ? '' : cloned_location.zone.short_name
          xml.neighborhood cloned_location.zone.nil? ? '' : cloned_location.zone.short_name
          xml.lat cloned_location.lat
          xml.lon cloned_location.lon
          xml.street1 cloned_location.street
          xml.street2
          xml.city cloned_location.city
          xml.state cloned_location.state
          xml.zip cloned_location.zip
          xml.phone cloned_location.phone
          xml.numMachines cloned_location.machines.size
        end
        cloned_location = nil
      end
    end
  end
end
