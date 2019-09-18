#include %A_ScriptDir%
#include Spotify.ahk
#MaxThreads 2

; A nice little OSD that displays some info about the currently playing track, and offers a way to control volume/favorite songs
; Hold F9 to open the OSD, and it will show a volume slider that can be changed by holding right mouse and moving the mouse
;   up/down
;  Holding right mouse button will slid the bottom bar between "None", "Favorite" and "Unfavorite"
;    None = Do nothing
;    Favorite = Favorite the displayed song
;    Unfavorite = Unfavorite the song
;   The second two do not check if the song is favorited or not first, so be careful with them
;  The album cover of the track will also be downloaded and shown (stored in %Temp%\%AlbumName%.jpg)

Spotify.Auth()

Gui, OSD:New, HwndOSDHwnd +LastFound +AlwaysOnTop -Caption +ToolWindow
Gui, OSD:Color, FF0088
Gui, OSD:Font, q3
Gui, OSD:Add, Text, w200 h30 C999999 Background333333 HwndSongHwnd
Gui, OSD:Add, Progress, C999999 Background333333 Vertical w30 h100 Range0-100 HwndVolumeProgress section, 100
Gui, OSD:Add, Picture, w100 h100 xs+40 ys HwndPicHwnd
Gui, OSD:Add, Text, w200 h30 C999999 Background333333 HwndFavText xs ys+110, None          Favorite           Unfavorite
Gui, OSD:Add, Progress, C999999 Background333333 w65 h10 Range0-5 HwndFavProg xs ys+130, 5
WinSet, TransColor, FF0088 150
LastPic := ""
return

#if WinActive("ahk_id " OSDHwnd)
LButton::LButton := true
LButton Up::LButton := false
RButton::RButton := true
RButton Up::RButton := false
#If

F9::
	if (Running) {
		return
	}
	Running := true
	
	;SoundGetWaveVolume, Vol
	Info := Spotify.Player.GetFullPlaybackInfo()
	;
	
	if !(FileExist(Temp "\" Info.Track.Album.Name ".jpg")) {
		IsDone := False
		Fn := Func("DownloadToFile").Bind(Info.Track.Album.Images[1].URL, Temp "\" Info.Track.Album.Name ".jpg", IsDone)
		SetTimer, % Fn, -500
	}
	
	GuiControl,, % VolumeProgress, % Info.Device.Volume
	GuiControl,, % SongHwnd, % Info.Track.Name "`n" Info.Track.Artists[1].Name
	GuiControl, Move, % FavProg, % "x0"

	if (LastPic != Info.Track.Album.Name) {
		GuiControl,, % PicHwnd, % "*w100 *h100"
		ShowingImage := false
	}
	else {
		ShowingImage := true
	}
	
	Gui, OSD:Show
	
	Delta := Info.Device.Volume
	CoordMode, Mouse, Screen
	
	MouseGetPos, InitialX, InitialY
	
	while (GetKeyState("F9")) {
		if (!ShowingImage && FileExist(Temp "\" Info.Track.Album.Name ".jpg")) {
			GuiControl,, % PicHwnd, % "*w100 *h100 " Temp "\" Info.Track.Album.Name ".jpg"
			LastPic := Info.Track.Album.Name
			ShowingImage := true
		}
		
		MouseGetPos, MouseX, MouseY
	
		if (LButton) {
			DeltaX := 0 - (InitialX - MouseX)
			
			if (DeltaX < 0) {
				DeltaX := 0
			}
			else if (DeltaX > 120) {
				DeltaX := 120
			}
			
			GuiControl, Move, % FavProg, % "x" DeltaX
			;ToolTip, % DeltaX
		}
		else if (RButton) {
			Delta := InitialY - MouseY + Info.Device.Volume
			GuiControl,, % VolumeProgress, % Delta
		}
		
		Sleep, 50
	}
	
	Spotify.Player.SetVolume(Delta)
	
	if (DeltaX != 0 && DeltaX > 40) {
		if (DeltaX < 80) {
			Spotify.Player.SaveCurrentlyPlaying()
		}
		else if (DeltaX > 80) {
			Spotify.Player.UnSaveCurrentlyPlaying()
		}
	}
	
	Gui, OSD:Hide
	Running := false
return

DownloadToFile(URL, File, ByRef IsDone) {
	UrlDownloadToFile, % URL, % File
	IsDone := true
}