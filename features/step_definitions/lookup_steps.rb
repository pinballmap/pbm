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
