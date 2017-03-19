xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "#{@region.full_name} Pinball Map - New Score List"
    xml.description "Find pinball machines!"
    xml.link root_path

    for msx in @msxs
      machine = msx.machine
      location = msx.location
      xml.item do
        xml.title "#{location.name}'s #{machine.name}: #{msx.score} by #{msx.user ? msx.user.username : 'Unknown'} on #{msx.created_at.to_s(:rfc822)}"
        xml.link region_homepage_path(@region.name.downcase) + "/?by_location_id=#{location.id}"
        xml.description "#{location.name}'s #{machine.name}: #{msx.score} by #{msx.user ? msx.user.username : 'Unknown'} on #{msx.created_at.to_s(:rfc822)}"
        xml.guid msx.id
        xml.pubDate msx.created_at.to_s(:rfc822)
      end
    end
  end
end
