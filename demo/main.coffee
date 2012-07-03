directionsRenderer = new google.maps.DirectionsRenderer()
directionsService = new google.maps.DirectionsService()
geocoder = new google.maps.Geocoder()

$ ->
    directionsRenderer = new google.maps.DirectionsRenderer()
    mapOptions =
        center: new google.maps.LatLng(-34.397, 150.644)
        zoom: 8
        mapTypeId: google.maps.MapTypeId.ROADMAP

    map = new google.maps.Map($('#map-canvas')[0], mapOptions)
    directionsRenderer.setMap(map)


    # 675 Dolores
    start = new google.maps.Marker
        position: new google.maps.LatLng(37.7585989, -122.425413)
        map: map
        title: "Start"
        draggable: true

    # 16th and Mission
    end = new google.maps.Marker
        position: new google.maps.LatLng(37.7650501, -122.4196959)
        map: map
        title: "End"
        draggable: true

    showStartEndRoute = ->
        showRoute start.position, end.position

    google.maps.event.addListener start, 'dragend', showStartEndRoute
    google.maps.event.addListener end, 'dragend', showStartEndRoute
    showStartEndRoute()


logLatLng = (address) ->
    geocoder.geocode {'address': address}, (results, status) ->
        if status == google.maps.GeocoderStatus.OK
            console.log(results[0].geometry.location)
        else
            alert 'Geocode failed: ' + status


showRoute = (start, end) ->
    request =
        origin:start,
        destination:end,
        travelMode: google.maps.TravelMode.DRIVING
    directionsService.route request, (result, status) ->
        if (status == google.maps.DirectionsStatus.OK)
            directionsRenderer.setDirections(result)
        else
            alert 'Route failed: ' + status
