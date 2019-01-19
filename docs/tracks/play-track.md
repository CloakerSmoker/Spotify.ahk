# Playing A Track
Wraps around [this](https://developer.spotify.com/documentation/web-api/reference/player/start-a-users-playback/) Spotify API endpoint
## Warning
##### ** This method requires Spotify Premium, and will NOT work without Spotify Premium (see [here](https://developer.spotify.com/documentation/web-api/reference/player/start-a-users-playback/#response-format))**
### Note
This method does not match up with the API endpoint exactly, instead the ID of the track is used to build a [Context Object](/contexts/context-obj) which is then played

If an active device is not found, an error about the response status code not being 2xx will be thrown.
## How to use
After creating a `Spotify` object, and getting a track through either [`.Tracks.GetTrack()`](get-track.md) or any other function/object which contains/returns track objects, the `.Play()` method of the returned track object can be used. 

`.Play()` will start playing the track on the active device.

## Example
This example will:

A) Create a `Spotify` object (which will prompt the user for authorization if it is not already done) 

B) Get a track with [`.Tracks.GetTrack()`](get-track.md) by the track's [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids)

C) Play the track
```
Spoofy := new Spotify()
GoodSongIMO := Spoofy.Tracks.GetTrack("4A6eJ3gOmVdD7C69N3DC7K")
GoodSongIMO.Play()
```