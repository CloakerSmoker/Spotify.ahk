# Getting Current Playback Info
Wraps around [this](https://developer.spotify.com/documentation/web-api/reference/player/get-information-about-the-users-current-playback/) Spotify API endpoint
## How to use
After creating a `Spotify` object, you can call `.Player.GetCurrentPlaybackInfo()`.

This will return a [Current Playback Info Object](current-info-object.md) which contains no methods, but various information about the users current playback.

## Example
This example will:

A) Create a `Spotify` object (which will prompt the user for authorization if it is not already done) 

B) Get a [Current Playback Info Object](current-info-object.md) with `.Player.GetCurrentPlaybackInfo()`

C) Show how many seconds into the song the player is, and the `name` property of the currently playing track
```
Spoofy := new Spotify()
CurrentPlayback := Spoofy.Player.GetCurrentPlaybackInfo()
MsgBox, % "You are currently " Ceil(CurrentPlayback.progress_ms / 1000) " seconds into the song """ CurrentPlayback.Track.Name """"
```