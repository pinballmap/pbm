xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title 'Pinball Map - New Score List'
    xml.description 'Find pinball machines!'
    xml.link root_path

    for msx in @msxs
      machine = msx.machine
      location = msx.location
      xml.item do
        xml.title "#{msx.location.name}'s #{msx.machine.name}: #{MachineScoreXref::ENGLISH_SCORES[msx.rank]}, with #{msx.score} by #{msx.user.initials} on #{msx.created_at.to_s(:rfc822)}"
        xml.description "#{msx.location.name}'s #{msx.machine.name}: #{MachineScoreXref::ENGLISH_SCORES[msx.rank]}, with #{msx.score} by #{msx.user.initials} on #{msx.created_at.to_s(:rfc822)}"
        xml.guid msx.id
        xml.pubDate msx.created_at.to_s(:rfc822)
      end
    end
  end
end
