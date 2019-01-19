# Getting A Track By ID
Wraps around [this](https://developer.spotify.com/documentation/web-api/reference/tracks/get-track/) Spotify API endpoint
## How to use
After creating a `Spotify` object, you can use `.Track.GetTrack()` to get a track by its [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids).

This will return a [Track Object](track-object.md) which can then be used for the methods outlined on [this](track-object.md) page.

## Example
This example will:

A) Create a `Spotify` object (which will prompt the user for authorization if it is not already done) 

B) Get a track with `.Tracks.GetTrack()` by the track's [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids)

C) Save the track
```
Spoofy := new Spotify()
GoodSongIMO := Spoofy.Tracks.GetTrack("4A6eJ3gOmVdD7C69N3DC7K")
GoodSongIMO.Save()
```