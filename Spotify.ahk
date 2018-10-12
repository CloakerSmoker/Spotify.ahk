#MaxThreads 2
class Spotify {
	__New() {
		this.Util := new Util(this)
		this.Player := new Player(this)
		this.Library := new Library(this)
		this.Albums := new Albums(this)
		this.Artists := new Artists(this)
	}
	class SimpleArtistObject {
		__New(response) {
			RegexMatch(response, "https:\/\/o.*?""", ExternalURL)
			this.ExternalURL := SubStr(ExternalURL, 1, (StrLen(ExternalURL) - 1))
			RegexMatch(response, "me"" : "".*?"",\n", Name)
			this.Name := SubStr(Name, 8, (StrLen(Name) - 10))
			RegexMatch(this.ExternalURL, "[0-9a-zA-Z]{22}", ID)
			this.ID := ID
		}
	}
	class FullArtistObject {
		__New(response) {
			RegexMatch(response, "https:\/\/o.*?""", ExternalURL)
			this.ExternalURL := SubStr(ExternalURL, 1, (StrLen(ExternalURL) - 1))
			RegexMatch(response, "me"" : "".*?"",\n", Name)
			this.Name := SubStr(Name, 8, (StrLen(Name) - 10))
			RegexMatch(this.ExternalURL, "[0-9a-zA-Z]{22}", ID)
			this.ID := ID
			RegexMatch(response, """total"" : [0-9]*", Followers)
			this.Followers := SubStr(Followers, 10)
			RegexMatch(response, "s"" : \[.*? ]", Genres)
			this.Genres := StrSplit(SubStr(Genres, 7) , ",", "[ ""]")
		}
	}
}
class Util {
	__New(ParentObject) {
		this.ParentObject:=ParentObject
		this.RefreshLoc:="HKCU\Software\SpotifyAHK"
		this.StartUp()
	}
	StartUp() {
		RegRead, refresh,% this.RefreshLoc, refreshToken
		if (refresh) {
			this.RefreshAuth(refresh)
		}
		else {
			this.auth := ""
			paths := {}
			paths["/callback"] := this["authCallback"].bind(this)
			paths["404"] := this["NotFound"]
			server := new HttpServer()
			server.SetPaths(paths)
			server.Serve(8000)
			Run, % "https://accounts.spotify.com/en/authorize?client_id=9fe26296bb7b4330ac59339efd2742b0&response_type=code&redirect_uri=http:%2F%2Flocalhost:8000%2Fcallback&scope=user-modify-playback-state"
			loop {
				Sleep, -1
			} until (this.InternalIsReady() = true)
			this.GetTokens()
		}
	}
	SetTimeout(response) {
		RegexMatch(response, "[0-9]{4}", timeout)
		this.timeout := A_Hour + ((timeout / 60) / 60)
	}
	CheckTimeout() {
		if (A_Hour = this.timeout) {
			RegRead, refresh,% this.RefreshLoc, refreshToken
			this.RefreshAuth(refresh)
		}
	}
	RefreshAuth(refresh) {
		refresh := this.DecryptToken(refresh)
		arg := {1:{1:"Content-Type", 2:"application/x-www-form-urlencoded"}, 2:{1:"Authorization", 2:"Basic OWZlMjYyOTZiYjdiNDMzMGFjNTkzMzllZmQyNzQyYjA6ZWNhNjU2ZDFkNTczNDNhOTllMWJjNWVmODQ0YmY2NGM="}}
		response := this.CustomCall("POST", "https://accounts.spotify.com/api/token?grant_type=refresh_token&refresh_token=" . refresh, arg)
		this.authState := true
		if (InStr(response, "refresh_token")) {
			this.SaveRefresh(response)
		}
		RegexMatch(response, "s_token"":"".*?""", token)
		this.token := this.TrimToken(token)
		this.SetTimeout(response)
	}
	GetTokens() {
		if (this.fail) {
			ErrorLevel := 1
			return
		}
		if (this.authState) {
			return
		}
		AHKsock_Close(-1)
		arg := {1:{1:"Content-Type", 2:"application/x-www-form-urlencoded"}, 2:{1:"Authorization", 2:"Basic OWZlMjYyOTZiYjdiNDMzMGFjNTkzMzllZmQyNzQyYjA6ZWNhNjU2ZDFkNTczNDNhOTllMWJjNWVmODQ0YmY2NGM="}}
		response := this.CustomCall("POST", "https://accounts.spotify.com/api/token?grant_type=authorization_code&code=" . this.auth . "&redirect_uri=http:%2F%2Flocalhost:8000%2Fcallback", arg)
		RegexMatch(response, "s_token"":"".*?""", token)
		this.token := this.TrimToken(token)
		this.SaveRefresh(response)
	}
	SaveRefresh(response) {
		RegexMatch(response, "h_token"":"".*?""", response)
		if !(response) {
			return
		}
		response:=this.encryptToken(this.TrimToken(response))
		RegWrite, REG_SZ, % this.RefreshLoc, RefreshToken, % response
		return
	}
	TrimToken(token) {
		StringTrimLeft, token, token, 10
		StringTrimRight, token, token, 1
		return token
	}
	IsReady() {
		if (this.token != "") {
			return true
		}
		else {
			return false
		}
	}
	InternalIsReady() {
		if (this.auth != "") {
			return true
		}
		else {
			return false
		}
	}
	CustomCall(method, url, HeaderArray := "") {
		this.CheckTimeout()
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
	NotFound(ByRef req, ByRef res) {
		res.SetBodyText("Page not found")
	}
	authCallback(self, ByRef req, ByRef res) {
		res.SetBodyText( req.queries["error"] ? "Error, authorization not given, Spotify.ahk will not function correctly without authorization." : "Authorization complete, closing listen server.")
		res.status := 200
		this.auth := req.queries["code"]
		this.fail := req.queries["error"]
	}
	EncryptToken(RefreshToken){
		return crypt.encrypt.strEncrypt(RefreshToken, this.GetIDs(), 5, 3)
	}
	DecryptToken(RefreshToken){
		try{
			return crypt.encrypt.strDecrypt(RefreshToken, this.GetIDs(), 5, 3)
		} catch {
			regDelete, % this.RefreshLoc, RefreshToken
			this.startup()
			regRead, RefreshToken, % this.RefreshLoc, refreshToken
			return crypt.encrypt.strDecrypt(RefreshToken, this.GetIDs(), 5, 3)
		}
	}
	GetIDs(){
		static infos := [["ProcessorID", "Win32_Service"], ["SKU", "Win32_BaseBoard"], ["DeviceID", "Win32_USBController"]]
		wmi := ComObjGet("winmgmts:")
		id := ""
		for i, a in infos {
			wmin:=wmi.execQuery("Select " . a[1] . " from " . a[2])._newEnum
			while wmin[wminf]
				id .= wminf[a[1]]
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
		return new this.ParentObject.FullArtistObject(this.ParentObject.Util.CustomCall("GET", "artists/" . ArtistID))
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
#Include <AHKsock>
#Include <AHKhttp>
#Include <crypt>