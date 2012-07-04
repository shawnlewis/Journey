EARTH_CIRCUMFERENCE = 400751600   # meters

metersInEarthDegrees = (meters) ->
    360.0 * meters / EARTH_CIRCUMFERENCE

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
    $('input[name=provider]').change doRoute
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

# Returns a comma separated string of 4 values as expected by the flickr
# search API.
# "The 4 values represent the bottom-left corner of the box and the
#  top-right corner, minimum_longitude, minimum_latitude,
#  maximum_longitude, maximum_latitude."
boundingBox = (centerLatLng, distance) ->
    dist = metersInEarthDegrees(distance)
    return (centerLatLng.ab - dist) +
        ',' + (centerLatLng.$a - dist) +
        ',' + (centerLatLng.ab + dist) +
        ',' + (centerLatLng.$a + dist)

# Returns the name of a function that can be called once, after which it
# will be deleted. The name is always unique.
#
# This is useful for jsonp request which can only call a callback that's
# in the global scope (attached to window) by name. Each request can have
# its own unique callback passed in as a function rather than by name.
oneOffID = 0
oneOffFunction = (callback) ->
    name = 'oneOffFunction' + oneOffID
    oneOffID += 1
    window[name] = (args...) ->
        callback(args...)
        delete window[name]
    return name

flickrSearch = (options) ->
    callback = options.onResponse
    delete options['onResponse']

    options.api_key = '785f5248cb4ab12cf982c1600887864d'
    options.format = 'json'
    options.jsoncallback = oneOffFunction(callback)

    # Tells flickr to return a small thumbnail url. We could construct
    # URLs for each size from the response instead.
    options.extras = 'url_s'

    $.ajax
        url: 'http://api.flickr.com/services/rest/?method=flickr.photos.search'
        data: options
        dataType: 'jsonp'

instagramSearch = (options) ->
    callback = options.onResponse
    delete options['onResponse']

    options.access_token = window.IG_access_token
    options.callback = oneOffFunction(callback)

    $.ajax
        url: 'https://api.instagram.com/v1/media/search'
        data: options
        dataType: 'script'


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

            if $('input[name=provider]:checked').val() == 'Instagram'
                instagramSearch
                    lat: point.$a
                    lng: point.ab
                    distance: 10
                    onResponse: (response) ->
                        for d in response.data
                            imURL = d.images.thumbnail.url
                            pointImagesEl.append($('<img>').attr('src', imURL))
            else
                flickrSearch
                    bbox: boundingBox(point, 20)
                    min_taken_date: '2010-01-01'
                    onResponse: (response) ->
                        for photo in response.photos.photo
                            pointImagesEl.append($('<img>').attr('src', photo.url_s))


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
