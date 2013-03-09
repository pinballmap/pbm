Then /^my other search options should be "([^"]*)"$/ do |options|
  page.find("div#other_search_options").should have_content(options)
end

Given /^I switch to "([^"]*)" lookup$/ do |type|
  page.find("div#other_search_options a##{type}_section_link").click
end

Given /^I click to search by "([^"]*)"$/ do |type|
  if page.has_css?("div#by_#{type}_banner")
    page.find("div#by_#{type}_banner").click
  end
end

Given /^I press the "([^"]*)" search button$/ do |type|
  if page.has_css?("input##{type}_search_button")
    page.find("input##{type}_search_button").click
  end
end

Then /^I should see the listing for "([^"]*)"$/ do |name|
  within('div.search_result') do
    page.should have_content(name)
  end
end

Then /^I should not see the listing for "([^"]*)"$/ do |name|
  if page.has_css?('div.search_result')
    within('div.search_result') do
      page.should have_no_content(name)
    end
  end
end

Then /^I should see a summary for "([^"]*)" and "([^"]*)"$/ do |location_text, machine_text|
  if page.has_css?("div.map_summaries")
    page.find("div#map_summaries").should have_content(location_text)
    page.find("div#map_summaries").should have_content(machine_text)
  end
end

Then /^a location machine xref should exist with the machine name "([^"]*)" and the initials "([^"]*)"$/ do |machine_name, initials|
  m = Machine.find_by_name(machine_name)
  lmx = LocationMachineXref.find_by_machine_id(m.id)

  lmx.user.should == User.find_by_initials(initials)
end

Then /^the order of the listings should be "([^"]*)"$/ do |raw_listing|
  listings = raw_listing.split(",")
  actual_order = page.all('div.search_result').collect(&:text)

  actual_order.each_with_index do |value, index|
    value.should match /#{listings[index].strip}/i
  end
end

Given /^I navigate to the direct link for region "([^"]*)" location "(\d+)"$/ do |region, id|
  visit path_to("/#{region}/?by_location_id=#{id}")
end

Given /^I navigate to the direct link for region "([^"]*)" city "([^"]*)"$/ do |region, city|
  visit path_to("/#{region}/?by_city_id=#{city}")
end

Then /^I should see a link titled "([^"]*)" to "([^"]*)"/ do |title, url|
  URI.parse(page.find_link(title)['href']).to_s.should == url
end
