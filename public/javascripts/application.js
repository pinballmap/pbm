$(function () {
  $('#location_search', '.add_new_machine', '.update_machine_condition', '.remove_machine', '.add_high_score').submit(function () {
    $.get(this.action, $(this).serialize(), null, 'script');
    return false;
  });
});

var map;

function initializeMap() {
  var latlng = new google.maps.LatLng(-34.397, 150.644);
  map = new google.maps.Map(document.getElementById("map_canvas"), { zoom: 8, center: latlng, mapTypeId: google.maps.MapTypeId.ROADMAP });
}

function showLocation(id, lat, lon) {
  var latlng = new google.maps.LatLng(lat, lon);

  var marker = new google.maps.Marker({
      position: latlng,
      map: map,
      title: "Brotastic"
  });

  map.setCenter(latlng, 0);

  $('#location_detail_' + id).toggle();
  $('#machine_summary_' + id).toggle();
}
