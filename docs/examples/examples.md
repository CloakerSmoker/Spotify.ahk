## Hotkeys to save/un-save the currently playing track
```
Spoofy := new Spotify()
F1::Spoofy.Player.SaveCurrentlyPlaying() ; Alias for .Player.GetCurrentPlaybackInfo().Track.Save()
F2::Spoofy.Player.UnSaveCurrentlyPlaying() ; Alias for .Player.GetCurrentPlaybackInfo().Track.UnSave()
```
## Hotkey to play a random album from the user's top artists
```
Spoofy := new Spotify()
TopArtists := Spoofy.CurrentUser.GetTop("artists") ; Returns an array of top artists
TopArtistsAlbums := TopArtists[1].GetAlbums() ; Returns an array of number 1 top artist's ablums
Random, rand, 1, % TopArtistsAlbums.Length() ; Gets a random number 1 - Artist's number of ablums
TopArtistsAlbums[rand].Play() ; Plays the random album
```