/*
Hotkeys examples for Spotify class
Source: https://github.com/CloakerSmoker/Spotify.ahk
Documentation (updated): https://cloakersmoker.github.io/Spotify.ahk/rewrite/index.html

This example edited by: Jean Lalonde (https://github.com/JnLlnd) 2022-08-19
*/

#requires AutoHotkey v1.1
#SingleInstance,Force

#Include %A_ScriptDir%\Spotify.ahk

spoofy := new Spotify
Increment := 5

PlaybackInfo := spoofy.Player.GetCurrentPlaybackInfo()
VolumePercentage := PlaybackInfo.Device.Volume
ShuffleMode := PlaybackInfo.shuffle_state
RepeatMode := (PlaybackInfo.repeat_state = "context" ? 2 : PlaybackInfo.repeat_state = "track" ? 1 : 3) ; 1 "track", 2 "context" (album, playlist, etc.), any other value "off"

return

F1::
if(VolumePercentage - Increment > 0)
  VolumePercentage := VolumePercentage - Increment
spoofy.Player.SetVolume(VolumePercentage) ; Decrement the volume percentage and set the player to the new volume percentage
return

F2::
if(VolumePercentage + Increment <= 100)
  VolumePercentage := VolumePercentage + Increment
spoofy.Player.SetVolume(VolumePercentage) ; Increment the volume percentage and set the player to the new volume percentage
return 

F3::
ShuffleMode := !ShuffleMode
spoofy.Player.SetShuffle(ShuffleMode) ; Swap the shuffle mode of the player
return 

F4::
RepeatMode := RepeatMode + (RepeatMode = 0 ? 1 : (RepeatMode = 1 ? 1 : (RepeatMode = 2 ? 1 : -2)))
spoofy.Player.SetRepeatMode(RepeatMode) ; Cycle through the three repeat modes (1-2, 2-3, 3-1)
return 

F5::
spoofy.Player.NextTrack()
return 

F6::
spoofy.Player.LastTrack()
return 

