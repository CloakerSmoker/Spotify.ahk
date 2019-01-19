# Playing A Playlist
Wraps around [this](https://developer.spotify.com/documentation/web-api/reference/player/start-a-users-playback/) Spotify API endpoint
## Warning
##### ** This method requires Spotify Premium, and will NOT work without Spotify Premium (see [here](https://developer.spotify.com/documentation/web-api/reference/player/start-a-users-playback/#response-format))**
### Note
This method does not match up with the API endpoint exactly, instead the ID of the playlist is used to build a [Context Object](/contexts/context-obj) which is then played

If an active device is not found, an error about the response status code not being 2xx will be thrown.
## How to use
After creating a `Spotify` object, and getting a playlist through either [`.Playlists.GetPlaylist()`](get-playlist.md) or creating a new playlist with [`.Playlists.CreatePlaylist()`](create.md) (And adding tracks to the playlist), the `.Play()` method of the returned playlist object can be used. 

`.Play()` will start playing the playlist on the active device.

## Example
This example will:

A) Create a `Spotify` object (which will prompt the user for authorization if it is not already done) 

B) Create a new (empty) playlist named `Test 123` with the description `This is an example playlist made by Spotify.ahk`

C) Add a track to the new playlist with [`.AddTrack()`](add-tracks.md) by the track's [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids)

D) Will try to play the new playlist on the active device
```
Spoofy := new Spotify()
NewPlaylist := Spoofy.Playlists.CreatePlaylist("Test 123", "This is an example playlist made by Spotify.ahk")
NewPlaylist.AddTrack("5ogtb9bGQoH8CjZNxmbNHR")
NewPlaylist.Play()
```