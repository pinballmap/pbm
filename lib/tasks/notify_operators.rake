desc "Sends emails to operators with recent location edits"
task send_daily_digest_operator_email: :environment do
  Operator.where.not(email: [ nil, "" ]).each do |o|
    email_body = o.generate_operator_daily_digest
    machine_comments = email_body[:machine_comments]
    machines_added = email_body[:machines_added]
    machines_removed = email_body[:machines_removed]

    next if machine_comments.empty? && machines_added.empty? && machines_removed.empty?

    email_to = o.email.to_s

    OperatorMailer.with(email_to: email_to, machine_comments: machine_comments, machines_added: machines_added, machines_removed: machines_removed).send_daily_digest_operator_email.deliver_later
    sleep(8)
  end
rescue StandardError => e
  error_subject = "Notify operators rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end
