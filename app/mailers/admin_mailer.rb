class AdminMailer < ApplicationMailer
  def weekly_admin_digest_regionless
    @machines_count = params[:machines_count]
    @locations_count = params[:locations_count]
    @machineless_locations = params[:machineless_locations]
    @suggested_locations = params[:suggested_locations]
    @suggested_locations_count = params[:suggested_locations_count]
    @locations_added_count = params[:locations_added_count]
    @locations_deleted_count = params[:locations_deleted_count]
    @machine_comments_count = params[:machine_comments_count]
    @machines_added_count = params[:machines_added_count]
    @machines_removed_count = params[:machines_removed_count]

    mail(to: params[:user], subject: "Pinball Map - Weekly admin REGIONLESS digest - #{Date.today.strftime('%m/%d/%Y')}")
  end

  def weekly_admin_digest_all_regions
    attachments['all_region_info.txt'] = { mime_type: 'text/plain', content: params[:email_bodies].join("\n\n") }

    mail(to: params[:user], subject: "Pinball Map - Weekly admin digest for all regions - #{Date.today.strftime('%m/%d/%Y')}")
  end

  def notify_admins
    @region_name = params[:region_name]
    @machines_count = params[:machines_count]
    @locations_count = params[:locations_count]
    @events_count = params[:events_count]
    @events_new_count = params[:events_new_count]
    @contact_messages_count = params[:contact_messages_count]
    @machineless_locations = params[:machineless_locations]
    @suggested_locations = params[:suggested_locations]
    @suggested_locations_count = params[:suggested_locations_count]
    @locations_added_count = params[:locations_added_count]
    @locations_deleted_count = params[:locations_deleted_count]
    @machine_comments_count = params[:machine_comments_count]
    @machines_added_count = params[:machines_added_count]
    @machines_removed_count = params[:machines_removed_count]

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

    mail(to: params[:to_users], cc: params[:cc_users], subject: params[:subject])
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

  def send_daily_digest_regionless_machine_condition_email
    @submissions = params[:submissions]
    mail(to: params[:user], subject: "Pinball Map - Daily admin REGIONLESS machine comment digest - #{(Date.today - 1.day).strftime('%m/%d/%Y')}")
  end

  def send_daily_digest_regionless_machine_removal_email
    @submissions = params[:submissions]
    mail(to: params[:user], subject: "Pinball Map - Daily admin REGIONLESS machine removal digest - #{(Date.today - 1.day).strftime('%m/%d/%Y')}")
  end

  def picture_added
    @photo_id = params[:photo_id]
    @location_name = params[:location_name]
    @region_name = params[:region_name]
    @photo_url = params[:photo_url]

    mail(to: params[:to_users], subject: 'Pinball Map - Picture added')
  end

  def picture_removed
    @photo_id = params[:photo_id]
    @location_name = params[:location_name]

    mail(to: 'admin@pinballmap.com', subject: 'Pinball Map - Picture removed')
  end

  def new_machine_name
    @machine_name = params[:machine_name]
    @location_name = params[:location_name]
    @remote_ip = params[:remote_ip]
    @user_agent = params[:user_agent]
    @user_info = params[:user_info]

    mail(to: params[:to_users], subject: params[:subject])
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

    mail(to: params[:to_users], cc: params[:cc_users], subject: params[:subject])
  end
end
