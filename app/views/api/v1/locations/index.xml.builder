xml.instruct! :xml, :version => "1.0"
xml.locations :type => 'array' do
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
      xml.machines :type => 'array' do
        for machine in location.location_machine_xrefs
          xml.machineid machine.machine.id
          xml.machineName machine.machine.name
          xml.condition machine.condition
          xml.condtionDate machine.condition_date
        end
      end
    end
    cloned_location = nil
  end
end