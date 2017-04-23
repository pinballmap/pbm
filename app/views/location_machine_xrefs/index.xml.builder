xml.instruct! :xml, version: '1.0'
xml.data do
  xml.items do
    @lmxs.each do |lmx|
      cloned_lmx = lmx.clone
      xml.item do
        xml.title "#{cloned_lmx.machine.name} was added to #{cloned_lmx.location.name}"
        xml.description "Added on #{cloned_lmx.created_at.nil? ? '' : cloned_lmx.created_at.strftime('%d-%b-%Y')}"
      end
      cloned_lmx = nil
    end
  end
end
