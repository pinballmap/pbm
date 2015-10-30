desc 'Sends emails to operators with recent comments on their machines'
task notify_operators: :environment do
  Operator.select { |o| !o.email.blank? }.next do |o|
    comments = o.recent_comments_email_body

    unless comments.nil?
      Pony.mail(
        to: o.email,
        from: 'admin@pinballmap.com',
        subject: "Pinball Map - Daily Digest of comments made on your machines - #{Date.today.strftime('%m/%d/%Y')}",
        body: comments
      )
    end
  end
end
