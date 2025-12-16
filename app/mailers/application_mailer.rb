class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("EMAIL_ACTIONMAILER", "Pinball Map <admin@pinballmap.com>")
  layout "mailer"
end
