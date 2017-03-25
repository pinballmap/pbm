desc 'Sends emails to admins with region information'
task notify_admins: :environment do
  email_bodies = []

  Region.all.each do |r|
    email_subject = "PBM - Weekly admin digest for #{r.full_name} - #{Date.today.strftime('%m/%d/%Y')}"

    email_body = r.generate_weekly_admin_email_body
    email_bodies.push(email_body)

    email_to = r.users.map(&:email)

    Pony.mail(
      to: email_to,
      from: 'admin@pinballmap.com',
      subject: email_subject,
      body: email_body
    )
  end
end

desc 'Sends admins a daily digest email of all new machine conditions'
task send_daily_digest_machine_condition_email: :environment do
  Region.select(&:send_digest_comment_emails).each do |r|
    email_subject = "PBM - Daily admin machine comment digest for #{r.full_name} - #{(Date.today - 1.day).strftime('%m/%d/%Y')}"

    email_body = r.generate_daily_digest_comments_email_body
    email_to = r.users.map(&:email)

    Pony.mail(
      to: email_to,
      from: 'admin@pinballmap.com',
      subject: email_subject,
      body: email_body
    )
  end
end

desc 'Sends admins a daily digest email of all machine removals'
task send_daily_digest_machine_removal_email: :environment do
  Region.select(&:send_digest_removal_emails).each do |r|
    email_subject = "PBM - Daily admin machine removal digest for #{r.full_name} - #{(Date.today - 1.day).strftime('%m/%d/%Y')}"

    email_body = r.generate_daily_digest_removals_email_body
    email_to = r.users.map(&:email)

    Pony.mail(
      to: email_to,
      from: 'admin@pinballmap.com',
      subject: email_subject,
      body: email_body
    )
  end
end
