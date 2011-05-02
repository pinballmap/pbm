xml.instruct! :xml, :version => "1.0"
xml.data do
  xml.locations do
    for location in @locations
      xml.location do
        xml.id location.id
        xml.name location.name
        xml.neighborhood location.zone_id.nil? ? '' : location.zone.short_name
        xml.zoneNo location.zone_id
        xml.numMachines location.machines.size
        xml.lat location.lat
        xml.lon location.lon
      end
    end
  end

  xml.machines do
    for machine in @region.machines
      xml.machine do
        xml.id machine.id
        xml.name machine.name

        machine_counts = Hash.new
        @region.location_machine_xrefs.each do |lmx|
          (machine_counts[lmx.machine_id] ||= []) << lmx
        end

        xml.numLocations machine_counts[machine.id].size
      end
    end
  end

  xml.zones do
    for zone in @region.zones
      xml.zone do
        xml.id zone.id
        xml.name zone.name
        xml.shortName zone.short_name
        xml.isPrimary zone.is_primary ? 1 : 0
      end
    end
  end
end
