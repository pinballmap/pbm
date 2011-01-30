Then /^I click to see the detail for "([^"]*)"$/ do |name|
  l = Location.find_by_name(name)
  if page.has_css?("div#show_location_detail_#{l.id}")
    page.find("div#show_location_detail_#{l.id}").click
  end
end

Then /^I click on the add machine link for "([^"]*)"$/ do |name|
  l = Location.find_by_name(name)
  if page.has_css?("div#add_machine_banner_#{l.id}")
    page.find("div#add_machine_banner_#{l.id}").click
  end
end

Then /^I click on the show machines link for "([^"]*)"$/ do |name|
  l = Location.find_by_name(name)
  if page.has_css?("div#show_machines_banner_#{l.id}")
    page.find("div#show_machines_banner_#{l.id}").click
  end
end
