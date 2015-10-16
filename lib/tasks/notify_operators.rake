desc 'Sends emails to operators with recent comments on their machines'
task notify_operators: :environment do
  Region.all.each do |r|
    r.operators.select{|o| !o.email.blank?}.each do |o|
        machine_conditions_to_email = []

        o.locations.each do |l|
            l.location_machine_xrefs.each do |lmx|
                lmx.machine_conditions.where('created_at BETWEEN ? AND ?', DateTime.now.beginning_of_day, DateTime.now.end_of_day).each do |mc|
                    machine_conditions_to_email.push(mc)
                end
            end
        end

        if !machine_conditions_to_email.empty?
            body_text = "Here's a list of comments made on your pinball machines that were posted today to #{r.full_name}. We're sending this in the hope that it will help you identify, and fix, problems. If you don't want to receive these messages, please contact pinballmap@posteo.org.\n\n"

            machine_conditions_to_email.each do |mc|
                body_text += <<HERE

Comment: #{mc.comment}
Location: #{mc.location_machine_xref.location.name} - #{mc.location_machine_xref.location.full_street_address}
Machine: #{mc.location_machine_xref.machine.name}
HERE

            Pony.mail(
              to: o.email,
              from: 'admin@pinballmap.com',
              subject: "Pinball Map - Daily Digest of comments made on your machines - #{Date.today.strftime('%m/%d/%Y')}",
              body: body_text
            )
        end
      end
    end
  end
end
