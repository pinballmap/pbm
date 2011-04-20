Given /^I am a logged in user$/ do
  u = Factory.create :user

  visit '/users/sign_in'
  fill_in('Email', :with => u.email)
  fill_in('Password', :with => u.password)
  click_button('Sign in')
end
