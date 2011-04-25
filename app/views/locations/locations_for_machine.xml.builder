xml.instruct! :xml, :version => "1.0"
xml.data do
  xml.locations do
    if (@locations)
      for location in @locations
        xml.location do
          xml.id location.id
          xml.name location.name
          xml.zoneNo location.zone_id
          xml.zone location.zone_id.nil? ? '' : location.zone.short_name
          xml.neighborhood location.zone_id.nil? ? '' : location.zone.short_name
          xml.lat location.lat
          xml.lon location.lon
          xml.street1 location.street
          xml.street2
          xml.city location.city
          xml.state location.state
          xml.zip location.zip
          xml.phone location.phone
          xml.numMachines location.machines.size
        end
      end
    end
  end
end
