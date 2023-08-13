desc 'Sends emails to operators with recent comments on their machines'
task notify_operators: :environment do
  Operator.all.each(&:send_recent_comments) unless Rails.env.staging?
rescue StandardError => e
  Pony.mail(
    to: 'admin@pinballmap.com',
    from: 'admin@pinballmap.com',
    subject: "Pbm Rake Task Error - Notify Operators - #{Date.today.strftime('%m/%d/%Y')}",
    body: "Notify operators rake task error\n\n" + e.to_s
  )
end
