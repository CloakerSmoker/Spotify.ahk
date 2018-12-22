#MaxThreads 2
class Spotify {
	__New() {
		this.Util := new Util(this)
		this.Player := new Player(this)
		this.Library := new Library(this)
		this.Albums := new Albums(this)
		this.Artists := new Artists(this)
		this.Tracks := new Tracks(this)
	}
}
class Util {
	__New(ByRef ParentObject) {
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
	
	CustomCall(method, url, HeaderArray := "", noTimeOut := false, body := "") {
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
		
		SpotifyWinHttp.Send(body)
		
		if (SpotifyWinHttp.Status > 299) {
			throw {message: SpotifyWinHttp.Status, what: "HTTP response code not 2xx", file: A_LineFile, line: A_LineNumber}
		}
		
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
	__New(ByRef ParentObject) {
		this.ParentObject := ParentObject
	}
	SaveCurrentlyPlaying() {
		/*
		* Gets the currently playing track, then tells it to save itself (10/10 OOP, I know)
		* Requires something to be playing
		* returns the text response from the API, which is empty unless there is an error
		*/
		return this.GetCurrentPlaybackInfo().track.Save()
	}
	UnSaveCurrentlyPlaying() {
		/*
		* Gets the currently playing track, then tells it to unsave itself
		* Requires something to be playing
		* returns the text response from the API, which is empty unless there is an error
		*/
		return this.GetCurrentPlaybackInfo().track.UnSave()
	}
	SetVolume(volume) {
		return this.ParentObject.Util.CustomCall("PUT", "me/player/volume?volume_percent=" . volume)
	}
	GetCurrentPlaybackInfo() {
		Resp := JSON.load(this.ParentObject.Util.CustomCall("GET", "me/player"))
		Resp.Track := new track(Resp["item"], this.ParentObject)
		Resp.Device := new device(Resp["device"], this.ParentObject)
		Resp.Context := new context(Resp["context"], this.ParentObject)
		return Resp
	}
	ChangeContext(ContextURI) {
		return this.ParentObject.Util.CustomCall("PUT", "me/player/play",, false, JSON.Dump({"context_uri": ContextURI}))
	}
	
	GetDeviceList() {
		Resp := JSON.Load(this.ParentObject.Util.CustomCall("GET", "me/player/devices"))
		RetVar := []
		for k, v in Resp["devices"] {
			RetVar.Push(new device(v, this.ParentObject))
		}
		return RetVar
	}
	GetRecentlyPlayed() {
		Resp := JSON.Load(this.ParentObject.Util.CustomCall("GET", "me/player/recently-played?limit=50"))
		for k, v in Resp["items"] {
			v := {"track": new track(v["track"], this.ParentObject), "context": new context(v["context"], this.ParentObject), "played_at": v["played_at"]}
		}
		return Resp
	}
	
	PausePlayback() {
		return this.ParentObject.Util.CustomCall("PUT", "me/player/pause")
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
	ResumePlayback() {
		return this.ParentObject.Util.CustomCall("PUT", "me/player/play")
	}
	SetShuffle(mode) {
		return this.ParentObject.Util.CustomCall("PUT", "me/player/shuffle?state=" . (mode ? "true" : "false"))
	}
	PlayPause() {
		return ((this.GetCurrentPlaybackInfo()["is_playing"] = 0) ? (this.ResumePlayback()) : (this.PausePlayback()))
	}
}
class Library {
	__New(ByRef ParentObject) {
		this.ParentObject := ParentObject
	}
	CheckSavedForAlbum(AlbumID) {
		return this.ParentObject.Util.CustomCall("GET", "me/albums/contains?ids=" . AlbumID)
	}
	CheckSavedForTrack(TrackID) {
		return this.ParentObject.Util.CustomCall("GET", "me/tracks/contains?ids=" . TrackID)
	}
	GetSavedAlbums(limit := 50, offset := 0) {
		Resp := JSON.Load(this.ParentObject.Util.CustomCall("GET", "me/albums?limit=" . limit . "&offset=" . offset))
		for k, v in Resp["items"] {
			v := {"album": new album(v["album"], this.ParentObject), "added_at": v["added_at"]}
		}
		return Resp
	}
	GetSavedTracks(limit := 50, offset := 0) {
		Resp := JSON.Load(this.ParentObject.Util.CustomCall("GET", "me/tracks?limit=" . limit . "&offset=" . offset))
		for k, v in Resp["items"] {
			v := {"track": new track(v["track"], this.ParentObject), "added_at": v["added_at"]}
		}
		return Resp
	}
}

class Tracks {
	__New(ByRef ParentObject) {
		this.ParentObject := ParentObject
	}
	GetTrack(TrackID) {
		return new track(JSON.Load(this.ParentObject.Util.CustomCall("GET", "tracks/" . TrackID)), this.ParentObject)
	}
}
class Albums {
	__New(ByRef ParentObject) {
		this.ParentObject := ParentObject
	}
	GetAlbum(AlbumID) {
		return new album(JSON.Load(this.ParentObject.Util.CustomCall("GET", "albums/" . AlbumID)), this.ParentObject)
	}
}

class track {
	__New(ResponseTrackObj, ByRef Parent := "") {
		this.SpotifyObj := Parent
		this.json := ResponseTrackObj
		this.id := this.json["id"]
		this.album := new album(this.json["album"], this.SpotifyObj) ; TODO -- Album objects
		;for k, v in this.json["artists"] {
		;	this.artists.Push(new artist(v)) TODO -- Artist objects
		;}
		this.duration := this.json["duration_ms"]
		this.explicit := this.json["explicit"]
		this.name := this.json["name"]
	}

	Save() {
		return this.SpotifyObj.Util.CustomCall("PUT", "me/tracks?ids=" . this.id)
	}
	
	UnSave() {
		return this.SpotifyObj.Util.CustomCall("DELETE", "me/tracks?ids=" . this.id)
	}
	
	Play() {
		return this.SpotifyObj.Util.CustomCall("PUT", "me/player/play",, false, JSON.Dump({"uris": ["spotify:track:" . this.id]}))
	}
}

class album {
	__New(Albumjson, ByRef Parent := "") {
		this.SpotifyObj := Parent
		this.json := Albumjson
		this.artists := this.json["artists"]
		this.genres := this.json["genres"]
		this.id := this.json["id"]
		this.images := this.json["images"]
		this.name := this.json["name"]
		this.uri := this.json["uri"]
		this.tracks := []
		this.context := new context({"uri": this.uri}, this.SpotifyObj)
		for k, v in this.json["tracks"]["items"] {
			this.tracks.Push(new track(v, this.SpotifyObj))
		}
	}
	
	Play() {
		return this.context.SwitchTo()
	}
	
	Save() {
		return this.SpotifyObj.Util.CustomCall("PUT", "me/albums?ids=" . this.id)
	}
	
	UnSave() {
		return this.SpotifyObj.Util.CustomCall("DELETE", "me/albums?ids=" . this.id)
	}
}

class device {
	__New(Devicejson, ByRef Parent := "") {
		this.SpotifyObj := Parent
		this.json := Devicejson
		this.id := this.json["id"]
		this.IsActive := this.json["is_active"]
		this.IsPrivate := this.json["is_private_session"]
		this.name := this.json["name"]
		this.type  := this.json["type"]
		this.volume := this.json["volume_percent"]
	}
	
	TransferPlaybackTo() {
		return this.SpotifyObj.Util.CustomCall("PUT", "me/player",, false, JSON.Dump({"device_ids": [this.id]}))
	}
}

class context {
	__New(Contextjson, ByRef Parent := "") {
		this.SpotifyObj := Parent
		this.json := Contextjson
		this.uri := this.json["uri"]
		this.type := this.json["type"]
	}
	
	SwitchTo() {
		return this.SpotifyObj.Util.CustomCall("PUT", "me/player/play",, false, JSON.Dump({"context_uri": this.uri}))
	}
}

#Include <AHKsock>
#Include <AHKhttp>
#Include <crypt>
#Include <json>