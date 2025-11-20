desc "Sends emails to super admins with all region information"
task send_weekly_admin_digest_global: :environment do
  weekly_global_email_body = Region.generate_weekly_global_email_body

  User.where(is_super_admin: "Y").each do |user|
    AdminMailer.with(user: user.email, machines_count: weekly_global_email_body[:machines_count], locations_count: weekly_global_email_body[:locations_count], contact_messages_count: weekly_global_email_body[:contact_messages_count], machineless_locations: weekly_global_email_body[:machineless_locations], suggested_locations_count: weekly_global_email_body[:suggested_locations_count], locations_added_count: weekly_global_email_body[:locations_added_count], locations_deleted_count: weekly_global_email_body[:locations_deleted_count], machine_comments_count: weekly_global_email_body[:machine_comments_count], machines_added_count: weekly_global_email_body[:machines_added_count], machines_removed_count: weekly_global_email_body[:machines_removed_count], pictures_added_count: weekly_global_email_body[:pictures_added_count], scores_added_count: weekly_global_email_body[:scores_added_count], scores_deleted_count: weekly_global_email_body[:scores_deleted_count], machine_comments_deleted_count: weekly_global_email_body[:machine_comments_deleted_count]).send_weekly_admin_digest_global.deliver_later
  end
rescue StandardError => e
  error_subject = "Weekly super admins rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end

desc "Sends super admins a daily digest email of all new global machine conditions"
task send_daily_digest_global_machine_condition_email: :environment do
  global_comment_daily_email_body = Region.generate_daily_digest_global_comments_email_body
  submissions = global_comment_daily_email_body[:submissions]

  unless submissions.empty?
    User.where(is_super_admin: "Y").each do |user|
      AdminMailer.with(user: user.email, submissions: submissions).send_daily_digest_global_machine_condition_email.deliver_later
    end
  end
rescue StandardError => e
  error_subject = "Daily global comments rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end

desc "Sends super admins a daily digest email of all global machine removals"
task send_daily_digest_global_machine_removal_email: :environment do
  global_removals_daily_email_body = Region.generate_daily_digest_global_removal_email_body
  submissions = global_removals_daily_email_body[:submissions]

  unless submissions.empty?
    User.where(is_super_admin: "Y").each do |user|
      AdminMailer.with(user: user.email, submissions: submissions).send_daily_digest_global_machine_removal_email.deliver_later
    end
  end
rescue StandardError => e
  error_subject = "Daily global removals rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end

desc "Sends super admins a daily digest of global pictures added"
task send_daily_digest_global_picture_added_email: :environment do
  global_picture_added_daily_email_body = Region.generate_daily_digest_global_picture_added_email_body
  submissions = global_picture_added_daily_email_body[:submissions]

  unless submissions.empty?
    User.where(is_super_admin: "Y").each do |user|
      AdminMailer.with(user: user.email, submissions: submissions).send_daily_digest_global_picture_added_email.deliver_later
    end
  end
rescue StandardError => e
  error_subject = "Daily global picture added rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end

desc "Sends super admins a daily digest of global scores added"
task send_daily_digest_global_score_added_email: :environment do
  global_score_added_daily_email_body = Region.generate_daily_digest_global_score_added_email_body
  submissions = global_score_added_daily_email_body[:submissions]

  unless submissions.empty?
    User.where(is_super_admin: "Y").each do |user|
      AdminMailer.with(user: user.email, submissions: submissions).send_daily_digest_global_score_added_email.deliver_later
    end
  end
rescue StandardError => e
  error_subject = "Daily global score added rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end
