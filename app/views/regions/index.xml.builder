xml.instruct! :xml, :version => "1.0"
xml.data do
  xml.regions do
    for region in @regions
      xml.region do
        xml.id region.id
        xml.name region.name
        xml.formalName region.full_name
        xml.subdir region.name
        xml.lat region.lat
        xml.lon region.lon
        xml.nSearchNo region.n_search_no
        xml.motd region.motd
        xml.emailContact region.primary_email_contact
      end
    end
  end
end
