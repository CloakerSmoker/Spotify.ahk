#Include %A_ScriptDir%
#Include Spotify.ahk

Spotify.Auth()

VolumePercentage := Spotify.Player.GetCurrentPlaybackInfo().Device.Volume
ShuffleMode := 0
RepeatMode := 0
return

F1::
VolumePercentage--
Spotify.Player.SetVolume(VolumePercentage) ; Decrement the volume percentage and set the player to the new volume percentage
return

F2::
VolumePercentage++
Spotify.Player.SetVolume(VolumePercentage) ; Increment the volume percentage and set the player to the new volume percentage
return 

F3::
ShuffleMode := !ShuffleMode
Spotify.Player.SetShuffle(ShuffleMode) ; Swap the shuffle mode of the player
return 

F4::
NewMode := ["off", "context", "track"][Mod(++RepeatMode, 3) + 1]
Spotify.Player.SetRepeatMode(NewMode) ; Cycle through the three repeat modes (1-2, 2-3, 3-1)
return 
