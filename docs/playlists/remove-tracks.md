# Removing Tracks From A Playlist
Wraps around [this](https://developer.spotify.com/documentation/web-api/referenceremove-tracks.md-playlist/) Spotify API endpoint
## How to use
After creating a `Spotify` object, and getting a playlist through either [`.Playlists.GetPlaylist()`](get-playlist.md) or creating a new playlist with [`.Playlists.CreatePlaylist()`](create.md) (And adding tracks to the playlist), the `.RemoveTrack()` method of the returned playlist object can be used. 

`.RemoveTrack()` expects one parameter, `TrackIDOrTrackOBJ` (Which can either be a [track ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids) or a [track object](../tracks/track-object.md) and removes all instances of the track from the playlist

## Example
This example will:

A) Create a `Spotify` object (which will prompt the user for authorization if it is not already done) 

B) Create a new [Playlist Object](playlist-object.md)

C) Add 5 tracks to the playlist, 3 copies of Ocean Man and two other songs

D) Wait for 5 seconds, then remove all copies of Ocean Man from the playlist
```
Spoofy := new Spotify()
NewPlaylist := Spoofy.Playlists.CreatePlaylist("Test 1234", "This is a Spotify.ahk test playlist")
NewPlaylist.AddTrack("5ogtb9bGQoH8CjZNxmbNHR")
NewPlaylist.AddTrack("2yYSMsrFJ6m7ePtLxQZZBF")
loop, 3 {
	NewPlaylist.AddTrack("6M14BiCN00nOsba4JaYsHW")
}
Sleep, 10000
NewPlaylist.RemoveTrack("6M14BiCN00nOsba4JaYsHW")
```