desc 'Sends emails to operators with recent comments on their machines'
task notify_operators: :environment do
  Operator.all.each(&:send_recent_comments) unless Rails.env.staging?
rescue StandardError => e
  error_subject = 'Notify operators rake task error'
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_now
end
