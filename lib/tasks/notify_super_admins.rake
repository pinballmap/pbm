desc 'Sends emails to super admins with all region information'
task notify_super_admins: :environment do
  email_bodies = []

  Region.all.each do |r|
    email_body = r.generate_weekly_admin_email_body
    email_bodies.push(email_body)
  end

  User.where(is_super_admin: 'Y').each do |u|
    Pony.mail(
      to: u.email,
      from: 'admin@pinballmap.com',
      subject: "PBM - Weekly admin digest for all regions - #{Date.today.strftime('%m/%d/%Y')}",
      body: 'CHECK THE ATTACHMENT, BROH',
      attachments: { 'all_region_info.txt' => email_bodies.join("\n\n") }
    )
  end
end
