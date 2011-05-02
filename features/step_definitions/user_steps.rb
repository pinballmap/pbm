Given /^I am a logged in user$/ do
  r = Region.find_by_name('portland')
  u = Factory.create :user, :region => r

  visit '/users/sign_in'
  fill_in('Email', :with => u.email)
  fill_in('Password', :with => u.password)
  click_button('Sign in')
end
