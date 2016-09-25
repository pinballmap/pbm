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

  User.where(is_super_admin: 'Y').each do |u|
    Pony.mail(
      to: u.email,
      from: 'admin@pinballmap.com',
      subject: "PBM - Weekly admin digest for all regions - #{Date.today.strftime('%m/%d/%Y')}",
      body: email_bodies.join("\n\n")
    )
  end
end
