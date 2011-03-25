xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title 'Pinball Map - New Machine List'
    xml.description 'Find pinball machines!'
    xml.link root_path

    for lmx in @lmxs
      location = lmx.location
      machine = lmx.machine
      xml.item do
        xml.description "Added on #{lmx.created_at.to_s(:rfc822)}"
        xml.guid lmx.id
        xml.pubDate lmx.created_at.to_s(:rfc822)
      end
    end
  end
end
