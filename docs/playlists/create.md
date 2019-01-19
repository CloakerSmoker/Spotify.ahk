# Creating A Playlist
Wraps around [this](https://developer.spotify.com/documentation/web-api/referencecreate.md-playlist/) Spotify API endpoint
## How to use
After creating a `Spotify` object, call `.Playlists.CreatePlaylist()`, which expects two parameters, `name` (this name you want the new playlist to have) and `description` (the description you want the new playlist to have)

This will return a [playlist object](playlist-object.md) owned by the user that authorized Spotify.ahk which can then be used to [add tracks](add-tracks.md) to the playlist you created.

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