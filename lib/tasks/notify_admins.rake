desc "Sends emails to admins with region information"
task send_weekly_digest_region: :environment do
  Region.all.each do |r|
    email_subject = "Pinball Map - Weekly admin digest (#{r.full_name}) - #{Date.today.strftime('%m/%d/%Y')}"

    email_body = r.generate_weekly_admin_email_body

    email_to = r.users.map(&:email)

    next if email_to.blank? || email_to.nil?

    AdminMailer.with(email_to: email_to, email_subject: email_subject, region_name: email_body[:full_name], machines_count: email_body[:machines_count], locations_count: email_body[:locations_count], contact_messages_count: email_body[:contact_messages_count], machineless_locations: email_body[:machineless_locations], suggested_locations: email_body[:suggested_locations], suggested_locations_count: email_body[:suggested_locations_count], locations_added_count: email_body[:locations_added_count], locations_deleted_count: email_body[:locations_deleted_count], machine_comments_count: email_body[:machine_comments_count], machines_added_count: email_body[:machines_added_count], machines_removed_count: email_body[:machines_removed_count], pictures_added_count: email_body[:pictures_added_count], pictures_removed_count: email_body[:pictures_removed_count], scores_added_count: email_body[:scores_added_count]).send_weekly_digest_region.deliver_later
    sleep(8)
  end
rescue StandardError => e
  error_subject = "Weekly digest rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end

desc "Sends admins a daily activity digest email"
task send_daily_digest_region: :environment do
  Region.all.each do |r|
    email_subject = "Pinball Map - Daily activity digest (#{r.full_name}) - #{(Date.today - 1.day).strftime('%m/%d/%Y')}"
    email_body = r.generate_daily_digest_email_body

    next if email_body[:machine_comments].empty? && email_body[:machine_removals].empty? && email_body[:pictures_added].empty? && email_body[:high_scores].empty?

    email_to = r.users.map(&:email)

    next if email_to.blank? || email_to.nil?

    AdminMailer.with(email_to: email_to, email_subject: email_subject, region_name: r.full_name, machine_comments: email_body[:machine_comments], machine_removals: email_body[:machine_removals], pictures_added: email_body[:pictures_added], high_scores: email_body[:high_scores]).send_daily_digest_region.deliver_later
    sleep(8)
  end
rescue StandardError => e
  error_subject = "Daily region digest rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end
