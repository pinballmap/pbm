json.array!(@regions) do |json, region|
    json.id region.id
    json.name region.name
    json.formalName region.full_name
    json.subdir region.name
    json.lat region.lat
    json.lon region.lon
    json.nSearchNo region.n_search_no
    json.motd region.motd
    json.primaryEmailContact region.primary_email_contact
    json.adminEmails region.all_admin_email_addresses do |json, email|
      json.email email
    end
end