class Operator < ActiveRecord::Base
  belongs_to :region
  has_many :locations

  attr_accessible :name, :region_id, :email, :website, :phone

  def recent_comments_email_body
    machine_conditions_to_email = []
    locations.each do |l|
      l.location_machine_xrefs.each do |lmx|
        lmx.machine_conditions.where('created_at BETWEEN ? AND ?', DateTime.now.beginning_of_day, DateTime.now.end_of_day).each do |mc|
          machine_conditions_to_email.push(mc)
        end
      end
    end

    body_text = nil

    unless machine_conditions_to_email.empty?
      body_text = "Here's a list of comments made on your pinball machines that were posted today to #{region.full_name}. We're sending this in the hope that it will help you identify, and fix, problems. If you don't want to receive these messages, please contact pinballmap@posteo.org.\n"

      machine_conditions_to_email.sort.each do |mc|
        body_text += <<HERE

Comment: #{mc.comment}
Location: #{mc.location_machine_xref.location.name} - #{mc.location_machine_xref.location.full_street_address}
Machine: #{mc.location_machine_xref.machine.name}
HERE
      end
    end

    body_text
  end
end
