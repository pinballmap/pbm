desc 'Sends emails to admins with region information'
task notify_admins: :environment do
  Region.all.each do |r|
    email_subject = "PBM - Weekly admin digest for #{r.full_name} - #{Date.today.strftime('%m/%d/%Y')}"
    email_body = r.generate_weekly_admin_email_body
    email_to = r.users.map { |u| u.email }

    Pony.mail(
      to: email_to,
      from: 'admin@pinballmap.com',
      subject: email_subject,
      body: email_body
    )
  end
end
