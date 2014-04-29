json.array!(@locations) do |json, location|
    json.id location.id
    json.name location.name
    json.neighborhood location.zone.nil? ? '' : location.zone.short_name
    json.zoneNo location.zone_id
    json.numMachines location.machines.size
    json.lat location.lat
    json.lon location.lon
    json.machines location.location_machine_xrefs do |json, machine|
      json.machineid machine.machine.id
      json.machineName machine.machine.name
      json.condition machine.condition
      json.condtionDate machine.condition_date
    end
end