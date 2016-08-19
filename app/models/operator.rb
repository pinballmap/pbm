class Operator < ActiveRecord::Base
  belongs_to :region
  has_many :locations

  attr_accessible :name, :region_id, :email, :website, :phone

  scope :region, ->(name) { where(region_id: Region.find_by_name(name.downcase).id) }

  def send_recent_comments
    return if email.to_s == ''

    machine_conditions_to_email = []
    locations.each do |l|
      l.location_machine_xrefs.each do |lmx|
        lmx.machine_conditions.where('created_at BETWEEN ? AND ?', DateTime.now.beginning_of_day, DateTime.now.end_of_day).each do |mc|
          machine_conditions_to_email.push(mc)
        end
      end
    end

    return if machine_conditions_to_email.empty?

    body = "Here's a list of comments made on your pinball machines that were posted today to #{region.full_name}. We're sending this in the hope that it will help you identify, and fix, problems. If you don't want to receive these messages, please contact pinballmap@posteo.org.\n"

    machine_conditions_to_email.sort.each do |mc|
      body += <<HERE

Comment: #{mc.comment}
Location: #{mc.location_machine_xref.location.name} - #{mc.location_machine_xref.location.full_street_address}
Machine: #{mc.location_machine_xref.machine.name}
HERE
    end

    Pony.mail(
      to: email,
      from: 'admin@pinballmap.com',
      subject: "Pinball Map - Daily Digest of comments made on your machines - #{Date.today.strftime('%m/%d/%Y')}",
      body: body
    )
  end
end
