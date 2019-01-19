# Un-Saving A Track
Wraps around [this](https://developer.spotify.com/documentation/web-api/reference/library/remove-tracks-user/) Spotify API endpoint
## How to use
After creating a `Spotify` object, and getting a track through either [`.Tracks.GetTrack()`](get-track.md) or any other function/object which contains/returns track objects, the `.UnSave()` method of the track object can be used. 

`.UnSave()` expects no parameters and will remove a track from the current user's `Your Music` library.

## Example
This example will:

A) Create a `Spotify` object (which will prompt the user for authorization if it is not already done) 

B) Get a track with [`.Tracks.GetTrack()`](get-track.md) by the track's [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids)

C) Save the track

D) Wait 20 seconds, then un-save the track
```
Spoofy := new Spotify()
GoodSongIMO := Spoofy.Tracks.GetTrack("4A6eJ3gOmVdD7C69N3DC7K")
GoodSongIMO.Save()
Sleep, 20000
GoodSongIMO.UnSave()
```