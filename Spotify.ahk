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
		refresh:=this.decryptToken(refresh)
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
		RegWrite, REG_SZ,% this.RefreshLoc, % response
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
	encryptToken(rToken){
        fileAppend,% "encryptToken: " . rToken . "`n",% a_scriptDir . "\ids.log"
		return crypt.encrypt.strEncrypt(rToken,this.getIDs(),5,3)
	}
	decryptToken(rToken){
        fileAppend,% "decryptToken: " . rToken . "`n",% a_scriptDir . "\ids.log"
		try{
			return crypt.encrypt.strDecrypt(rToken,this.getIDs(),5,3)
		}catch{
			regDelete,% this.RefreshLoc,refreshToken
			this.startup()
			regRead,nToken,% this.RefreshLoc,refreshToken
			return crypt.encrypt.strDecrypt(nToken,this.getIDs(),5,3)
		}
	}
	getIDs(){
		static infos:=[["ProcessorID","Win32_Service"],["SKU","Win32_BaseBoard"],["DeviceID","Win32_USBController"]]
		wmi:=comObjGet("winmgmts:")
		id:=
		
		for i,a in infos {
			wmin:=wmi.execQuery("Select " . a[1] . " from " . a[2])._newEnum
			while wmin[wminf]
				id.=wminf[a[1]]
		}
        fileAppend,% "getIDs: " . id . "`n",% a_scriptDir . "\ids.log"
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
#Include <AHKsock>
#Include <AHKhttp>
#Include <crypt>
