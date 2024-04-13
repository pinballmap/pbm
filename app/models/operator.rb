class Operator < ApplicationRecord
  has_paper_trail
  belongs_to :region, optional: true
  has_many :locations
  has_many :suggested_locations

  scope :region, (->(name) { where(region_id: Region.find_by_name(name.downcase).id) })

  def operator_has_email
    email.blank? ? false : true
  end

  before_save do
    Status.where(status_type: 'operators').update({ updated_at: Time.current })
  end

  before_destroy do
    Status.where(status_type: 'operators').update({ updated_at: Time.current })
  end

  def send_recent_comments
    return if email.to_s == ''

    machine_conditions_to_email = []
    locations.each do |l|
      l.location_machine_xrefs.each do |lmx|
        lmx.machine_conditions.where('created_at BETWEEN ? AND ?', (Time.now - 1.day).beginning_of_day, (Time.now - 1.day).end_of_day).each do |mc|
          machine_conditions_to_email.push(mc)
        end
      end
    end

    return if machine_conditions_to_email.empty?

    body = "Here's a list of comments made on your pinball machines yesterday on Pinball Map. We're sending this in the hope that it will help you identify, and fix, problems. If you don't want to receive these messages, just reply to this message and tell us!\n"

    machine_conditions_to_email.sort.each do |mc|
      # OperatorMailer.with(email: email, comment: mc.comment, location_name: mc.location_machine_xref.location.name, location_address: mc.location_machine_xref.location.full_street_address, machine: mc.location_machine_xref.machine.name, date: mc.updated_at.strftime('%b %d, %Y - %I:%M%p %Z')).send_recent_comments.deliver_now

      body += <<HERE

Comment: #{mc.comment}
Location: #{mc.location_machine_xref.location.name} - #{mc.location_machine_xref.location.full_street_address}
Machine: #{mc.location_machine_xref.machine.name}
Date: #{mc.updated_at.strftime('%b %d, %Y - %I:%M%p %Z')}
HERE
    end

    unless Rails.env.test?
      puts body
      sleep(10) # throttle potection
    end

    OperatorMailer.with(email: email, body: body).send_recent_comments.deliver_now

    # Pony.mail(
    #   to: email,
    #   from: 'Pinball Map <admin@pinballmap.com>',
    #   subject: "Pinball Map - Daily digest of comments on your machines - #{Date.today.strftime('%m/%d/%Y')}",
    #   body: body
    # )
  end
end
