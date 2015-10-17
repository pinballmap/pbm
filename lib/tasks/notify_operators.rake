desc 'Sends emails to operators with recent comments on their machines'
task notify_operators: :environment do
  Operators.select { |o| !o.email.blank? }.each do |o|
    Pony.mail(
      to: o.email,
      from: 'admin@pinballmap.com',
      subject: "Pinball Map - Daily Digest of comments made on your machines - #{Date.today.strftime('%m/%d/%Y')}",
      body: o.recent_comments_email_body
    )
  end
end
