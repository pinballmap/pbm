xml.instruct! :xml, :version => "1.0"
xml.data do
  xml.locations do
    xml.location do
      xml.id @location.id
      xml.name @location.name
      xml.zoneNo @location.zone_id
      xml.lat @location.lat
      xml.lon @location.lon
      xml.street1 @location.street
      xml.street2
      xml.city @location.city
      xml.state @location.state
      xml.zip @location.zip
      xml.phone @location.phone
      xml.numMachines @location.machines.size
    end
    xml.machines do
      for lmx in @location.location_machine_xrefs
        xml.machine do
          xml.id lmx.machine_id
          xml.name lmx.machine.name
          xml.condition lmx.condition, :date => lmx.condition_date.nil? ? '' : lmx.condition_date.to_s
          xml.dateAdded lmx.created_at.to_date.nil? ? '' : lmx.created_at.to_date.to_s
        end
      end
    end
  end
end
