xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "#{@region ? @region.full_name + ' ' : ''}Pinball Map - New Machine List#{request.path_info.include?('machine_id') ? ' - ' + @lmxs.first.machine.name : ''}"
    xml.description "Find pinball machines!"
    xml.link [ request.protocol, request.host_with_port ].join("")

    @lmxs.each do |lmx|
      xml.item do
        xml.title [ "#{lmx.machine_name} was added to #{lmx.location_name} in #{lmx.city_name}#{lmx.user_name.nil? ? '' : ' by ' + lmx.user_name}" ].join("")
        xml.link [ request.protocol, request.host_with_port, @region ? region_homepage_path(@region.name.downcase) : "/map", "/?by_location_id=#{lmx.location_id}" ].join("")
        xml.description "Added on #{lmx.created_at.nil? ? 'UNKNOWN' : lmx.created_at.to_fs(:rfc822)}"
        xml.guid lmx.id, isPermaLink: false
        xml.pubDate lmx.created_at.nil? ? "UNKNOWN" : lmx.created_at.to_fs(:rfc822)
      end
      lmx = nil
    end
  end
end
