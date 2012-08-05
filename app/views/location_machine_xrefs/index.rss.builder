xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title 'Pinball Map - New Machine List'
    xml.description 'Find pinball machines!'
    xml.link root_path

    for lmx in @lmxs
      cloned_lmx = lmx.clone
      machine = cloned_lmx.machine
      location = cloned_lmx.location
      xml.item do
        xml.title "#{machine.name} was added to #{location.name}"
        xml.link "http://pinballmap.com/#{@region.name.downcase}/?by_location_id=#{location.id}"
        xml.description "Added on #{cloned_lmx.created_at.nil? ? 'UNKNOWN' : cloned_lmx.created_at.to_s(:rfc822)}"
        xml.guid cloned_lmx.id
        xml.pubDate cloned_lmx.created_at.nil? ? 'UNKNOWN' : cloned_lmx.created_at.to_s(:rfc822)
      end
      cloned_lmx = nil
    end
  end
end
