Pony.options = {
  :via => :smtp,
  :via_options => {
    :address => 'mail.smtp2go.com',
    :port => '587',
    :domain => 'pinballmap.com',
    :user_name => 'pinballmapsmtp2go',
    :password => ENV['SMTP2GO_API_KEY'],
    :authentication => :plain,
    :enable_starttls_auto => true
  }
}
