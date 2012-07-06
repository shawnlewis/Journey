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
    return (centerLatLng.lng - dist) +
        ',' + (centerLatLng.lat - dist) +
        ',' + (centerLatLng.lng + dist) +
        ',' + (centerLatLng.lat + dist)

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

googLatLng2LatLng = (ll) -> {'lat': ll.lat(), 'lng': ll.lng()}
instagramLatLng2LatLng = (ll) -> {'lat': ll.latitude, 'lng': ll.longitude}
flickrLatLng2LatLng = (ll) -> {'lat': ll.latitude, 'lng': ll.longitude}

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

    # Implements the same interface as the Flick class
    routeSearch: (points, onImage) ->
        for point in points
            instagram.search
                lat: point.lat
                lng: point.lng
                distance: 10
                onResponse: (response) ->
                    for d in response.data
                        onImage
                            thumbURL: d.images.thumbnail.url
                            location: instagramLatLng2LatLng(d.location)


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

        $.ajax
            url: @SEARCH_URL
            data: options
            dataType: 'jsonp'

    # Implements the same interface as the Instagram class
    routeSearch: (points, onImage) ->
        for point in points
            flickr.search
                bbox: boundingBox(point, 20)
                min_taken_date: '2010-01-01'
                extras: 'url_s,geo'
                onResponse: (response) ->
                    for photo in response.photos.photo
                        onImage
                            thumbURL: photo.url_s
                            location: flickrLatLng2LatLng(photo)


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

        points = _.map(_.flatten(s.path for s in leg.steps),
                       googLatLng2LatLng)

        showImagesForPoints(points)
    )

showImagesForPoints = (points) ->
    provider = instagram
    if $('input[name=provider]:checked').val() == 'Flickr'
        provider = flickr

    imagesEl = $('#images')
    imagesEl.empty()
    provider.routeSearch points, (photo) ->
        imagesEl.append($('<img>').attr('src', photo.thumbURL))
        loc = photo.location
        markers.push new google.maps.Marker
            position: new google.maps.LatLng(loc.lat, loc.lng)
            map: map


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
