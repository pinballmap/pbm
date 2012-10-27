json.events @events.each do |json, event|
  json.event do
    json.id event.id
    json.name event.name
    json.longDesc event.long_desc
    json.link event.external_link
    json.categoryNo event.category_no
    json.startDate event.start_date
    json.locationNo event.location_id
  end
end
