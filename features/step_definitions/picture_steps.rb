Then /^I should see a thumbnail for photo "([^"]*)"$/ do |id|
  page.should have_selector("a.location_picture_xref_#{id}")
end

Then /^I should not see a thumbnail for photo "([^"]*)"$/ do |id|
  page.should_not have_selector("a.location_picture_xref_#{id}")
end
