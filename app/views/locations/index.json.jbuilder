json.locations @locations.each do |json, location|
  json.location do
    json.id location.id
    json.name location.name
    json.neighborhood location.zone.nil? ? '' : location.zone.short_name
    json.zoneNo location.zone_id
    json.numMachines location.machines.size
    json.lat location.lat
    json.lon location.lon
  end
end

json.machines Machine.all.each do |json, machine|
  json.machine do
    json.id machine.id
    json.name machine.name

    json.numLocations LocationMachineXref.count_by_sql "select count(*) from location_machine_xrefs lmx inner join locations l on (lmx.location_id = l.id) where l.region_id=#{@region.id} and lmx.machine_id=#{machine.id}"
  end
end

json.zones @region.zones.each do |json, zone|
  json.zone do
    json.id zone.id
    json.name zone.name
    json.shortName zone.short_name
    json.isPrimary zone.is_primary ? 1 : 0
  end
end
