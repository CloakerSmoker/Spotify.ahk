#MaxThreads 2
class Spotify {
	__New() {
		this.Util := new Util(this)
		this.Player := new Player(this)
		this.Library := new Library(this)
		this.Albums := new Albums(this)
		this.Artists := new Artists(this)
	}
}
class Util {
	__New(ParentObject) {
		this.ParentObject := ParentObject
		this.RefreshLoc := "HKCU\Software\SpotifyAHK"
		this.StartUp()
	}
	StartUp() {
		RegRead, refresh, % this.RefreshLoc, refreshToken
		if (refresh) {
			this.RefreshTempToken(refresh)
		} else {
			this.auth := ""
			paths := {}
			paths["/callback"] := this["authCallback"].bind(this)
			paths["404"] := this["NotFound"]
			server := new HttpServer()
			server.SetPaths(paths)
			server.Serve(8000)
			Run, % "https://accounts.spotify.com/en/authorize?client_id=9fe26296bb7b4330ac59339efd2742b0&response_type=code&redirect_uri=http:%2F%2Flocalhost:8000%2Fcallback&scope=user-modify-playback-state%20user-read-currently-playing%20user-read-playback-state%20user-library-modify%20user-library-read%20user-read-email%20user-read-private%20user-read-birthdate%20user-follow-read%20user-follow-modify%20playlist-read-private%20playlist-read-collaborative%20playlist-modify-public%20playlist-modify-private%20user-read-recently-played%20user-top-read"
			loop {
				Sleep, -1
			} until (this.WebAuthDone() = true)
			this.FetchTokens()
		}
	}
	
	; Timeout methods
	
	SetTimeout() {
		TimeOut := A_Now
		EnvAdd, TimeOut, 1, hours
		this.TimeOut := TimeOut
	}
	CheckTimeout() {
		if (this.TimeLastChecked = A_Min) {
			return
		}
		this.TimeLastChecked := A_Min
		if (A_Now > this.TimeOut) {
			RegRead, refresh, % this.RefreshLoc, refreshToken
			this.RefreshTempToken(refresh)
		}
	}
	
	; API token operations
	
	RefreshTempToken(refresh) {
		refresh := this.DecryptToken(refresh)
		arg := {1:{1:"Content-Type", 2:"application/x-www-form-urlencoded"}, 2:{1:"Authorization", 2:"Basic OWZlMjYyOTZiYjdiNDMzMGFjNTkzMzllZmQyNzQyYjA6ZWNhNjU2ZDFkNTczNDNhOTllMWJjNWVmODQ0YmY2NGM="}}
		response := this.CustomCall("POST", "https://accounts.spotify.com/api/token?grant_type=refresh_token&refresh_token=" . refresh, arg, true)
		this.authState := true
		if (InStr(response, "refresh_token")) {
			this.SaveRefreshToken(response)
		}
		RegexMatch(response, "access_token"":""\K.*?(?="")", token)
		this.token := token
		this.SetTimeout()
	}
	FetchTokens() {
		if (this.fail) {
			ErrorLevel := 1
			return
		}
		if (this.authState) {
			return
		}
		AHKsock_Close(-1)
		arg := {1:{1:"Content-Type", 2:"application/x-www-form-urlencoded"}, 2:{1:"Authorization", 2:"Basic OWZlMjYyOTZiYjdiNDMzMGFjNTkzMzllZmQyNzQyYjA6ZWNhNjU2ZDFkNTczNDNhOTllMWJjNWVmODQ0YmY2NGM="}}
		response := this.CustomCall("POST", "https://accounts.spotify.com/api/token?grant_type=authorization_code&code=" . this.auth . "&redirect_uri=http:%2F%2Flocalhost:8000%2Fcallback", arg, true)
		RegexMatch(response, "access_token"":""\K.*?(?="")", token)
		this.token := token
		this.SaveRefreshToken(response)
	}
	
	; Local token operations
	
	SaveRefreshToken(response) {
		RegexMatch(response, "refresh_token"":""\K.*?(?="")", response)
		if !(response) {
			return
		}
		response := this.encryptToken(response)
		RegWrite, REG_SZ, % this.RefreshLoc, RefreshToken, % response
		return
	}
	
	; API call method with auto-auth/timeout check/base URL
	
	CustomCall(method, url, HeaderArray := "", noTimeOut := false) {
		if !(noTimeOut) {
			this.CheckTimeout()
		}
		if !((InStr(url, "https://api.spotify.com")) || (InStr(url, "https://accounts.spotify.com/api/"))) {
			url := "https://api.spotify.com/v1/" . url
		}
		if !(HeaderArray) {
			HeaderArray :=  {1:{1:"Authorization", 2:"Bearer " . this.token}}
		}
		SpotifyWinHttp := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		SpotifyWinHttp.Open(method, url, false)
		for index, SubHeaderArray in HeaderArray {
			SpotifyWinHttp.SetRequestHeader(SubHeaderArray[1], SubHeaderArray[2])
		}
		SpotifyWinHttp.Send()
		return SpotifyWinHttp.ResponseText
	}
	
	; Web auth methods
	
	NotFound(ByRef req, ByRef res) {
		res.SetBodyText("Page not found")
	}
	authCallback(self, ByRef req, ByRef res) {
		res.SetBodyText( req.queries["error"] ? "Error, authorization not given, Spotify.ahk will not function correctly without authorization." : "Authorization complete, closing listen server.")
		res.status := 200
		this.auth := req.queries["code"]
		this.fail := req.queries["error"]
	}
	WebAuthDone() {
		return (this.auth ? true : false)
	}
	
	; Token encryption/decryption methods
	
	EncryptToken(RefreshToken) {
		return crypt.encrypt.strEncrypt(RefreshToken, this.GetIDs(), 5, 3)
	}
	DecryptToken(RefreshToken) {
		try {
			return crypt.encrypt.strDecrypt(RefreshToken, this.GetIDs(), 5, 3)
		} catch {
			RegDelete, % this.RefreshLoc, RefreshToken
			this.StartUp()
			RegRead, RefreshToken, % this.RefreshLoc, refreshToken
			return crypt.encrypt.strDecrypt(RefreshToken, this.GetIDs(), 5, 3)
		}
	}
	GetIDs() {
		static infos := [["ProcessorID", "Win32_Service"], ["SKU", "Win32_BaseBoard"], ["DeviceID", "Win32_USBController"]]
		wmi := ComObjGet("winmgmts:")
		id := ""
		for i, a in infos {
			wmin := wmi.execQuery("Select " . a[1] . " from " . a[2])._newEnum
			while wmin[wminf] {
				id .= wminf[a[1]]
			}
		}
		return id
	}
}
class Player {
	__New(ParentObject) {
		this.ParentObject := ParentObject
	}
	SetVolume(volume) {
		return this.ParentObject.Util.CustomCall("PUT", "me/player/volume?volume_percent=" . volume)
	}
	GetDeviceList() {
		return this.ParentObject.Util.CustomCall("GET", "me/player/devices")
	}
	GetCurrentPlaybackInfo() {
		return this.ParentObject.Util.CustomCall("GET", "me/player")
	}
	GetRecentlyPlayed() {
		return this.ParentObject.Util.CustomCall("GET", "me/player/recently-played")
	}
	PausePlayback() {
		return this.ParentObject.Util.CustomCall("POST", "me/player/pause")
	}
	SeekTime(TimeInMS) {
		return this.ParentObject.Util.CustomCall("PUT", "me/player/seek?position_ms=" . TimeInMS)
	}
	SetRepeatMode(mode) {
		return this.ParentObject.Util.CustomCall("PUT", "me/player/repeat?state=" . (mode = 1 ? "track" : (mode = 2 ? "context" : "off")))
	}
	NextTrack() {
		return this.ParentObject.Util.CustomCall("POST", "me/player/next")
	}
	LastTrack() {
		return this.ParentObject.Util.CustomCall("POST", "me/player/previous")
	}
	ChangeContext(ContextURI) {
		return this.ParentObject.Util.CustomCall("PUT", "me/player/play?{""context_uri"": """ . ContextURI . """}")
	}
	SetContextToTrackArray(TrackArray) {
		return this.ParentObject.Util.CustomCall("PUT", "me/player/play?{""uris"": [" . TrackArray . "]}")
	}
	ResumePlayback() {
		return this.ParentObject.Util.CustomCall("PUT", "me/player/play")
	}
	SetShuffle(mode) {
		return this.ParentObject.Util.CustomCall("PUT", "me/player/shuffle?state=" . (mode ? "true" : "false"))
	}	
}
class Library {
	__New(ParentObject) {
		this.ParentObject := ParentObject
	}
	CheckSavedForAlbum(AlbumID) {
		return this.ParentObject.Util.CustomCall("GET", "me/albums/contains?ids=" . AlbumID)
	}
	CheckSavedForTrack(TrackID) {
		return this.ParentObject.Util.CustomCall("GET", "me/tracks/contains?ids=" . TrackID)
	}
	GetSavedAlbums(NumberOfAlbums, offset) {
		return this.ParentObject.Util.CustomCall("GET", "me/albums?limit=" . NumberOfAlbums . "&offset=" . offset)
	}
	GetSavedTracks(NumberOfTracks, offset) {
		return this.ParentObject.Util.CustomCall("GET", "me/tracks?limit=" . NumberOfTracks . "&offset=" . offset)
	}
	RemoveSavedAlbum(IDList) {
		return this.ParentObject.Util.CustomCall("DELETE", "me/albums?ids=" . IDList)
	}
	RemoveSavedTrack(IDList) {
		return this.ParentObject.Util.CustomCall("DELETE", "me/tracks?ids=" . IDList)
	}
	SaveNewAlbum(AlbumID) {
		return this.ParentObject.Util.CustomCall("PUT", "me/albums?ids=" . AlbumID)
	}
	SaveNewTrack(TrackID) {
		return this.ParentObject.Util.CustomCall("PUT", "me/tracks?ids=" . TrackID)
	}
}
class Albums {
	__New(ParentObject) {
		this.ParentObject := ParentObject
	}
	GetAlbum(AlbumID) {
		return this.ParentObject.Util.CustomCall("GET", "albums/" . AlbumID)
	}
	GetTracksFromAlbum(AlbumID) {
		return this.ParentObject.Util.CustomCall("GET", "albums/" . AlbumID . "/tracks")
	}
}
class Artists {
	__New(ParentObject) {
		this.ParentObject := ParentObject
	}
	GetArtist(ArtistID) {
		return this.ParentObject.Util.CustomCall("GET", "artists/" . ArtistID)
	}
	GetArtistAlbums(ArtistID) {
		return this.ParentObject.Util.CustomCall("GET", "artists/" . ArtistID . "/albums")
	}
	GetRelatedArtists(ArtistID) {
		return this.ParentObject.Util.CustomCall("GET", "artists/" . ArtistID . "/related-artists")
	}
	GetArtistTopTracks(ArtistID) {
		return this.ParentObject.Util.CustomCall("GET", "artists/" . ArtistID . "/top-tracks")
	}
}
class Tracks {
	__New(ParentObject) {
		this.ParentObject := ParentObject
	}
	GetAudioFeatures(TrackID) {
		return this.ParentObject.Util.CustomCall("GET", "audio-features/" . TrackID)
	}
	GetTrack(TrackID) {
		return this.ParentObject.Util.CustomCall("GET", "tracks/" . TrackID)
	}
}
#Include <AHKsock>
#Include <AHKhttp>
#Include <crypt>