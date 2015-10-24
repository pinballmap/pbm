xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "#{@region.full_name} Pinball Map - Events List"
    xml.description "Find pinball events!"
    xml.link "http://#{request.host}"

    for event in @events
      xml.item do
        xml.title event.name
        xml.link event.external_link? ? event.external_link : "http://pinballmap.com/#{@region.name.downcase}/events"
        xml.description "#{event.start_date.nil? ? '' : "Event Date: #{event.start_date}"}#{event.end_date.nil? ? '' : " - #{event.end_date}"}#{event.start_date.nil? ? '' : '. '}#{event.long_desc? ? "Event Description: #{event.long_desc} " : ''}#{event.location_id.nil? ? '' : "Map Location Link: http://pinballmap.com/#{@region.name.downcase}/?by_location_id=#{event.location_id}"}"
        xml.guid event.id, :isPermaLink => false
        xml.pubDate event.created_at.nil? ? 'UNKNOWN' : event.created_at.to_s(:rfc822)
      end
    end
  end
end
