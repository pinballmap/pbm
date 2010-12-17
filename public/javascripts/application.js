$(function () {
  $('#location_search').submit(function () {
    $.get(this.action, $(this).serialize(), null, 'script');
    return false;
  });
});

var map;

function initializeMap() {
  var latlng = new google.maps.LatLng(-34.397, 150.644);
  map = new google.maps.Map(document.getElementById("map_canvas"), { zoom: 8, center: latlng, mapTypeId: google.maps.MapTypeId.ROADMAP });
}

function showLocation(lat, lon) {
console.log(lat);
console.log(lon);
  var latlng = new google.maps.LatLng(lat, lon);

  var marker = new google.maps.Marker({
      position: latlng,
      map: map,
      title: "Brotastic"
  });

  map.setCenter(latlng, 0);
}
