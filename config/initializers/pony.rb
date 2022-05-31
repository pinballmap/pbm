Pony.options = {
  :via => :smtp,
  :via_options => {
    :address => 'smtp.sendgrid.net',
    :port => '587',
    :domain => 'pinballmap.com',
    :user_name => 'apikey',
    :password => ENV['SENDGRID_API_KEY'],
    :authentication => :plain,
    :enable_starttls_auto => true
  }
}
