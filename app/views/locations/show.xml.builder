xml.instruct! :xml, :version => "1.0"
xml.data do
  xml.locations do
    xml.location do
      xml.id @location.id
      xml.name @location.name
      xml.zoneNo @location.zone_id
      xml.zone @location.zone.nil? ? '' : @location.zone.short_name
      xml.neighborhood @location.zone.nil? ? '' : @location.zone.short_name
      xml.lat @location.lat
      xml.lon @location.lon
      xml.street1 @location.street
      xml.street2
      xml.city @location.city
      xml.state @location.state
      xml.zip @location.zip
      xml.phone @location.phone
      xml.numMachines @location.machines.size
      xml.machines do
        for lmx in @location.location_machine_xrefs
          xml.machine do
            xml.id lmx.machine_id
            xml.name lmx.machine.name
            if (lmx.condition.to_s != '')
              xml.condition lmx.condition, :date => lmx.condition_date.nil? ? '' : lmx.condition_date.to_s
            end
          end
        end
      end
    end
  end
end
