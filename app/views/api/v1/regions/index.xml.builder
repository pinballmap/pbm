xml.instruct! :xml, :version => "1.0"
xml.regions :type => 'array' do
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
      xml.primaryEmailContact region.primary_email_contact
      xml.adminEmails :type => 'array' do 
        for email in region.all_admin_email_addresses
          xml.email email
        end
      end
    end
  end
end