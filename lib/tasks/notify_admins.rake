desc "Sends emails to admins with region information"
task send_weekly_admin_digest: :environment do
  Region.all.each do |r|
    email_subject = "Pinball Map - Weekly admin digest (#{r.full_name}) - #{Date.today.strftime('%m/%d/%Y')}"

    email_body = r.generate_weekly_admin_email_body

    email_to = r.users.map(&:email)

    next if email_to.blank? || email_to.nil?

    AdminMailer.with(email_to: email_to, email_subject: email_subject, region_name: email_body[:full_name], machines_count: email_body[:machines_count], locations_count: email_body[:locations_count], contact_messages_count: email_body[:contact_messages_count], machineless_locations: email_body[:machineless_locations], suggested_locations: email_body[:suggested_locations], suggested_locations_count: email_body[:suggested_locations_count], locations_added_count: email_body[:locations_added_count], locations_deleted_count: email_body[:locations_deleted_count], machine_comments_count: email_body[:machine_comments_count], machines_added_count: email_body[:machines_added_count], machines_removed_count: email_body[:machines_removed_count], pictures_added_count: email_body[:pictures_added_count], scores_added_count: email_body[:scores_added_count]).send_weekly_admin_digest.deliver_later
    sleep(8)
  end
rescue StandardError => e
  error_subject = "Weekly digest rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end

desc "Sends admins a daily digest email of all new machine conditions"
task send_daily_digest_machine_condition_email: :environment do
  Region.select(&:send_digest_comment_emails).each do |r|
    email_subject = "Pinball Map - Daily admin machine comment digest (#{r.full_name}) - #{(Date.today - 1.day).strftime('%m/%d/%Y')}"
    email_body = r.generate_daily_digest_comments_email_body
    submissions = email_body[:submissions]

    next if submissions.empty?

    email_to = r.users.map(&:email)

    next if email_to.blank? || email_to.nil?

    AdminMailer.with(email_to: email_to, email_subject: email_subject, submissions: submissions, region_name: r.full_name).send_daily_digest_machine_condition_email.deliver_later
    sleep(8)
  end
rescue StandardError => e
  error_subject = "Daily comments rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end

desc "Sends admins a daily digest email of all machine removals"
task send_daily_digest_machine_removal_email: :environment do
  Region.select(&:send_digest_removal_emails).each do |r|
    email_subject = "Pinball Map - Daily admin machine removal digest (#{r.full_name}) - #{(Date.today - 1.day).strftime('%m/%d/%Y')}"
    email_body = r.generate_daily_digest_removal_email_body
    submissions = email_body[:submissions]

    next if submissions.empty?

    email_to = r.users.map(&:email)

    next if email_to.blank? || email_to.nil?

    AdminMailer.with(email_to: email_to, email_subject: email_subject, submissions: submissions, region_name: r.full_name).send_daily_digest_machine_removal_email.deliver_later
    sleep(8)
  end
rescue StandardError => e
  error_subject = "Daily removals rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end
