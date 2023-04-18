xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0' do
  xml.channel do
    xml.title "#{@region.full_name} Pinball Map - Events List"
    xml.description 'Find pinball events!'
    xml.link [request.protocol, request.host_with_port].join('')

    @events.each do |event|
      xml.item do
        xml.title event.name
        xml.link event.external_link? ? event.external_link : events_path(@region.name.downcase)
        xml.description "#{event.start_date.nil? ? '' : "Event Date: #{event.start_date}"}#{event.end_date.nil? ? '' : " - #{event.end_date}"}#{event.start_date.nil? ? '' : '. '}#{event.long_desc? ? "Event Description: #{event.long_desc} " : ''}#{event.location_id.nil? ? '' : 'Map Location Link: ' + region_homepage_path(@region.name.downcase) + "/?by_location_id=#{event.location_id}"}"
        xml.guid event.id, isPermaLink: false
        xml.pubDate event.created_at.nil? ? 'UNKNOWN' : event.created_at.to_fs(:rfc822)
      end
    end
  end
end
