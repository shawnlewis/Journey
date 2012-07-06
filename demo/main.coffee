##### Constants

EARTH_CIRCUMFERENCE = 400751600   # meters

MAP_OPTIONS =
    center: new google.maps.LatLng(-34.397, 150.644)
    zoom: 8
    mapTypeId: google.maps.MapTypeId.ROADMAP


##### Utilities

metersInEarthDegrees = (meters) ->
    360.0 * meters / EARTH_CIRCUMFERENCE

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

logLatLng = (address) ->
    geocoder.geocode {'address': address}, (results, status) ->
        if status == google.maps.GeocoderStatus.OK
            console.log(results[0].geometry.location)
        else
            alert 'Geocode failed: ' + status

googleGetRoute = (start, end, onSuccess) ->
    request =
        origin:start,
        destination:end,
        travelMode: google.maps.TravelMode.DRIVING
    directionsService.route request, (result, status) ->
        if (status == google.maps.DirectionsStatus.OK)
            onSuccess(result)
        else
            alert 'Route failed: ' + status


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


class Instagram
    CLIENT_ID: 'bab6e1f1e6c4447c8702006a0c016c5d'

    constructor: ->
        @accessToken = null

    init: ->
        IG.init
            client_id: @CLIENT_ID
            check_status: true
            cookie: true

        IG.login(
            (response) =>
                @accessToken = response.session.access_token
            scope: ['basic']
        )

    search: (options) ->
        callback = options.onResponse
        delete options['onResponse']

        options.access_token = @accessToken
        options.callback = oneOffFunction(callback)

        $.ajax
            url: 'https://api.instagram.com/v1/media/search'
            data: options
            dataType: 'script'

FLICKR_ROOT_URL = 'http://api.flickr.com/services/rest/?method='

class Flickr
    API_KEY: '785f5248cb4ab12cf982c1600887864d'
    SEARCH_URL: FLICKR_ROOT_URL + 'flickr.photos.search'

    search: (options) ->
        #console.log(@SEARCH_URL)
        callback = options.onResponse
        delete options['onResponse']

        options.api_key = @API_KEY
        options.format = 'json'
        options.jsoncallback = oneOffFunction(callback)

        # Tells flickr to return a small thumbnail url. We could construct
        # URLs for each size from the response instead.
        options.extras = 'url_s'

        $.ajax
            url: @SEARCH_URL
            data: options
            dataType: 'jsonp'


##### Services

directionsRenderer = new google.maps.DirectionsRenderer()
directionsService = new google.maps.DirectionsService()
geocoder = new google.maps.Geocoder()
flickr = new Flickr()
instagram = new Instagram()


##### App state

# 675 Dolores
start = new google.maps.Marker
    position: new google.maps.LatLng(37.7585989, -122.425413)
    title: "Start"
    draggable: true

# 16th and Mission
end = new google.maps.Marker
    position: new google.maps.LatLng(37.7650501, -122.4196959)
    title: "End"
    draggable: true

map = null

# holds the current image markers
markers = []

##### Functions that interact with state

updateRoute = ->
    googleGetRoute(start.position, end.position, (result) ->
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
                instagram.search
                    lat: point.$a
                    lng: point.ab
                    distance: 10
                    onResponse: (response) ->
                        for d in response.data
                            imURL = d.images.thumbnail.url
                            pointImagesEl.append($('<img>').attr('src', imURL))
            else
                flickr.search
                    bbox: boundingBox(point, 20)
                    min_taken_date: '2010-01-01'
                    onResponse: (response) ->
                        for photo in response.photos.photo
                            pointImagesEl.append($('<img>').attr('src', photo.url_s))


        closure()

# Runs on page ready
$ ->
    instagram.init()

    $('input[name=provider][value=Flickr]').prop('checked', true)

    map = new google.maps.Map($('#map-canvas')[0], MAP_OPTIONS)
    directionsRenderer.setMap(map)
    start.setMap(map)
    end.setMap(map)

    google.maps.event.addListener start, 'dragend', updateRoute
    google.maps.event.addListener end, 'dragend', updateRoute
    $('input[name=provider]').change updateRoute
    updateRoute()
