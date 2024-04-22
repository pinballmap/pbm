desc 'Sends emails to super admins with all region information'
task notify_super_admins: :environment do
  email_bodies = []

  Region.all.each do |r|
    email_body = r.generate_weekly_admin_email_body
    email_bodies.push(email_body)
  end

  weekly_regionless_email_body = Region.generate_weekly_regionless_email_body

  User.where(is_super_admin: 'Y').each do |user|
    AdminMailer.with(user: user.email, email_bodies: email_bodies).weekly_admin_digest_all_regions.deliver_now
    AdminMailer.with(user: user.email, machines_count: weekly_regionless_email_body[:regionless_machines_count], locations_count: weekly_regionless_email_body[:regionless_locations_count], machineless_locations: weekly_regionless_email_body[:machineless_locations], suggested_locations: weekly_regionless_email_body[:suggested_locations], suggested_locations_count: weekly_regionless_email_body[:suggested_locations_count], locations_added_count: weekly_regionless_email_body[:locations_added_count], locations_deleted_count: weekly_regionless_email_body[:locations_deleted_count], machine_comments_count: weekly_regionless_email_body[:machine_comments_count], machines_added_count: weekly_regionless_email_body[:machines_added_count], machines_removed_count: weekly_regionless_email_body[:machines_removed_count]).weekly_admin_digest_regionless.deliver_now
  end
rescue StandardError => e
  error_subject = 'Weekly super admins rake task error'
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_now
end

desc 'Sends super admins a daily digest email of all new regionless machine conditions'
task send_daily_digest_regionless_machine_condition_email: :environment do
  regionless_comment_daily_email_body = Region.generate_daily_digest_regionless_comments_email_body
  submissions = regionless_comment_daily_email_body[:submissions]

  unless submissions.empty?
    User.where(is_super_admin: 'Y').each do |user|
      AdminMailer.with(user: user.email, submissions: submissions).send_daily_digest_regionless_machine_condition_email.deliver_now
    end
  end
end

desc 'Sends super admins a daily digest email of all regionless machine removals'
task send_daily_digest_regionless_machine_removal_email: :environment do
  regionless_removals_daily_email_body = Region.generate_daily_digest_regionless_removal_email_body
  submissions = regionless_removals_daily_email_body[:submissions]

  unless submissions.empty?
    User.where(is_super_admin: 'Y').each do |user|
      AdminMailer.with(user: user.email, submissions: submissions).send_daily_digest_regionless_machine_removal_email.deliver_now
    end
  end
end
