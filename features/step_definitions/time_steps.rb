require 'timecop'

Given /^today is (\d+)\/(\d+)\/(\d+)$/ do |month, day, year|
  Timecop.freeze(Time.new(year.to_i, month.to_i, day.to_i))
end

When /^I wait for (\d+) seconds?$/ do |secs|
  sleep secs.to_i
end

After do
  Timecop.return
end
