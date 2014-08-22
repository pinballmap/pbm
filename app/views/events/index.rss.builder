xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title 'Pinball Map - Events List'
    xml.description 'Find pinball events!'
    xml.link root_path

    for event in @events
      xml.event do
        xml.name event.name
        xml.link event.external_link
        xml.description event.long_desc
        xml.startDate event.start_date
        xml.endDate event.end_date
        xml.pbmLocation event.location_id ? "http://pinballmap.com/#{@region.name.downcase}/?by_location_id=#{event.location_id}" : 'UNKNOWN'
        xml.guid event.id
        xml.pubDate event.created_at.nil? ? 'UNKNOWN' : event.created_at.to_s(:rfc822)
      end
    end
  end
end
