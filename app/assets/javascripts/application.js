var map;
var markers = new Array();
var infoWindows = new Array();
var searchSections = new Array('city', 'location', 'machine', 'type', 'operator', 'zone');

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
  map = new google.maps.Map(document.getElementById("map_canvas"), { mapTypeId: google.maps.MapTypeId.ROADMAP });
  infoWindows = new Array();

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

function loadingHTML() {
  return "<div class='loading'><img src='assets/spinner_blue.gif' /> Loading <div>";
}

function setOtherSearchOptions(newSection) {
  var html = "<p class='black_text'>SEARCH BY</p>";
  for (section in searchSections) {
      html += "  <a href='#' id='" + searchSections[section] + "_section_link' onclick='switchSection(\"" + searchSections[section] + "\");'>" + searchSections[section] + "</a>\n"
  }

  $('#other_search_options').html(html);
}

function switchSection(newSection) {
  setOtherSearchOptions(newSection);
  $("div .section:visible").hide();
  $('#by_' + newSection).toggle();
  $("#" + newSection + "_section_link").toggleClass("active_section_link");
}

function initSearch(region, locationID) {
  var url = '/' + region + '/locations?by_location_id=' + locationID;

  $('#locations').html(loadingHTML());
  $.get(url, function(data){$('#locations').html(data);}, 'script');
}

function showLocationDetail(locationID) {
  $('#show_location_detail_location_' + locationID).toggle();
  toggleData('location_detail_location', locationID);
  toggleArrows('location_detail', locationID);
}

function singleLocationLoad(region, locationID) {
  showLocationDetail(locationID);
  toggleData('show_machines_location', locationID);

  $('#show_machines_location_' + locationID).html(loadingHTML());
  $('#show_machines_location_' + locationID).load('/' + region + '/locations/' + locationID + '/render_machines');
}
