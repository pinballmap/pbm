class AdminMailer < ApplicationMailer
  def send_weekly_admin_digest_global
    @machines_count = params[:machines_count]
    @locations_count = params[:locations_count]
    @machineless_locations = params[:machineless_locations]
    @suggested_locations_count = params[:suggested_locations_count]
    @locations_added_count = params[:locations_added_count]
    @locations_deleted_count = params[:locations_deleted_count]
    @machine_comments_count = params[:machine_comments_count]
    @machines_added_count = params[:machines_added_count]
    @machines_removed_count = params[:machines_removed_count]
    @pictures_added_count = params[:pictures_added_count]
    @contact_messages_count = params[:contact_messages_count]
    @scores_added_count = params[:scores_added_count]
    @scores_deleted_count = params[:scores_deleted_count]
    @machine_comments_deleted_count = params[:machine_comments_deleted_count]

    mail(to: params[:user], subject: "Pinball Map - Weekly admin global digest - #{Date.today.strftime('%m/%d/%Y')}")
  end

  def send_weekly_admin_digest
    @region_name = params[:region_name]
    @machines_count = params[:machines_count]
    @locations_count = params[:locations_count]
    @contact_messages_count = params[:contact_messages_count]
    @machineless_locations = params[:machineless_locations]
    @suggested_locations = params[:suggested_locations]
    @suggested_locations_count = params[:suggested_locations_count]
    @locations_added_count = params[:locations_added_count]
    @locations_deleted_count = params[:locations_deleted_count]
    @machine_comments_count = params[:machine_comments_count]
    @machines_added_count = params[:machines_added_count]
    @machines_removed_count = params[:machines_removed_count]
    @pictures_added_count = params[:pictures_added_count]
    @scores_added_count = params[:scores_added_count]

    mail(to: params[:email_to], subject: params[:email_subject])
  end

  def send_admin_notification
    @name = params[:name]
    @email = params[:email]
    @message = params[:message]
    @user_info = params[:user_info]
    @user_name = params[:user_name]
    @user_email = params[:user_email]
    @remote_ip = params[:remote_ip]
    @headers = params[:headers]
    @user_agent = params[:user_agent]

    mail(to: params[:to_users], reply_to: params[:user_email] || params[:email], cc: params[:cc_users], subject: params[:subject])
  end

  def send_daily_digest_machine_condition_email
    @submissions = params[:submissions]
    @region_name = params[:region_name]
    mail(to: params[:email_to], subject: params[:email_subject])
  end

  def send_daily_digest_machine_removal_email
    @submissions = params[:submissions]
    @region_name = params[:region_name]
    mail(to: params[:email_to], subject: params[:email_subject])
  end

  def send_daily_digest_global_machine_condition_email
    @submissions = params[:submissions]
    mail(to: params[:user], subject: "Pinball Map - Daily admin global machine comment digest - #{(Date.today - 1.day).strftime('%m/%d/%Y')}")
  end

  def send_daily_digest_global_machine_removal_email
    @submissions = params[:submissions]
    mail(to: params[:user], subject: "Pinball Map - Daily admin global machine removal digest - #{(Date.today - 1.day).strftime('%m/%d/%Y')}")
  end

  def send_daily_digest_global_picture_added_email
    @submissions = params[:submissions]
    mail(to: params[:user], subject: "Pinball Map - Daily global pictures added digest - #{(Date.today - 1.day).strftime('%m/%d/%Y')}")
  end

  def send_daily_digest_global_score_added_email
    @submissions = params[:submissions]
    mail(to: params[:user], subject: "Pinball Map - Daily global scores added digest - #{(Date.today - 1.day).strftime('%m/%d/%Y')}")
  end

  def send_new_location_notification
    @location_name = params[:location_name]
    @location_street = params[:location_street]
    @location_city = params[:location_city]
    @location_state = params[:location_state]
    @location_zip = params[:location_zip]
    @location_country = params[:location_country]
    @location_phone = params[:location_phone]
    @location_website = params[:location_website]
    @location_type = params[:location_type]
    @operator = params[:operator]
    @location_comments = params[:location_comments]
    @location_machines = params[:location_machines]
    @remote_ip = params[:remote_ip]
    @headers = params[:headers]
    @user_agent = params[:user_agent]
    @user_info = params[:user_info]

    mail(to: params[:to_users], reply_to: params[:user_email], cc: params[:cc_users], subject: params[:subject])
  end
end
