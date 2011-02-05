Given /^I click on the add scores link for "([^"]*)"$/ do |name|
  lmx = LocationMachineXref.where(:location_id => Location.find_by_name(name).id).first
  if page.has_css?("div#add_scores_location_machine_xref_banner_#{lmx.id}")
    page.find("div#add_scores_location_machine_xref_banner_#{lmx.id}").click
  end
end

Given /^I fill in a score with initials "([^"]*)" and score "([^"]*)" and rank "([^"]*)"$/ do |initials, score, rank|
  fill_in("initials", :with => initials)
  fill_in("score", :with => score)
  select(rank, :from => 'rank')
end

Then /^"([^"]*)"'s "([^"]*)" should have a score with initials "([^"]*)" and score "([^"]*)" and rank "([^"]*)"$/ do |location_name, machine_name, initials, score, rank|
  lmx = LocationMachineXref.where('machine_id = ? and location_id = ?', Machine.find_by_name(machine_name).id, Location.find_by_name(location_name).id).first
  msx = MachineScoreXref.where('location_machine_xref_id = ?', lmx.id).first
  msx.initials.should == initials
  msx.score.should == score.to_i
  msx.rank.should == rank.to_i
end

Given /^a high score exists for location "([^"]*)"'s "([^"]*)" with initials "([^"]*)" and score "([^"]*)" and rank "([^"]*)"$/ do |location_name, machine_name, initials, score, rank|
  lmx = LocationMachineXref.where(:location => Location.find_by_name(location_name), :machine => Machine.find_by_name(machine_name)).first
  Factory.create(:machine_score_xref, :location_machine_xref => lmx, :initials => initials, :score => score, :rank => MachineScoreXref::ENGLISH_SCORES.key(rank))
end
