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

    markers = []
    doRoute = -> getRoute(start.position, end.position, (result) ->
        directionsRenderer.setDirections(result)

        for marker in markers
            marker.setMap(null)
        markers = []

        # We only get one route back because we didn't request
        # alternatives. We only get one leg because we didn't
        # specify waypoints.
        leg = result.routes[0].legs[0]

        for step in leg.steps
            for point in step.path
                markers.push(new google.maps.Marker
                    position: point
                    map: map
                )
    )

    google.maps.event.addListener start, 'dragend', doRoute
    google.maps.event.addListener end, 'dragend', doRoute
    doRoute()


logLatLng = (address) ->
    geocoder.geocode {'address': address}, (results, status) ->
        if status == google.maps.GeocoderStatus.OK
            console.log(results[0].geometry.location)
        else
            alert 'Geocode failed: ' + status


getRoute = (start, end, onSuccess) ->
    request =
        origin:start,
        destination:end,
        travelMode: google.maps.TravelMode.DRIVING
    directionsService.route request, (result, status) ->
        if (status == google.maps.DirectionsStatus.OK)
            onSuccess(result)
        else
            alert 'Route failed: ' + status
