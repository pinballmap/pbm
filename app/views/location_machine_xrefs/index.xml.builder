xml.instruct! :xml, :version => "1.0"
xml.data do
  xml.items do
    for lmx in @lmxs
      xml.item do
        xml.title "#{lmx.machine.name} was added to #{lmx.location.name}"
        xml.description "Added on #{lmx.created_at.nil? ? '' : lmx.created_at.strftime("%d-%b-%Y")}"
      end
    end
  end
end
