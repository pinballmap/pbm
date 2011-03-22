var map;
var markers = new Array();
var infoWindows = new Array();
var searchSections = new Array('city', 'location', 'machine', 'zone');

function initializeMap() {
  var latlng = new google.maps.LatLng(-34.397, 150.644);
  map = new google.maps.Map(document.getElementById("map_canvas"), { zoom: 8, center: latlng, mapTypeId: google.maps.MapTypeId.ROADMAP });
}

function hideSearchSections() {
  for (section in searchSections) {
    $('#by_' + searchSections[section] + "_open_arrow").toggle(false);
    $('#by_' + searchSections[section] + "_closed_arrow").toggle(true);
    $('#by_' + searchSections[section]).toggle(false);
  }
}

function toggleArrows(name, id) {
  var open = '_open_arrow' + (id ? '_' + id : '');
  var closed = '_closed_arrow' + (id ? '_' + id : '');

  $('#' + name + open).toggle();
  $('#' + name + closed).toggle();
}

function toggleData(name, id) {
  var main = id ? '_' + id : '';

  $('#' + name + main).toggle();
  toggleArrows(name, id);
}

function clearInfoWindows() {
  if (infoWindows) {
    for (i in infoWindows) {
      infoWindows[i].close();
    }
  }
}

function clearMarkers() {
  if (markers) {
    for (i in markers) {
      markers[i].setMap(null);
    }
  }
}

function showLocations(ids, lats, lons, contents) {
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
    infoWindows.push(new google.maps.InfoWindow({ content: contents[i] }));

    attachMarkerClick(marker, i)
  }

  map.fitBounds(bounds);
}

function attachMarkerClick(marker, index) {
  google.maps.event.addListener(marker, 'click', function() {
    clearInfoWindows();
    map.panTo(marker.getPosition());
    infoWindows[index].open(map, marker);
  });
}

function loading_html() {
  return "<div class='loading'><img src='images/spinner_blue.gif' /> Loading <div>";
}
