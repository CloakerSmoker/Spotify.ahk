# Adding Tracks To A Playlist
Wraps around [this](https://developer.spotify.com/documentation/web-api/reference/playlists/add-tracks-to-playlist/) Spotify API endpoint
## How to use
After creating a `Spotify` object, and getting a playlist through either [`.Playlists.GetPlaylist()`](get-playlist.md) or creating a new playlist with [`.Playlists.CreatePlaylist()`](create.md), the `.AddTrack()` method of the returned playlist object can be used. 

`.AddTrack()` expects one parameter, `TrackIDOrTrackOBJ` (Which can either be a [track ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids) or a [track object](../tracks/track-object.md)

## Example
This example will:

A) Create a `Spotify` object (which will prompt the user for authorization if it is not already done) 

B) Create a new (empty) playlist named `Test 123` with the description `This is an example playlist made by Spotify.ahk`

C) Add a track to the new playlist with `.AddTrack()` by the track's [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids)

D) Will try to play the new playlist on the active device
```
Spoofy := new Spotify()
NewPlaylist := Spoofy.Playlists.CreatePlaylist("Test 123", "This is an example playlist made by Spotify.ahk")
NewPlaylist.AddTrack("5ogtb9bGQoH8CjZNxmbNHR")
NewPlaylist.Play()
```