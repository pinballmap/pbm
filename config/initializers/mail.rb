ActionMailer::Base.smtp_settings = {
  :address        => 'mail.smtp2go.com',
  :port           => '2525',
  :authentication => :plain,
  :user_name      => 'pinballmapsmtp2go',
  :password       => ENV['SMTP2GO_API_KEY'],
  :domain         => 'pinballmap.com',
  :enable_starttls_auto => true
}
ActionMailer::Base.delivery_method = :smtp
