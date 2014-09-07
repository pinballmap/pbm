json.items @lmxs.each do |json, lmx|
  json.item do
    json.title "#{lmx.machine.name} was added to #{lmx.location.name}"
    json.description "Added on #{lmx.created_at.nil? ? '' : lmx.created_at.strftime('%d-%b-%Y')}"
  end
end
