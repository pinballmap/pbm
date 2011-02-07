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

Then /^I should see the "([^"]*)" input$/ do |labeltext|
  find_field("#{labeltext}").should be_true
end

Then /^"([^"]*)" should have "([^"]*)"$/ do |location_name, machine_name|
  Location.find_by_name(location_name).machine_names.should include(machine_name)
end

Then /^"([^"]*)" should only have "([^"]*)"$/ do |location_name, machine_name|
  l = Location.find_by_name(location_name)
  l.machine_names.should include(machine_name)
  l.machine_names.length.should be 1
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
