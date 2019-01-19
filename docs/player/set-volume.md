# Setting Playback Volume
Wraps around [this](https://developer.spotify.com/documentation/web-api/reference/player/set-volume-for-users-playback/) Spotify API endpoint
## Warning
##### ** This method requires Spotify Premium, and will NOT work without Spotify Premium (see [here](https://developer.spotify.com/documentation/web-api/reference/player/set-volume-for-users-playback/#response-format))**
## Note
The API endpoint called by this method is in beta, and might not work perfectly
### How To Use
After creating a `Spotify` object, the `.Player.SetVolume()` method can be used. 

`.Player.SetVolume()` expects one parameter, `volume` (A number 0-100 representing the volume percentage you want) and will try to set the playback volume on the currently active device to the passed percentage

### Example
This example will:

A) Create a `Spotify` object (which will prompt the user for authorization if it is not already done) 

B) Call [`.Player.GetCurrentPlaybackInfo()`](player-current-info.md) and store the current volume percent

C) Increment the current volume percentage by 10

D) Set the volume percentage to the new percentage

```
Spoofy := new Spotify()
CurrentVolume := Spoofy.Player.GetCurrentPlaybackInfo().progress_ms
CurrentVolume += 10
Spoofy.Player.SetVolume(CurrentVolume)
```