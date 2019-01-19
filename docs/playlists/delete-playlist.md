# Deleting A Playlist
Wraps around [this](https://developer.spotify.com/documentation/web-api/reference/follow/unfollow-playlist/) Spotify API endpoint

### Note
It is not currently possible to delete a playlist entirely on Spotify, the best alternative is to unfollow it, which is the same as "deleting" a playlist through the web players or desktop app.

Because of this, this method just unfollows a playlist.
## How to use
After creating a `Spotify` object, and getting a playlist through either [`.Playlists.GetPlaylist()`](get-playlist.md) or creating a new playlist with [`.Playlists.CreatePlaylist()`](create.md), the `.Delete()` method of the playlist object can be called to "delete" the playlist.

## Example
This example will:

A) Create a `Spotify` object (which will prompt the user for authorization if it is not already done) 

B) Create a new [Playlist Object](playlist-object.md)

C) Add 5 tracks to the playlist, 3 copies of Ocean Man and two other songs

D) Wait for 10 seconds, then remove all copies of Ocean Man from the playlist

E) Wait 20 seconds, then delete the playlist
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
Sleep, 20000
NewPlaylist.Delete()
```