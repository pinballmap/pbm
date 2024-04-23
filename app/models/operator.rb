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

    comments = []
    heading = "Here are the comments left on your pinball machines yesterday on Pinball Map. We hope this helps you identify and fix problems. You opted in to receive these, but if you don't want them anymore reply to this message and tell us! Also, see our FAQ: https://pinballmap.com/faq#operators"

    machine_conditions_to_email.sort.each do |mc|
      comment = "Comment: #{mc.comment}\nLocation: #{mc.location_machine_xref.location.name} - #{mc.location_machine_xref.location.full_street_address}\nMachine: #{mc.location_machine_xref.machine.name}\nDate: #{mc.updated_at.strftime('%b %d, %Y - %I:%M%p %Z')}"
      comments << comment
    end

    OperatorMailer.with(email: email, heading: heading, comments: comments).send_recent_comments.deliver_now

    unless Rails.env.test?
      sleep(8) # throttle potection
    end
  end
end
