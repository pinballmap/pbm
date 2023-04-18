xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0' do
  xml.channel do
    xml.title "#{@region ? @region.full_name : ''} Pinball Map - New Machine List"
    xml.description 'Find pinball machines!'
    xml.link [request.protocol, request.host_with_port].join('')

    @lmxs.each do |lmx|
      cloned_lmx = lmx.clone
      machine = cloned_lmx.machine
      location = cloned_lmx.location
      xml.item do
        xml.title ["#{machine.name}#{machine.year_and_manufacturer} was added to #{location.name} in #{location.city}#{cloned_lmx.last_updated_by_username && cloned_lmx.last_updated_by_username.empty? ? '' : ' by ' + cloned_lmx.last_updated_by_username}"].join('')
        xml.link [request.protocol, request.host_with_port, location.region && @region ? region_homepage_path(location.region.name.downcase) : '/map', "/?by_location_id=#{location.id}"].join('')
        xml.description "Added on #{cloned_lmx.created_at.nil? ? 'UNKNOWN' : cloned_lmx.created_at.to_fs(:rfc822)}"
        xml.guid cloned_lmx.id, isPermaLink: false
        xml.pubDate cloned_lmx.created_at.nil? ? 'UNKNOWN' : cloned_lmx.created_at.to_fs(:rfc822)
      end
      cloned_lmx = nil
    end
  end
end
