Then /^I should see the following autocomplete options:$/ do |table|
  table.raw.each do |row|
    page.should have_xpath("//a[text()='#{row[0]}']")
  end
end

When /^I click on the "([^"]*)" autocomplete option$/ do |link_text|
  page.evaluate_script %Q{ $('.ui-menu-item a:contains("#{link_text}")').trigger("mouseenter").click(); }
end
