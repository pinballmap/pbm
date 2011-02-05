Then /^"([^"]*)"'s "([^"]*)" should have the condition "([^"]*)"$/ do |location_name, machine_name, condition|
  LocationMachineXref.where('machine_id = ? and location_id = ?',
    Machine.find_by_name(machine_name).id,
    Location.find_by_name(location_name).id
  ).first.condition.should == condition
end

Given /^I update the machine condition for "([^"]*)"'s "([^"]*)" to be "([^"]*)"$/ do |location_name, machine_name, condition|
  lmx = LocationMachineXref.where('machine_id = ? and location_id = ?',
    Machine.find_by_name(machine_name).id,
    Location.find_by_name(location_name).id
  ).first

  page.find("div#machine_condition_display_location_machine_xref_#{lmx.id}").click
  fill_in("new_machine_condition_#{lmx.id}", :with => condition)
  click_button('update_condition')
end
