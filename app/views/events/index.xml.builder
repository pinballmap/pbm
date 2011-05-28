xml.instruct! :xml, :version => "1.0"
xml.data do
  xml.events do
    for event in @events
      xml.event do
        xml.id event.id
        xml.name event.name
        xml.longDesc event.long_desc
        xml.link event.external_link
        xml.categoryNo event.category_no
        xml.startDate event.start_date
        xml.locationNo event.location_id
      end
    end
  end
end
