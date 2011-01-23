module LocationsHelper
  def open_closed_arrows_for(name, id)
    arrows = "<div id='#{name}_open_arrow_#{id}' class='float_left' style='display: none;'><img alt='open arrow' src='images/open_arrow.gif' /></div>"
    arrows += "<div id='#{name}_closed_arrow_#{id}' class='float_left'><img alt='closed arrow' src='images/closed_arrow.gif' /></div>"

    arrows.html_safe
  end

  def format_location_content(location)
    content = "'<div class=\"infowindow\">"
    content += [location.name, location.street, [location.city, location.state, location.zip].join(', '), location.phone].join('<br />')
    content += '<hr /><br />'

    machines = location.machines.map {|m| m.name + '<br />'}

    content += machines.join
    content += "</div>'"

    content.html_safe
  end

  def locations_javascript_data(locations)
    ids = Array.new
    lats = Array.new
    lons = Array.new
    contents = Array.new

    locations.each do |l|
      ids      << l.id
      lats     << l.lat
      lons     << l.lon
      contents << format_location_content(l)
    end

    [ids, lats, lons, contents]
  end
end
