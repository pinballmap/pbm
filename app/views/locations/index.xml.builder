xml.instruct! :xml, :version => "1.0"
xml.data do
  xml.locations do
    for location in @locations
      cloned_location = location.clone
      xml.location do
        xml.id cloned_location.id
        xml.name cloned_location.name
        xml.neighborhood cloned_location.zone.nil? ? '' : cloned_location.zone.short_name
        xml.zoneNo cloned_location.zone_id
        xml.numMachines cloned_location.machines.size
        xml.lat cloned_location.lat
        xml.lon cloned_location.lon
      end
      cloned_location = nil
    end
  end

  xml.machines do
    for machine in @region.machines
      cloned_machine = machine.clone
      xml.machine do
        xml.id cloned_machine.id
        xml.name cloned_machine.name

        xml.numLocations LocationMachineXref.count_by_sql "select count(*) from location_machine_xrefs lmx inner join locations l on (lmx.location_id = l.id) where l.region_id=#{@region.id} and lmx.machine_id=#{cloned_machine.id}"
      end
      cloned_machine = nil
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
