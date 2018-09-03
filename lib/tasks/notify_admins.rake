desc 'Sends emails to admins with region information'
task notify_admins: :environment do
  if Time.now.friday?
    email_bodies = []

    Region.all.each do |r|
      email_subject = "PBM - Weekly admin digest for #{r.full_name} - #{Date.today.strftime('%m/%d/%Y')}"

      email_body = r.generate_weekly_admin_email_body
      email_bodies.push(email_body)

      email_to = r.users.map(&:email)

      next if email_to.blank? || email_to.nil?

      Pony.mail(
        to: email_to,
        from: 'admin@pinballmap.com',
        subject: email_subject,
        body: email_body
      )
    end
  end
end

desc 'Sends admins a daily digest email of all new machine conditions'
task send_daily_digest_machine_condition_email: :environment do
  email_bodies = []

  Region.select(&:send_digest_comment_emails).each do |r|
    email_subject = "PBM - Daily admin machine comment digest for #{r.full_name} - #{(Date.today - 1.day).strftime('%m/%d/%Y')}"

    email_body = r.generate_daily_digest_comments_email_body

    next if email_body.nil?

    email_bodies.push(email_body)
    email_to = r.users.map(&:email)

    next if email_to.blank? || email_to.nil?

    Pony.mail(
      to: email_to,
      from: 'admin@pinballmap.com',
      subject: email_subject,
      body: email_body
    )
  end

  email_bodies.push(Region.generate_daily_digest_regionless_comments_email_body)

  User.where(is_super_admin: 'Y').each do |u|
    Pony.mail(
      to: u.email,
      from: 'admin@pinballmap.com',
      subject: "PBM - Daily admin machine comment digest for ALL locations - #{(Date.today - 1.day).strftime('%m/%d/%Y')}",
      body: 'CHECK THE ATTACHMENT, PLEASE',
      attachments: { 'daily_all_location_comments_info.txt' => email_bodies.join("\n\n") }
    )
  end
end

desc 'Sends admins a daily digest email of all machine removals'
task send_daily_digest_machine_removal_email: :environment do
  email_bodies = []

  Region.select(&:send_digest_removal_emails).each do |r|
    email_subject = "PBM - Daily admin machine removal digest for #{r.full_name} - #{(Date.today - 1.day).strftime('%m/%d/%Y')}"

    email_body = r.generate_daily_digest_removals_email_body

    next if email_body.nil?

    email_bodies.push(email_body)
    email_to = r.users.map(&:email)

    next if email_to.blank? || email_to.nil?

    Pony.mail(
      to: email_to,
      from: 'admin@pinballmap.com',
      subject: email_subject,
      body: email_body
    )
  end

  email_bodies.push(Region.generate_daily_digest_regionless_removals_email_body)

  User.where(is_super_admin: 'Y').each do |u|
    Pony.mail(
      to: u.email,
      from: 'admin@pinballmap.com',
      subject: "PBM - Daily admin machine removal digest for ALL locations - #{(Date.today - 1.day).strftime('%m/%d/%Y')}",
      body: 'CHECK THE ATTACHMENT, PLEASE',
      attachments: { 'daily_all_machine_deletion_info.txt' => email_bodies.join("\n\n") }
    )
  end
end
