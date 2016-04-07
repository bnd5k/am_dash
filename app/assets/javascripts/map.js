if (typeof AMDash === "undefined") {
  AMDash = {};
}

AMDash.initMap = function() {
  var mapElement = document.getElementById('map')

  var map = new google.maps.Map(mapElement, {
    zoom: 13,
    center: {lat: Number(mapElement.dataset.lat), lng: Number(mapElement.dataset.lon)}
  })

  var trafficLayer = new google.maps.TrafficLayer();
  trafficLayer.setMap(map);
}
