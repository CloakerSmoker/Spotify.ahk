/*
Export example for Spotify class
Source: https://github.com/CloakerSmoker/Spotify.ahk
Documentation (updated): https://cloakersmoker.github.io/Spotify.ahk/rewrite/index.html
Edited: Jean Lalonde (https://www.QuickAccessPopup.com) 2022-08-19

ObjCSV class (to save data to CSV file)
Source: https://github.com/JnLlnd/ObjCSV
Documentation: http://code.jeanlalonde.ca/ahk/ObjCSV/ObjCSV-doc/

This example by: Jean Lalonde (https://github.com/JnLlnd) 2022-08-19
*/

#requires AutoHotkey v1.1
#SingleInstance,Force

#Include %A_ScriptDir%
#Include Spotify.ahk ; https://github.com/CloakerSmoker/Spotify.ahk
#Include ObjCSV.ahk ; https://github.com/JnLlnd/ObjCSV

global o_Spotify := new Spotify
global o_PlaylistOutput := Object()

GetPlaylist("37i9dQZF1EVHGWrwldPRtj", "Daily Mix 1")
GetPlaylist("6uplrDScAMCePauuh1hVOF", "MTL Jazz")

ToolTip, Saving to CSV file
ObjCSV_Collection2CSV(o_PlaylistOutput, A_ScriptDir . "\Playlists.csv", true, "Playlist;Artists;Album;Title;Seconds;ISRC;URL", , true, ";", , , , "UTF-8")
ToolTip

Run, % A_ScriptDir . "\Playlists.csv"

return


GetPlaylist(strPlaylistID, strPlaylistName)
{
	ToolTip, %strPlaylistName%
	o_PlaylistTracks := o_Spotify.Playlists.GetPlaylist(strPlaylistID).GetAllTracks()
	
	for intOrder, oTrack in o_PlaylistTracks
	{
		oNewTrack := Object()
		oNewTrack.Playlist := strPlaylistName
		oNewTrack.Title := oTrack.name
		for intArtistOrder, oArtist in oTrack.artists
			oNewTrack.Artists .= oArtist.name . ", "
		oNewTrack.Artists := SubStr(oNewTrack.Artiste, 1, -2)
		oNewTrack.Album := oTrack.album.name
		oNewTrack.ISRC := oTrack.json.external_ids.isrc
		oNewTrack.Seconds := Round(oTrack.json.duration_ms / 1000)
		oNewTrack.URL := oTrack.json.external_urls.spotify
		o_PlaylistOutput.Push(oNewTrack)
	}
	ToolTip
}
