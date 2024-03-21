desc 'Sends emails to admins with region information'
task notify_admins: :environment do
  unless Rails.env.staging?
    email_bodies = []

    Region.all.each do |r|
      email_subject = "Pinball Map - Weekly admin digest (#{r.full_name}) - #{Date.today.strftime('%m/%d/%Y')}"

      email_body = r.generate_weekly_admin_email_body
      email_bodies.push(email_body)

      email_to = r.users.map(&:email)

      next if email_to.blank? || email_to.nil?

      Pony.mail(
        to: email_to,
        from: 'Pinball Map <admin@pinballmap.com>',
        subject: email_subject,
        body: email_body
      )
    end
  end
rescue StandardError => e
  Pony.mail(
    to: 'admin@pinballmap.com',
    from: 'Pinball Map <admin@pinballmap.com>',
    subject: "Pbm Rake Task Error - Weekly Digest - #{Date.today.strftime('%m/%d/%Y')}",
    body: "Weekly digest rake task error\n\n" + e.to_s
  )
end

desc 'Sends admins a daily digest email of all new machine conditions'
task send_daily_digest_machine_condition_email: :environment do
  unless Rails.env.staging?
    email_bodies = []

    Region.select(&:send_digest_comment_emails).each do |r|
      email_subject = "Pinball Map - Daily admin machine comment digest (#{r.full_name}) - #{(Date.today - 1.day).strftime('%m/%d/%Y')}"

      email_body = r.generate_daily_digest_comments_email_body

      next if email_body.nil?

      email_bodies.push(email_body)
      email_to = r.users.map(&:email)

      next if email_to.blank? || email_to.nil?

      Pony.mail(
        to: email_to,
        from: 'Pinball Map <admin@pinballmap.com>',
        subject: email_subject,
        body: email_body
      )
    end
  end
rescue StandardError => e
  Pony.mail(
    to: 'admin@pinballmap.com',
    from: 'Pinball Map <admin@pinballmap.com>',
    subject: "Pbm Rake Task Error - Daily Comments - #{Date.today.strftime('%m/%d/%Y')}",
    body: "Daily comments rake task error\n\n" + e.to_s
  )
end

desc 'Sends admins a daily digest email of all machine removals'
task send_daily_digest_machine_removal_email: :environment do
  unless Rails.env.staging?
    email_bodies = []

    Region.select(&:send_digest_removal_emails).each do |r|
      email_subject = "Pinball Map - Daily admin machine removal digest (#{r.full_name}) - #{(Date.today - 1.day).strftime('%m/%d/%Y')}"

      email_body = r.generate_daily_digest_removals_email_body

      next if email_body.nil?

      email_bodies.push(email_body)
      email_to = r.users.map(&:email)

      next if email_to.blank? || email_to.nil?

      Pony.mail(
        to: email_to,
        from: 'Pinball Map <admin@pinballmap.com>',
        subject: email_subject,
        body: email_body
      )
    end
  end
rescue StandardError => e
  Pony.mail(
    to: 'admin@pinballmap.com',
    from: 'Pinball Map <admin@pinballmap.com>',
    subject: "Pbm Rake Task Error - Daily Removals - #{Date.today.strftime('%m/%d/%Y')}",
    body: "Daily removals rake task error\n\n" + e.to_s
  )
end
