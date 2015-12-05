desc 'Sends emails to operators with recent comments on their machines'
task notify_operators: :environment do
  Operator.all.each do |o|
    o.send_recent_comments
  end
end
