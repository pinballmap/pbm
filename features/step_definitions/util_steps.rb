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
