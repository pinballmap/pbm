Given /^I click on the add scores link for "([^"]*)"$/ do |name|
  lmx = LocationMachineXref.where(:location_id => Location.find_by_name(name).id).first
  if page.has_css?("div#add_scores_lmx_banner_#{lmx.id}")
    page.find("div#add_scores_lmx_banner_#{lmx.id}").click
  end
end

Given /^I fill in a score of "([^"]*)" and rank "([^"]*)" and initials "([^"]*)"$/ do |score, rank, initials|
  fill_in("score", :with => score)
  fill_in("initials", :with => initials)
  select(rank, :from => 'rank')
end

Then /^"([^"]*)"'s "([^"]*)" should have a score with score "([^"]*)" and rank "([^"]*)" and initials "([^"]*)"$/ do |location_name, machine_name, score, rank, initials|
  lmx = LocationMachineXref.where('machine_id = ? and location_id = ?', Machine.find_by_name(machine_name).id, Location.find_by_name(location_name).id).first
  msx = MachineScoreXref.where('location_machine_xref_id = ?', lmx.id).first
  msx.score.should == score.to_i
  msx.rank.should == rank.to_i
  msx.initials.should == initials
end

Given /^a high score exists for location "([^"]*)"'s "([^"]*)" with initials "([^"]*)" and score "([^"]*)" and rank "([^"]*)"$/ do |location_name, machine_name, initials, score, rank|
  lmx = LocationMachineXref.where(:location => Location.find_by_name(location_name), :machine => Machine.find_by_name(machine_name)).first
  Factory.create(:machine_score_xref, :initials => initials, :location_machine_xref => lmx, :score => score, :rank => MachineScoreXref::ENGLISH_SCORES.key(rank))
end

Then /^I should not see the show scores option for "([^"]*)"'s "([^"]*)"$/ do |location_name, machine_name|
  lmx = LocationMachineXref.where('machine_id = ? and location_id = ?', Machine.find_by_name(machine_name).id, Location.find_by_name(location_name).id).first

  page.should_not have_selector("div#score_container_lmx_#{lmx.id}.hidden")
end

Then /^I should see the show scores option for "([^"]*)"'s "([^"]*)"$/ do |location_name, machine_name|
  lmx = LocationMachineXref.where('machine_id = ? and location_id = ?', Machine.find_by_name(machine_name).id, Location.find_by_name(location_name).id).first

  within("div#machine_lmx_#{lmx.id}") do
    page.should have_content('SHOW HIGH SCORES')
  end
end
