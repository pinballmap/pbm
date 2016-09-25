desc 'Sends emails to operators with recent comments on their machines'
task notify_operators: :environment do
  Operator.all.each(&:send_recent_comments)
end
