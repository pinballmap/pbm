xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title 'Pinball Map - New Machine List'
    xml.description 'Find pinball machines!'
    xml.link root_path

    for lmx in @lmxs
      machine = lmx.machine
      location = lmx.location
      xml.item do
        xml.title "#{machine.name} was added to #{location.name}"
        xml.link "http://pinballmap.com/#{@region.name.downcase}/?by_location_id=#{location.id}"
        xml.description "Added on #{lmx.created_at.to_s(:rfc822)}"
        xml.guid lmx.id
        xml.pubDate lmx.created_at.to_s(:rfc822)
      end
    end
  end
end
