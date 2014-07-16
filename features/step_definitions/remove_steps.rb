When /^I (accept|dismiss) the "([^"]*)" alert$/ do |action, text|
  alert = page.driver.browser.switch_to.alert
  alert.text.should eq(text)
  alert.send(action)
end

Then /^the infowindow should be blank$/ do
  page.should have_no_content('Test Machine Name')
end
