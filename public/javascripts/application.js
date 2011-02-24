var map;
var markers = new Array();
var infowindows = new Array();
var searchSections = new Array('city', 'location', 'machine', 'zone');

function initialize_map() {
  var latlng = new google.maps.LatLng(-34.397, 150.644);
  map = new google.maps.Map(document.getElementById("map_canvas"), { zoom: 8, center: latlng, mapTypeId: google.maps.MapTypeId.ROADMAP });
}

function hide_search_sections() {
  for (section in searchSections) {
    $('#by_' + searchSections[section] + "_open_arrow").toggle(false);
    $('#by_' + searchSections[section] + "_closed_arrow").toggle(true);
    $('#by_' + searchSections[section]).toggle(false);
  }
}

function toggle_data(name, id) {
  var main = id ? '_' + id : '';
  var open = '_open_arrow' + (id ? '_' + id : '');
  var closed = '_closed_arrow' + (id ? '_' + id : '');

  $('#' + name + main).toggle();
  $('#' + name + open).toggle();
  $('#' + name + closed).toggle();
}

function clear_infowindows() {
  if (infowindows) {
    for (i in infowindows) {
      infowindows[i].close();
    }
  }
}

function clear_markers() {
  if (markers) {
    for (i in markers) {
      markers[i].setMap(null);
    }
  }
}

function show_locations(ids, lats, lons, contents) {
  var bounds = new google.maps.LatLngBounds();

  for (i in ids) {
    var latlng = new google.maps.LatLng(lats[i], lons[i]);

    var marker = new google.maps.Marker({
      animation: google.maps.Animation.DROP,
      position: latlng,
      map: map,
    });

    markers.push(marker);
    bounds.extend(latlng);
    infowindows.push(new google.maps.InfoWindow({ content: $("<div/>").html(contents[i]).text() }));

    attach_marker_click(marker, i)
  }

  map.fitBounds(bounds);
}

function attach_marker_click(marker, index) {
  google.maps.event.addListener(marker, 'click', function() {
    clear_infowindows();
    map.panTo(marker.getPosition());
    infowindows[index].open(map, marker);
  });
}

function loading_html() {
  return "<div class='loading'><img src='images/spinner_blue.gif' /> Loading <div>";
}
