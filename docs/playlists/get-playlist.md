# Getting A Playlist By ID
Wraps around [this](https://developer.spotify.com/documentation/web-api/referenceget-playlist.md/) Spotify API endpoint
## How to use
After creating a `Spotify` object, you can use `.Playlists.GetPlaylist()` to get a playlist by its [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids).

This will return a [Playlist Object](playlist-object.md) which can then be played/edited by the methods outlined on [this](playlist-object.md) page.

## Example
This example will:

A) Create a `Spotify` object (which will prompt the user for authorization if it is not already done) 

B) Get the playlist `Epic Gamer Music` by `Enrique Triana` 

C) Try to play `Epic Gamer Music` on the active device
```
Spoofy := new Spotify()
EpicGamerMusic := Spoofy.Playlists.GetPlaylist("2PJPSL6yYJA3ygxr5hADPw")
EpicGamerMusic.Play()
```