json.location @location
json.id @location.id
json.name @location.name
json.zoneNo @location.zone_id
json.zone @location.zone.nil? ? '' : @location.zone.short_name
json.neighborhood @location.zone.nil? ? '' : @location.zone.short_name
json.lat @location.lat
json.lon @location.lon
json.street1 @location.street
json.street2
json.city @location.city
json.state @location.state
json.zip @location.zip
json.phone @location.phone
json.numMachines @location.machines.size

json.machines @location.location_machine_xrefs.each do |json, lmx|
  json.machine do
    json.id lmx.machine_id
    json.name lmx.machine.name
    json.condition lmx.condition
    json.condition_date lmx.condition_date.nil? ? '' : lmx.condition_date.to_s
  end
end
