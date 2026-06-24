desc "Sends emails to super admins with all region information"
task send_weekly_digest_global: :environment do
  weekly_global_email_body = Region.generate_weekly_global_email_body

  User.where(is_super_admin: "Y").each do |user|
    AdminMailer.with(user: user.email, machines_count: weekly_global_email_body[:machines_count], locations_count: weekly_global_email_body[:locations_count], contact_messages_count: weekly_global_email_body[:contact_messages_count], machineless_locations: weekly_global_email_body[:machineless_locations], suggested_locations_count: weekly_global_email_body[:suggested_locations_count], locations_added_count: weekly_global_email_body[:locations_added_count], locations_deleted_count: weekly_global_email_body[:locations_deleted_count], machine_comments_count: weekly_global_email_body[:machine_comments_count], machines_added_count: weekly_global_email_body[:machines_added_count], machines_removed_count: weekly_global_email_body[:machines_removed_count], pictures_added_count: weekly_global_email_body[:pictures_added_count], pictures_removed_count: weekly_global_email_body[:pictures_removed_count], scores_added_count: weekly_global_email_body[:scores_added_count], scores_deleted_count: weekly_global_email_body[:scores_deleted_count], machine_comments_deleted_count: weekly_global_email_body[:machine_comments_deleted_count]).send_weekly_digest_global.deliver_later
  end
rescue StandardError => e
  error_subject = "Weekly super admins rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end

desc "Sends super admins a daily global activity digest email"
task send_daily_digest_global: :environment do
  email_body = Region.generate_daily_digest_global_email_body

  unless email_body[:machine_comments].empty? && email_body[:machine_removals].empty? && email_body[:pictures_added].empty? && email_body[:location_metadata].empty? && email_body[:new_user_activity].empty?
    User.where(is_super_admin: "Y").each do |user|
      AdminMailer.with(user: user.email, machine_comments: email_body[:machine_comments], machine_removals: email_body[:machine_removals], pictures_added: email_body[:pictures_added], location_metadata: email_body[:location_metadata], remove_and_readd: email_body[:remove_and_readd], new_user_activity: email_body[:new_user_activity], proxy_machine_additions: email_body[:proxy_machine_additions], proxy_machine_comments: email_body[:proxy_machine_comments], machine_comments_count: email_body[:machine_comments_count], machine_removals_count: email_body[:machine_removals_count], pictures_added_count: email_body[:pictures_added_count], location_metadata_count: email_body[:location_metadata_count], machines_added_count: email_body[:machines_added_count], scores_added_count: email_body[:scores_added_count]).send_daily_digest_global.deliver_later
    end
  end
rescue StandardError => e
  error_subject = "Daily global digest rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end

desc "Sends super admins a report of potentially duplicate locations"
task send_duplicate_locations_report: :environment do
  name_city_dupes = Location.group(:name, :city).having("count(*) > 1").count.map { |(name, city), count| { "name" => name, "city" => city, "count" => count } }
  lat_zip_dupes = Location.group(:lat, :zip).having("count(*) > 1").count.map { |(lat, zip), count| { "lat" => lat.to_s, "zip" => zip, "count" => count } }

  unless name_city_dupes.empty? && lat_zip_dupes.empty?
    User.where(is_super_admin: "Y").each do |user|
      AdminMailer.with(user: user.email, name_city_dupes: name_city_dupes, lat_zip_dupes: lat_zip_dupes).send_duplicate_locations_report.deliver_later
    end
  end
rescue StandardError => e
  error_subject = "Duplicate locations report rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end
