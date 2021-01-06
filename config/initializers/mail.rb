ActionMailer::Base.smtp_settings = {
  :address        => 'smtp.sendgrid.net',
  :port           => '587',
  :authentication => :plain,
  :user_name      => 'apikey',
  :password       => ENV['SENDGRID_API_KEY'],
  :domain         => 'heroku.com'
}
ActionMailer::Base.delivery_method = :smtp
