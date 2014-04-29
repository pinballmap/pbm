json.array!(@locations) do |json, location|
    json.id location.id
    json.name location.name
    json.neighborhood location.zone.nil? ? '' : location.zone.short_name
    json.zoneNo location.zone_id
    json.numMachines location.machines.size
    json.lat location.lat
    json.lon location.lon
    json.city location.city
    json.createdAt location.created_at
    json.description location.description
    json.locationType location.location_type_id
    json.operatorid location.operator_id
    json.phone location.phone
    json.regionid location.region_id
    json.state location.state
    json.street location.street
    json.updatedAt location.updated_at
    json.website location.website
    json.zip location.zip
    json.zoneid location.zone_id
    json.machines location.location_machine_xrefs do |json, machine|
      json.machineid machine.machine.id
      json.machineName machine.machine.name
      json.condition machine.condition
      json.condtionDate machine.condition_date
    end
end