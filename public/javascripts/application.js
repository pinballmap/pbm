$(function () {
  $('#location_search', '.add_new_machine', '.update_machine_condition', '.remove_machine', '.add_high_score').submit(function () {
    $.get(this.action, $(this).serialize(), null, 'script');
    return false;
  });
});

var map;

function initialize_map() {
  var latlng = new google.maps.LatLng(-34.397, 150.644);
  map = new google.maps.Map(document.getElementById("map_canvas"), { zoom: 8, center: latlng, mapTypeId: google.maps.MapTypeId.ROADMAP });
}

function toggle_data(name, id) {
  $('#' + name + '_' + id).toggle();
  $('#' + name + '_open_arrow_' + id).toggle();
  $('#' + name + '_closed_arrow_' + id).toggle();
}

function show_location(id, lat, lon) {
  var latlng = new google.maps.LatLng(lat, lon);

  var marker = new google.maps.Marker({
      position: latlng,
      map: map,
  });

  map.setCenter(latlng, 0);
}
