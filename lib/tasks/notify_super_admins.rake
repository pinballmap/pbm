desc 'Sends emails to super admins with all region information'
task notify_super_admins: :environment do
  unless Rails.env.staging?
    email_bodies = []

    Region.all.each do |r|
      email_body = r.generate_weekly_admin_email_body
      email_bodies.push(email_body)
    end

    User.where(is_super_admin: 'Y').each do |u|
      Pony.mail(
        to: u.email,
        from: 'Pinball Map <admin@pinballmap.com>',
        subject: "Pinball Map - Weekly admin digest for all regions - #{Date.today.strftime('%m/%d/%Y')}",
        body: "CHECK THE ATTACHMENT, BROH. Right now we have #{Location.count} locations and #{LocationMachineXref.count} total machines.",
        attachments: { 'all_region_info.txt' => email_bodies.join("\n\n") }
      )

      Pony.mail(
        to: u.email,
        from: 'Pinball Map <admin@pinballmap.com>',
        subject: "Pinball Map - Weekly admin REGIONLESS digest - #{Date.today.strftime('%m/%d/%Y')}",
        body: Region.generate_weekly_regionless_email_body
      )
    end
  end
rescue StandardError => e
  Pony.mail(
    to: 'admin@pinballmap.com',
    from: 'Pinball Map <admin@pinballmap.com>',
    subject: "Pbm Rake Task Error - Weekly Super Admins - #{Date.today.strftime('%m/%d/%Y')}",
    body: "Weekly super admins rake task error\n\n" + e.to_s
  )
end
