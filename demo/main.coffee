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

        points = _.flatten(s.path for s in leg.steps)

        markers = _.map points, (point) ->
            new google.maps.Marker
                position: point
                map: map

        showImagesForPoints(points)
    )

    google.maps.event.addListener start, 'dragend', doRoute
    google.maps.event.addListener end, 'dragend', doRoute
    doRoute()

    IG.init
        client_id: 'bab6e1f1e6c4447c8702006a0c016c5d'
        check_status: true
        cookie: true


    window.IG_access_token = null
    IG.login(
        (response) ->
            window.IG_access_token = response.session.access_token
        scope: ['basic']
    )


window.handleIGSearch = (response) ->
    console.log(response)


showImagesForPoints = (points) ->
    imagesEl = $('#images')
    imagesEl.empty()

    for point, i in points

        # needs to be in a closure or else pointImagesEl will be
        # the one created during the last iteration of the loop.
        # TODO: understand this better.
        closure = ->
            pointImagesEl = $('<div>').addClass('.point-images')
            imagesEl.append(pointImagesEl)

            pointImagesEl.append($('<div>').text(point.$a + ' ' + point.ab))

            # warning: if the user changes points before all callbacks
            # are called, outstanding api calls will call the wrong
            # callbacks
            callbackName = 'handleIGSearch' + i

            console.log(callbackName)
            window[callbackName] = (response) ->
                for d in response.data
                    imURL = d.images.standard_resolution.url
                    imURL = d.images.low_resolution.url
                    imURL = d.images.thumbnail.url
                    pointImagesEl.append($('<img>').attr('src', imURL))
            $.ajax
                url: 'https://api.instagram.com/v1/media/search'
                data:
                    access_token: window.IG_access_token
                    callback: callbackName
                    lat: point.$a
                    lng: point.ab
                    distance: 10
                dataType: 'script'
        closure()


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
