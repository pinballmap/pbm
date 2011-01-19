Given /^there are (\d+) (.+)$/ do |n, model_str|
  model_str = model_str.gsub(/\s/, '_').singularize
  model_sym = model_str.to_sym
  klass = eval(model_str.camelize)
  klass.transaction do
    klass.destroy_all
    n.to_i.times do |i|
      Factory(model_sym)
    end
  end
end

Then /^I should see the following autocomplete options:$/ do |table|
  table.raw.each do |row|
    page.should have_xpath("//a[text()='#{row[0]}']")
  end
end

When /^I wait for (\d+) seconds?$/ do |secs|
  sleep secs.to_i
end

When /^I click on the "([^"]*)" autocomplete option$/ do |link_text|
  page.evaluate_script %Q{ $('.ui-menu-item a:contains("#{link_text}")').trigger("mouseenter").click(); }
end

Then /^I should see the "([^"]*)" input$/ do |labeltext|
  find_field("#{labeltext}").should be_true
end

Then /^"([^"]*)" should have "([^"]*)"$/ do |location_name, machine_name|
  Location.find_by_name(location_name).machine_names.should include(machine_name)
end

Then /^"([^"]*)"'s "([^"]*)" should have the condition "([^"]*)"$/ do |location_name, machine_name, condition|
  LocationMachineXref.where('machine_id = ? and location_id = ?',
    Machine.find_by_name(machine_name).id,
    Location.find_by_name(location_name).id
  ).first.condition.should == condition
end

Then /^"([^"]*)"'s "([^"]*)" should have a score with initials "([^"]*)" and score "([^"]*)" and rank "([^"]*)"$/ do |location_name, machine_name, initials, score, rank|
  lmx = LocationMachineXref.where('machine_id = ? and location_id = ?', Machine.find_by_name(machine_name).id, Location.find_by_name(location_name).id).first
  msx = MachineScoreXref.where('location_machine_xref_id = ?', lmx.id).first
  msx.initials.should == initials
  msx.score.should == score.to_i
  msx.rank.should == rank.to_i
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

Then /^I click to see the detail for "([^"]*)"$/ do |name|
  if page.has_css?('div.search_result')
    within('div.search_result') do
      click_link(name)
    end
  end
end

Then /^I click on the add machine link for "([^"]*)"$/ do |name|
  l = Location.find_by_name(name)
  if page.has_css?("div#add_machine_banner_#{l.id.to_i}.sub_nav_item")
    page.find("div#add_machine_banner_#{l.id.to_i}.sub_nav_item").click
  end
end

Then /^I click on the show machines link for "([^"]*)"$/ do |name|
  l = Location.find_by_name(name)
  if page.has_css?("div#show_machines_banner_#{l.id.to_i}.sub_nav_item")
    page.find("div#show_machines_banner_#{l.id.to_i}.sub_nav_item").click
  end
end

Given /^"([^"]*)" has (\d+) locations and (\d+) machines$/ do |name, num_locations, num_machines|
  locations = Array.new()
  r = Region.find_by_name(name)

  num_locations.to_i.times {
    locations << Factory.create(:location, :region_id => r.id)
  }

  num_machines.to_i.times {
    Factory.create(:location_machine_xref, :location_id => locations.first.id, :machine_id => Factory.create(:machine).id)
  }
end

Then /^I should see a summary for "([^"]*)" and "([^"]*)"$/ do |location_text, machine_text|
  if page.has_css?("div.map_summaries")
    page.find("div#map_summaries").should have_content(location_text)
    page.find("div#map_summaries").should have_content(machine_text)
  end
end
