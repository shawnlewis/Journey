directionsRenderer = new google.maps.DirectionsRenderer()
directionsService = new google.maps.DirectionsService()

$ ->
    directionsRenderer = new google.maps.DirectionsRenderer()
    mapOptions =
        center: new google.maps.LatLng(-34.397, 150.644)
        zoom: 8
        mapTypeId: google.maps.MapTypeId.ROADMAP

    map = new google.maps.Map($('#map-canvas')[0], mapOptions)
    directionsRenderer.setMap(map)

    $('#start').blur calcRoute
    $('#end').blur calcRoute

calcRoute = ->
    start = $('#start').val()
    end = $('#end').val()
    request =
        origin:start,
        destination:end,
        travelMode: google.maps.TravelMode.DRIVING
    directionsService.route request, (result, status) ->
        if (status == google.maps.DirectionsStatus.OK)
            directionsRenderer.setDirections(result)
