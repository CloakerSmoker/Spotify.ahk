#MaxThreads 2
;Spotify.Auth()
;MsgBox, % JSON.Dump(S.CurrentUser.Playlists)
;MsgBox, % JSON.Dump(S.Playlists.GetPlaylist("spotify:playlist:37i9dQZF1EjrwJMNfC5pGN").Tracks)
;z::
;MsgBox, % Spotify.Playlists.GetPlaylist("37i9dQZF1EjrwJMNfC5pGN").Name
;return
;MsgBox, % JSON.Dump(S.Albums.GetAlbum("spotify:album:6MdXxYdygE9DSD4WHDKmFV").Tracks)

class Spotify {
	Auth() {
		Spotify.Util.StartUp() ; Do the auth process
		
		Spotify.S_HTTP_ARCHIVE := HTTP.CACHE_FOREVER | HTTP.CACHE_IGNORE_HEADERS
		Spotify.CurrentUser := new Spotify.User(JSON.load(Spotify.Util.CustomCall("GET", "me")))
		Spotify.CurrentUser.IsCurrentUser := true
	}
	UToI(URI) {
		RegexMatch(URI, ":\K\w{22}", ID) ; Spotify probably has a standard for these URIs, but they always go something like spotify:user:AAAAAAA:playlist:0v2uDeO2CBArBZ3ujn8hKl, so assuming nobody's got a 22 character username, this will do
		return ID
	}
	
	TypeErr(Type1, Type2, Line) {
		static LF := "`n"
		return Exception("TypeError", "Spotify.ahk", "Objects of types (specifically " Type1 " and " (Type2 ? Type2 : "NonSpotifyObject") ") are not compatable." LF LF "Line: " Line)
	}
	
	class Util {
		static RefreshTokenRegKey := "HKCU\Software\SpotifyAHK" ; Where we store the refresh token between runs, change this if you'd like
		static ErrorHandlers := [this["Error"]]
	
		StartUp() {
			HTTP.SetCacheFile(A_ScriptDir "\SpotifyAHKCache.json")
			; This is a method because we *might* need to start the authorization process over again for some reason
			RegRead, Refresh, % this.RefreshTokenRegKey, RefreshToken ; Check if we have a stored refresh token, if we do, just get a new temp token using that, else do the whole auth process again
			
			if (Refresh) {
				this.RefreshToken := Refresh
				this.RefreshTempToken()
			} 
			else {
				Paths := {} ; HTTP sever paths mapped to AHK functions
				Paths["/callback"] := this.AuthCallback.Bind(this, this.FetchToken.Bind(this)) ; When someone is redirected by the Spotify auth, run "AuthCallback" and tell AuthCallback to run "FetchTokens" after
				;Paths["/playbackhost"] := this.ParentObject.Playback.WBStart.Bind(this.ParentObject.Playback, this.ChangeTimeoutMode.Bind(this, "playback"))
				Paths["404"] := this["NotFound"] ; When a page isn't found, say that
				Server := new HttpServer()
				Server.SetPaths(Paths)
				Server.Serve(8000)
				; Open the Spotify auth page in whatever browser, and request full permissions
				; Once auth is done, it redirects to /callback, calling "AuthCallback", execution stops until AuthCallback is called by the HTTP server
				Run, % "https://accounts.spotify.com/en/authorize?client_id=9fe26296bb7b4330ac59339efd2742b0&response_type=code&redirect_uri=http:%2F%2Flocalhost:8000%2Fcallback&scope=user-modify-playback-state%20user-read-currently-playing%20user-read-playback-state%20user-library-modify%20user-library-read%20user-read-email%20user-read-private%20user-read-birthdate%20user-follow-read%20user-follow-modify%20playlist-read-private%20playlist-read-collaborative%20playlist-modify-public%20playlist-modify-private%20user-read-recently-played%20user-top-read%20streaming"
			}
		}
		
		SetTimeout() {
			TimeOut := A_Now ; We've got a new token, in an hour it will expire, so we'll save the what time it will be in 1 hour
			EnvAdd, TimeOut, 1, hours
			this.TimeOut := TimeOut
		}
		CheckTimeout() {
			if (A_Now > this.TimeOut) {
				this.RefreshTempToken() ; If it is now past when our temp token expires, get a new one
			}
		}
		
		; API token operations
		
		RefreshTempToken() {
			Args := {"Content-Type": "application/x-www-form-urlencoded", "Authorization": "Basic OWZlMjYyOTZiYjdiNDMzMGFjNTkzMzllZmQyNzQyYjA6ZWNhNjU2ZDFkNTczNDNhOTllMWJjNWVmODQ0YmY2NGM="}
			; Assuming we already have a valid refresh token, ask Spotify for a valid access token we can use for everything else
			Response := JSON.Load(this.CustomCall("POST", "https://accounts.spotify.com/api/token?grant_type=refresh_token&refresh_token=" . this.RefreshToken, Args, true))
			
			if (Response["refresh_token"]) {
				this.SaveRefreshToken(Response) ; Sometimes Spotify might give us a new refresh token, so if we got a new one, save it
			}
			
			if (Response["access_token"]) {
				; If we got an access token, we can set the flag that we're authorized
				this.AuthComplete := true
				this.Token := Response["access_token"] ; And store the new access token
				this.SetTimeout() ; And set when the new access token will expire
			}
			else {
				; Else if they didn't give us a new access token, something went wrong
				this.AuthComplete := false ; Set that auth is *not* complete
				
				if (Response["error_description"] = "Invalid refresh token") {
					RegWrite, REG_SZ, % this.RefreshTokenRegKey, RefreshToken, % ""
				}
				
				Throw {"Message": Response["error_description"], "What": Response["error"], "File": A_LineFile, "Line": A_LineNumber}
				;this.StartUp() ; Call startup after wiping the stored refresh token, so we can try to get a new valid one
			}
		}
		FetchToken() {
			; If there was any sort of error during the web auth, assume any auth code we got is bad, and throw a real error
			; This is pretty much the only error we can't recover from, since we can't just redo the wbe auth when the web auth just failed.
			if (this.AuthFail) {
				Throw {"Message": "Spotify.ahk web authorization failed", "What": "Authorization fail", "File": A_LineFile, "Line": A_LineNumber}
				return
			}
			if (this.AuthComplete) {
				; If we've already used our auth code, and have our tokens, we don't need to try this again 
				; Note: This entire check/var might actually be useless since it's near impossible to get here again
				; Maybe if it's directly called, but who would just call random methods? Maybe rename this
				return
			}
			;SetTimer, % Fn, Off
			
			Args := {"Content-Type": "application/x-www-form-urlencoded", "Authorization": "Basic OWZlMjYyOTZiYjdiNDMzMGFjNTkzMzllZmQyNzQyYjA6ZWNhNjU2ZDFkNTczNDNhOTllMWJjNWVmODQ0YmY2NGM="}
			Response := JSON.Load(R := this.CustomCall("POST", "https://accounts.spotify.com/api/token?grant_type=authorization_code&code=" . this.AuthCode . "&redirect_uri=http:%2F%2Flocalhost:8000%2Fcallback", Args, true))
			
			;MsgBox, % R
			
			if (Response["refresh_token"]) {
				this.SaveRefreshToken(Response)
			}
			else {
				Throw {"Message": "Spotify.ahk did not receive a refresh token from the Spotify API", "What": "Authorization fail", "File": A_LineFile, "Line": A_LineNumber}
				RegWrite, REG_SZ, % this.RefreshTokenRegKey, RefreshToken, % ""
				; I lied (again) below, I don't know what the hell I was thinking, but we CAN NOT recover from the Spotify API failing to give us a refresh token first try
			}
			
			if (Response["access_token"]) {
				; If we got an access token, we can set the flag that we're authorized
				this.AuthComplete := true
				this.Token := Response["access_token"] ; And store the new access token
				this.SetTimeout() ; And set when the new access token will expire
				AHKsock_Close(-1) ; close the listen server
			}
			else {
				; Else if they didn't give us a new access token, something went wrong
				this.AuthComplete := false ; Set that auth is *not* complete
				
				; I lied, this is the *other* only error we can't recover from, if there's an error getting our first access token, then something's fucky and we shouldn't keep trying
				RegWrite, REG_SZ, % this.RefreshTokenRegKey, RefreshToken, % ""
				;MsgBox, % "Hi"
				Throw {"Message": "Spotify.ahk could not get an authorization token after web authorization", "What": "Authorization fail", "File": A_LineFile, "Line": A_LineNumber}
				return
			}
		}
		
		; Local token operations
		
		SaveRefreshToken(Response) {
			; Might get a JSON object from a response that contains a refresh token, or just that token as a string
			; Either way, store the token and write it to the registry
			if (Response["refresh_token"]) {
				this.RefreshToken := Response["refresh_token"]
				RegWrite, REG_SZ, % this.RefreshTokenRegKey, RefreshToken, % Response["refresh_token"]
			}
			else if (Response) {
				this.RefreshToken := Response
				RegWrite, REG_SZ, % this.RefreshTokenRegKey, RefreshToken, % Response
			}
			return
		}
		
		; API call method with auto-auth/timeout check/base URL
		
		CustomCall(Method, URL, HeaderMap := "", NoTimeOut := false, BodyData := "", NoError := false, CacheMode := 0x0) {
			; TODO -- Swap BodyData and NoTimeOut, since the extra stuff should come after the more common stuff
			if (HeaderMap = -1) {
				; allows for params to be passed as an object, since this function has way too many
				for k, v in NoTimeOut {
					;MsgBox, % "Set " k " := " v
					%k% := v ; set that param to be the version passed
				}
				
				if (HeaderMap = -1) {
					; if a new headermap was not given, set it back to the original for the !(HeaderMap) check
					HeaderMap := ""
				}
				if (IsObject(NoTimeOut)) {
					; if a new NoTimeOut wasn't given, set it back to default for the same reason
					NoTimeOut := false
				}
				
				;MsgBox, % Method "`n" URL "`n" HeaderMap "`n" NoTimeOut "`n" BodyData "`n" NoError "`n" CacheMode
			}
			
			if !(NoTimeOut) {
				this.CheckTimeout() ; If we are doing an operation that doesn't use the access token, we don't need to check if it's expired
			}
			if !((InStr(URL, "https://api.spotify.com")) || (InStr(URL, "https://accounts.spotify.com/api/"))) {
				URL := "https://api.spotify.com/v1/" URL ; If we're just passed a API endpoint path, prepend the API base path to it
			}
			if !(HeaderMap) {
				HeaderMap := {"Authorization": "Bearer " this.Token} ; If we're not passed a bunch of request headers, just use the default Spotify auth header with our access token
				; Since this only happens when we don't get a list of headers, we don't need to worry about it when getting or initial tokens since each one of those requests uses custom headers
			}
			
			Response := HTTP.Request(Method, URL, HeaderMap, BodyData, CacheMode)
			
			return Response.Text ; Return whatever the API wants to give us
		}
		Error(Exception) {
			Throw, % Exception
		}
		
		; Web auth methods
		
		NotFound(ByRef req) {
			; Will be called on 404, not really important
			Response := new HttpResponse()
			Response.SetBodyText("Page not found")
			return Response
		}
		AuthCallback(NextFunction, Request, HttpServer) {
			; Will be called by the HTTP server after the Spotify auth redirects to localhost
			Response := new HttpResponse() 
			Response.SetBodyText(Request.Queries["error"] 
							? "Error, authorization not given, Spotify.ahk will not function correctly without authorization." 
							: "Authorization complete, closing listen server.") 
			; Spotify passes the query param "error" to tell us if something went wrong, we set the body text of our response to tell the user if something's up
			Response.status := (Request.Queries["error"] ? 400 : 200) ; If error, HTTP code >400 just  
			
			this.AuthCode := Request.Queries["code"] ; Query param "code" contains an auth code that we can exchange for our first real auth token and refresh token
			this.AuthFail := Request.Queries["error"] ; Just store the error param, so the rest of the script knows if something went wrong
			
			SetTimer, % NextFunction, -10 ; Call the function for after we get the auth code in a new thread since the HTTP server fucks the call stack

			return Response
		}
		WebAuthDone() {
			return (this.AuthCode ? true : false) ; Will tell us if we have the auth code we need to get our real tokens
		}
		
		class HTTPCache {
			SetCacheFile(FilePath) {
				return HTTP.SetCacheFile(FilePath)
			}
			Enable() {
				return HTTP.EnableCache()
			}
			Disable() {
				return HTTP.DisableCache()
			}
		}
	}
	
	class Player {
		SaveCurrentlyPlaying() {
			/*
			* Gets the currently playing track, then uses
			* Requires something to be playing
			* returns the text response from the API, which is empty unless there is an error
			*/
			return Spotify.Library.SaveTrack(this.GetCurrentTrack().ID)
		}
		UnSaveCurrentlyPlaying() {
			/*
			* Gets the currently playing track, then tells it to unsave itself
			* Requires something to be playing
			* returns the text response from the API, which is empty unless there is an error
			*/
			return Spotify.Library.UnSaveTrack(this.GetCurrentTrack().ID)
		}
		SetVolume(Volume) {
			/*
			* Sets the volume of playback on the active device to the percent (0-100) passed 
			*/
			if (Volume > 100) {
				Volume := 100
			}
			else if (Volume < 0) {
				Volume := 0
			}
			return Spotify.Util.CustomCall("PUT", "me/player/volume?volume_percent=" Volume)
		}
		GetCurrentPlaybackInfo() {
			return this.GetFullPlaybackInfo()
		}
		GetPartialPlaybackInfo() {
			Resp := JSON.load(Spotify.Util.CustomCall("GET", "me/player/currently-playing"))
			Resp.Track := new Spotify.Track(Resp["item"])
			Resp.Context := new Spotify.Context(Resp["context"])
			return Resp
		}
		GetFullPlaybackInfo() {
			/*
			* Calls me/player, which returns a whole bunch of different objects
			* Translates JSON versions of track/device/context objects into custom objects
			* Alters the original response object, so any extra info that can't be turned into an object is still returned
			*/
			Resp := JSON.load(Spotify.Util.CustomCall("GET", "me/player"))
			Resp.Track := new Spotify.Track(Resp["item"])
			Resp.Device := new Spotify.Device(Resp["device"])
			Resp.Context := new Spotify.Context(Resp["context"])
			return Resp
		}
		GetCurrentTrack() {
			return this.GetPartialPlaybackInfo().Track
		}
		
		GetDeviceList() {
			/*
			* Gets an array of device objects from the API
			* Translates them into our device class, and returns an array of custom device objects
			*/
			Resp := JSON.Load(Spotify.Util.CustomCall("GET", "me/player/devices"))
			DeviceList := []
			for k, v in Resp["devices"] {
				DeviceList.Push(new Spotify.Device(v))
			}
			return DeviceList
		}
		GetRecentlyPlayed() {
			/*
			* Gets an array of tracks alongside other info from the API
			* You might also want to read this Spotify API docs page
			* https://developer.spotify.com/documentation/web-api/reference/player/get-recently-played/
			* Array
			* |-> [1] Play History Object
			* |       |-> ["track"] (A simplified track object)
			* |       |-> ["context"] (A context object the track was played in)
			* |       |-> ["played_at"] (A UTC timestamp formatted YYYY-MM-DDTHH:MM:SSZ) - Note, I've got no clue what T or Z mean
			* |-> [2] Another Play History Object (They are numerically indexed, you can loop through with a for loop)
			*/
			Resp := JSON.Load(Spotify.Util.CustomCall("GET", "me/player/recently-played?limit=50"))
			
			RecentlyPlayedObjects := []
			for k, v in Resp["items"] {
				RecentlyPlayedObjects.Push({"track": new Spotify.Track(v["track"]), "context": new Spotify.Context(v["context"]), "played_at": v["played_at"]})
			}
			return RecentlyPlayedObjects
		}
		SeekTime(TimeInMS) {
			/*
			* Tells the API to jump to the specified time in MS on the currently playing track
			*/
			return Spotify.Util.CustomCall("PUT", "me/player/seek?position_ms=" TimeInMS)
		}
		SetRepeatMode(NewMode) {
			if !(Mode := {"Track": "track", "Context": "context", "Off": "off"}[NewMode]) {
				return ; Basically a painful way to make sure NewMode is a valid mode, and to make it lowercase
			}

			return Spotify.Util.CustomCall("PUT", "me/player/repeat?state=" Mode)
		}
		SetShuffle(NewMode) {
			/*
			* Tells the API to change the shuffle mode to true/false, depending on what it it passed
			*/
			return Spotify.Util.CustomCall("PUT", "me/player/shuffle?state=" (NewMode ? "true" : "false"))
		}
		NextTrack() {
			return Spotify.Util.CustomCall("POST", "me/player/next")
		}
		PrevTrack() {
			return this.LastTrack()
		}
		LastTrack() {
			return Spotify.Util.CustomCall("POST", "me/player/previous")
		}
		PausePlayback() {
			return Spotify.Util.CustomCall("PUT", "me/player/pause")
		}
		ResumePlayback() {
			return Spotify.Util.CustomCall("PUT", "me/player/play")
		}
		PlayPause() {
			/*
			* Figure this one out on your own
			*/
			if (IsPlaying := this.GetCurrentPlaybackInfo()["is_playing"]) {
				this.PausePlayback()
			} 
			else {
				this.ResumePlayback()
			}
			return !IsPlaying
		}
		
		SwitchToDevice(DeviceID) {
			return Spotify.Util.CustomCall("PUT", "me/player",, false, JSON.Dump({"device_ids": [DeviceID]}))
		}
		SwitchToContext(ContextType, ContextID) {
			return Spotify.Util.CustomCall("PUT", "me/player/play",, false, JSON.Dump({"context_uri": "spotify:" ContextType ":" ContextID}))
		}
		PlayTrack(TrackID) {
			return Spotify.Util.CustomCall("PUT", "me/player/play",, false, JSON.Dump({"uris": ["spotify:track:" TrackID]}))
		}
		PlayPlaylist(PlaylistID) {
			return this.SwitchToContext("playlist", PlaylistID)
		}
		PlayAlbum(AlbumID) {
			return this.SwitchToContext("album", AlbumID)
		}
	}
	class Library {
		; saved album functions
		GetSavedAlbums() {
			return Spotify.PagingObjectEndpointGet("me/albums?limit=50&offset=", "Album", this.CountSavedAlbums(), this["SavedAlbumsFilter"].Bind(this))
		}
		SavedAlbumsFilter(SavedAlbumObject) {
			SavedAlbumObject.Album.Added_At := SavedAlbumObject.Added_At
			return SavedAlbumObject.Album
		}
		CountSavedAlbums() {
			AlbumCounter := JSON.Load(Spotify.Util.CustomCall("GET", "me/albums?limit=1"))
			return AlbumCounter["total"]
		}
		
		AlbumIsSaved(AlbumID) {
			return Spotify.Util.CustomCall("GET", "me/albums/contains?ids=" AlbumID)
		}
		SaveAlbum(AlbumID) {
			return Spotify.Util.CustomCall("PUT", "me/albums?ids=" AlbumID)
		}
		UnSaveAlbum(AlbumID) {
			return Spotify.Util.CustomCall("DELETE", "me/albums?ids=" AlbumID)
		}

		; saved track functions
		GetSavedTracks() {
			return Spotify.PagingObjectEndpointGet("me/tracks?limit=50&offset=", "Track", this.CountSavedTracks(), this["SavedTracksFilter"].Bind(this))
		}
		SavedTracksFilter(SavedTrackObject) {
			SavedTrackObject.Track.Added_At := SavedTrackObject.Added_At
			return SavedTrackObject.Track
		}
		CountSavedTracks() {
			TrackCounter := JSON.Load(Spotify.Util.CustomCall("GET", "me/tracks?limit=1"))
			return TrackCounter["total"]
		}
		
		TrackIsSaved(TrackID) {
			return Spotify.Util.CustomCall("GET", "me/tracks/contains?ids=" TrackID)
		}
		SaveTrack(TrackID) {
			return Spotify.Util.CustomCall("PUT", "me/tracks?ids=" TrackID)
		}
		UnSaveTrack(TrackID) {
			return Spotify.Util.CustomCall("DELETE", "me/tracks?ids=" TrackID)
		}
	}
	
	class Playlists {
		GetPlaylist(PlaylistID) {
			return new Spotify.Playlist(JSON.Load(Spotify.Util.CustomCall("GET", "playlists/" PlaylistID, -1, {"CacheMode": Spotify.S_HTTP_ARCHIVE})))
		}
		PlaylistGetTrackCount(PlaylistID) {
			PlaylistCounter := JSON.Load(Spotify.Util.CustomCall("GET", "playlists/" PlaylistID "/tracks?limit=1"))
			return PlaylistCounter["total"]
		}
		PlaylistAddTrack(PlaylistID, TrackID) {
			return Spotify.Util.CustomCall("POST", "playlists/" PlaylistID "/tracks?uris=spotify:track:" TrackID)
		}
		PlaylistRemoveTrack(PlaylistID, TrackID) {
			return Spotify.Util.CustomCall("DELETE", "playlists/" PlaylistID "/tracks",, false, JSON.Dump({"tracks": [{"uri": "spotify:track:" TrackID}]}))
		}
		DeletePlaylist(PlaylistID) {
			return Spotify.Util.CustomCall("DELETE", "playlists/" PlaylistID "/followers")
		}
		CreatePlaylist(PlaylistName, Public := false, Description := "") {
			return new Spotify.Playlist(JSON.Load(Spotify.Util.CustomCall("POSt", "https://api.spotify.com/v1/users/" Spotify.CurrentUser.ID "/playlists",, false, JSON.Dump({"name": PlaylistName, "public": (Public ? "true" : "false"), "description": Description}))))
		}
	}
	class Playlist extends SpotifyAPIBaseClass {
		Init() {
			this.Owner := new Spotify.User(this.JSON["owner"])
			
			this.Public := (this.JSON["public"] = "null" ? true : (this.JSON["public"] = "true"))
			
			if ((this.JSON["tracks"]["items"].Count() = this.JSON["tracks"]["total"]) && this.JSON["tracks"]["total"]) {		
				this.Tracks := []
				
				for k, v in this.JSON["tracks"]["items"] {
					this.Tracks.Push(new Spotify.Track(v["track"]))
				}
			}
			else {
				this.JSON["tracks"] := ""
			}
		}
		Get(Key) {
			if (Key = "Tracks") {
				;MsgBox, % "Getter Called"
				
				this.Tracks := this.GetAllTracks()
				return this.Tracks
			}
		}
		Refresh() {
			this.JSON := Spotify.Playlists.GetPlaylist(this.ID).JSON
			this.Init()
			return true
		}
		
		GetAllTracks() {
			return Spotify.PagingObjectEndpointGet("playlists/" this.ID "/tracks?offset=", "Track", this.GetTrackCount(), this["PagingFilter"].Bind(this))
		}
		PagingFilter(PlaylistTrackObject) {
			return PlaylistTrackObject["track"]
		}
		
		GetTrackCount() {
			return Spotify.Playlists.PlaylistGetTrackCount(this.ID)
		}
		AddTrack(TrackObject) {
			return Spotify.Playlists.PlaylistAddTrack(this.ID, TrackObject.ID)
		}
		RemoveTrack(TrackObject) {
			return Spotify.Playlists.PlaylistRemoveTrack(this.ID, TrackObject.ID)
		}
		Play() {
			return Spotify.Player.SwitchToContext("playlist", this.ID)
		}
		Delete() {
			return Spotify.Playlists.DeletePlaylist(this.ID)
		}
	}
	
	class Tracks {
		GetTrack(TrackID) {
			return new Spotify.Track(JSON.Load(Spotify.Util.CustomCall("GET", "tracks/" TrackID, -1, {"CacheMode": S_HTTP_ARCHIVE})))
		}
	}
	class Track extends SpotifyAPIBaseClass {
		Init() {
			if (IsObject(this.JSON["album"])) {
				this.Album := new Spotify.Album(this.JSON["album"]) ; TODO -- Album objects;;; done
			}
			
			this.Artists := []
			
			for k, v in this.JSON["artists"] {
				this.Artists[k] := new Spotify.Artist(v)
			}
		}
		Get(Key) {
			if (Key = "duration") {
				return this.duration_ms
			}
		}
		Refresh() {
			this.JSON := Spotify.Tracks.GetTrack(this.ID).JSON
			this.Init()
			return true
		}
		
		IsSaved() {
			return Spotify.Library.TrackIsSaved(this.ID)
		}
	
		Save() {
			return Spotify.Library.SaveTrack(this.ID)
		}
		
		UnSave() {
			return Spotify.Library.UnSaveTrack(this.ID)
		}
		
		Play() {
			return Spotify.Player.PlayTrack(this.ID)
		}
	}
	
	class Albums {
		GetAlbum(AlbumID) {
			return new Spotify.Album(JSON.Load(Spotify.Util.CustomCall("GET", "albums/" AlbumID, -1, {"CacheMode": Spotify.S_HTTP_ARCHIVE})))
		}
		AlbumGetTrackCount(AlbumID) {
			TrackCounter := JSON.Load(Spotify.Util.CustomCall("GET", "albums/" AlbumID "/tracks?limit=1", -1, {"CacheMode": Spotify.S_HTTP_ARCHIVE}))
			return TrackCounter["total"]
		}
	}
	class Album extends SpotifyAPIBaseClass {
		Init() {
			; o h m y f u c k i n g g o d
			; I have spent DAYS
			; reading every. single. line of this library
			; trying to find why |this.JSON["tracks"] := ""| would through a load-time error
			; about an invalid setter
			; turns out it was because I forgot a { after |if (this.JSON["tracks"]["items"].Count() = this.GetTrackCount())|
			
			if ((this.JSON["tracks"]["items"].Count() = this.JSON["tracks"]["total"]) && this.JSON["tracks"]["items"]) {
				this.Tracks := []
			
				for k, v in this.JSON["tracks"]["items"] {
					this.Tracks.Push(new Spotify.Track(v))
				}
			}
			else {
				this.JSON["tracks"] := ""
			}
			
			this.Images := []
			
			for k, v in this.JSON["Images"] {
				this.Images.Push(v)
			}
		}
		Get(Key) {
			if (Key = "Tracks") {
				this.Tracks := this.GetAllTracks()
				return this.Tracks
			}
		}
		Refresh() {
			this.JSON := Spotify.Albums.GetAlbum(this.ID).JSON
			this.Init()
			return true
		}
		
		GetAllTracks() {
			return Spotify.PagingObjectEndpointGet("albums/" this.ID "/tracks?offset=", "Track", this.GetTrackCount())
		}
		GetTrackCount() {
			return Spotify.Albums.AlbumGetTrackCount(this.ID)
		}
		
		IsSaved() {
			return Spotify.Library.AlbumIsSaved(this.ID)
		}
		Save() {
			return Spotify.Library.SaveAlbum(this.ID)
		}
		UnSave() {
			return Spotify.Library.UnSaveAlbum(this.ID)
		}
		Play() {
			return Spotify.Player.SwitchToContext("album", this.ID)
		}
	}
	class Device extends SpotifyAPIBaseClass {
		Init() {
			if !(this.volume_percent) {
				this.volume_percent := 0
			}
		}
		Get(Key) {
			if (Key = "volume") {
				return this.volume_percent
			}
		}
		Refresh() {
			return false
		}
	
		SwitchTo() {
			return Spotify.Player.SwitchToDevice(this.ID)
		}
	}
	class Context extends SpotifyAPIBaseClass {
		Init() {
			this.ID := Spotify.UToI(this.URI)
		}
		Refresh() {
			return false
		}
	
		SwitchTo() {
			return Spotify.Player.SwitchToContext(this.Type, this.ID)
		}
	}
	
	class Artists {
		GetArtist(ArtistID) {
			return new Spotify.Artist(JSON.Load(Spotify.Util.CustomCall("GET", "artists/" ArtistID, -1, {"CacheMode": Spotify.S_HTTP_ARCHIVE})))
		}
		ArtistGetAlbumCount(ArtistID) {
			AlbumCounter := JSON.load(Spotify.Util.CustomCall("GET", "artists/" ArtistID "/albums?limit=1"))
			return AlbumCounter["total"]
		}	
	}
	class Artist extends SpotifyAPIBaseClass {
		Init() {
			if ((this.JSON["albums"]["items"].Count() = this.JSON["albums"]["total"]) && this.JSON["albums"]["total"]) {
				this.Albums := []
			
				for k, v in this.JSON["albums"]["items"] {
					this.Albums.Push(new Spotify.Album(v))
				}
			}
			else {
				this.JSON["albums"] := ""
			}
		}
		Get(Key) {
			if (Key = "Albums") {
				this.Albums := this.GetAllAlbums()
				return this.Albums
			}
		}
		Refresh() {
			this.JSON := Spotify.Artists.GetArtist(this.ID).JSON
			this.Init()
			return true
		}
	
		GetAllAlbums() {
			return Spotify.PagingObjectEndpointGet("artists/" this.ID "/albums?limit=50&offset=", "Album", this.GetAlbumCount())
		}
		GetAlbumCount() {
			return Spotify.Artists.ArtistGetAlbumCount(this.ID)
		}
	}
	
	class Users {
		GetUser(UserID) {
			return new Spotify.User(JSON.Load(Spotify.Util.CustomCall("GET", "users/" UserID, -1, {"CacheMode": Spotify.S_HTTP_ARCHIVE})))
		}
		UserGetPlaylists(UserID, Offset := 0, Limit := 50) {
			PlaylistArray := []
	
			for k, v in JSON.load(Spotify.Util.CustomCall("GET", "users/" UserID "/playlists?limit=" Limit "&offset=" Offset))["items"] {
				PlaylistArray.Push(new Spotify.Playlist(v))
			}
			
			return PlaylistArray
		}
		UserGetTracks(UserID, Offset := 0, Limit := 50) {
			TrackArray := []
	
			for k, v in JSON.load(Spotify.Util.CustomCall("GET", "users/" UserID "/tracks?limit=" Limit "&offset=" Offset))["items"] {
				TrackArray.Push(new Spotify.Track(v["track"]))
			}
			
			return TrackArray
		}
		UserGetPlaylistsCount(UserID) {
			PlaylistCounter := JSON.Load(Spotify.Util.CustomCall("GET", "users/" UserID "/playlists?limit=1"))
			return PlaylistCounter["total"]
		}
		UserGetTrackCount(UserID) {
			TrackCounter := JSON.Load(Spotify.Util.CustomCall("GET", "users/" UserID "/tracks?limit=1"))
			return TrackCounter["total"]
		}
	}
	class User extends SpotifyAPIBaseClass {
		Init() {
			this.IsCurrentUser := false
			this.Name := this.JSON["display_name"]
			this.SubscriptionLevel := this.JSON["product"]
		}
		
		Get(Key) {
			if (Key = "Playlists") {
				this.Playlists := this.GetAllPlaylists()
				return this.Playlists
			}
			else if (Key = "Tracks") {
				this.Tracks := this.GetAllTracks()
				return this.Tracks
			}
		}
		
		Refresh() {
			this.JSON := Spotify.Users.GetUser(this.ID).JSON
			this.Init()
			return true
		}
		
		GetPlaylistsCount() {
			PlaylistCounter := JSON.Load(Spotify.Util.CustomCall("GET", "users/" this.ID "/playlists?limit=1"))
			return PlaylistCounter["total"]
		}
		GetTrackCount() {
			TrackCounter := JSON.Load(Spotify.Util.CustomCall("GET", "users/" this.ID "/tracks?limit=1"))
			return TrackCounter["total"]
		}
		
		GetAllPlaylists() {
			return Spotify.PagingObjectEndpointGet("users/" this.ID "/playlists?limit=50&offset=", "Playlist", this.GetPlaylistsCount())
		}
		GetAllTracks() {
			return Spotify.PagingObjectEndpointGet("users/" this.ID "/tracks?limit=50&offset=", "Track", this.GetPlaylistsCount())
		}
		
		GetPlaylists(Offset, Limit) {
			return Spotify.Users.UserGetPlaylists(this.ID, Offset, Limit)
		}
		GetTracks(Offset, Limit) {
			return Spotify.Users.UserGetTracks(this.ID, Offset, Limit)
		}
		
		GetTop(ArtistsOrTracks := "tracks") {
			if !(this.IsCurrentUser) {
				Throw {"Message": "The Spotify API does not allow getting the top tracks/artists of any user except for the current.", "What": "Wrong User", "File": A_LineFile, "Line": A_LineNumber}
			}
			
			ReturnArray := []
			
			for k, v in JSON.load(Spotify.Util.CustomCall("GET", "me/top/" ArtistsOrTracks))["items"] {
				if (ArtistsOrTracks = "artists") {
					ReturnArray.Push(new Spotify.Artist(v))
				}
				else {
					ReturnArray.Push(new Spotify.Track(v))
				}
			}
			
			return ReturnArray
		}
	}
	
	class Search {
		For(Types*) {
			Object := {"Types": Types}
			Object.By := Spotify.Search._By.Bind(Object)
			return Object
		}
		_By(Object, What, Criterion) {
			;Msgbox, % "By " JSON.Dump(Criterion) "`nT:" JSON.Dump(Object)
			Criterion["q"] := What
			
			return Spotify.Search.Search(Spotify.Search.BuildQueryString(Object.Types, ObjectCriterion))
		}
	
	
		Search(QueryString) {
			Result := JSON.Load(Spotify.Util.CustomCall("GET", "search?" QueryString))
			
			ResultObject := new Spotify.Search.SearchResult(QueryString)
			
			for k, v in Result.Artists.Items {
				ResultObject.Push("artist", v)
			}
			
			for k, v in Result.Tracks.Items {
				ResultObject.Push("track", v)
			}
			
			for k, v in Result.Albums.Items {
				ResultObject.Push("album", v)
			}
			
			for k, v in Result.Playlists.Items {
				ResultObject.Push("playlist", v)
			}
			
			return ResultObject
		}
		
		class SearchResult {
			__New(QueryString) {
				this.Artists := []
				this.Tracks := []
				this.Albums := []
				this.Playlists := []
				this.Query := QueryString
			}
			Push(Type, ValueJSON) {
				ObjectClass := Spotify[Type]
				this[type "s"].Push(new ObjectClass(ValueJSON))
			}
		}
		
		BuildQueryString(Types, QueryParts) {
			QueryString := ""
			TypeString := ""
			Limit := 10
			Offset := 0
			
			for k, v in Criterion {
				if (k = "limit") {
					Limit := v
				}
				else if (k = "offset") {
					Offset := v
				}
				else {
					QueryString := QueryString this.BuildQueryPart(v) (k != Criterion.Count() ? "%20" : "")
				}
			}
			
			for k, v in Types {
				TypeString := TypeString (SubStr(v, -0) = "s" ? SubStr(v, 1, StrLen(v) - 1) : v) (k != Types.Count() ? "," : "")
			}
			
			return "q=" QueryString "&types" TypeString "&limit=" Limit "&Offset=" Offset 
		}
		
		BuildQueryPart(Name, Value := false) {
			if !(Value) {
				return StrReplace(Name, A_Space, "%20")
			}
			else {
				return StrReplace(Name ":" Value, A_Space, "%20")
			}
		}
	}
	
	PagingObjectEndpointGet(URL, ClassName, TotalCount, Filter := false) {
		; I don't know why, but I couldn't return the array of playlists generated by this function properly, so ignore the stuff with ObjectArray
		; Maybe some limitation on pushing large objects onto an array
		ObjectArray := []
		ObjectArray[1] := ""
		ObjectArray.SetCapacity(TotalCount)
		
		ObjectClass := this[ClassName] ; "Dynamic initialization" - thanks nnnik for the OOP expertise
		
		loop, % Ceil(TotalCount / 50) {
			for k, v in JSON.Load(this.Util.CustomCall("GET", URL . ((A_Index - 1 ) * 50)))["items"] {
				ObjectArray.Push(new ObjectClass((Filter ? Filter.Call(v) : v)))
			}
		}
		
		ObjectArray.RemoveAt(1)
		return ObjectArray
	}
}

class SpotifyAPIBaseClass {
	; For pretty much all API objects, we just store the JSON, and maybe change around some names before handing it to the user
	; so this base class will store the JSON for us, and call a func we override to rearange if we need
	
	__New(JSON) {
		this.JSON := JSON
		this.Init()
	}
	
	; By having __Get grab a value from the JSON, we can easily take an object from the API and let the user get any value they want from it
	; However, since sometimes an object might still want a __Get method, we can call regular Get() to see if the object has any overrides it wants to do
	__Get(Key) {
		Value := this.JSON[Key]
		
		if (!Value) {
			Value := this.Get(Key)
		}
		
		return Value
	}
	
	; Since usually Get() won't get overridden, this one will do
	Get(Key) {
		return ""
	}
	
	; method that should always be overridden
	; will replace this.json with a complete/updated version of this object
	; for when you get a incomplete object, or think a resource might have updated
	; also for when something fails an IsValid check
	Refresh() {
		return false
	}
}
IsValid(Object) {
	; depending on the class of the object passed, this function will check if most/all
	; of its properties are set correctly 
	; note: not all objects need to be valid in the way this function outputs
	; most API objects are fine with just an ID/URI, so only use this function to ensure the data
	; you need is there, and call Obj.Refresh() if it is not
	; IsLowValid() can be used to check if an object is fucked or not instead
	
	; note to self/anyone crazy enough to try to add on to this garbage heap: If an object doesn't pass IsValid after Obj.Refresh is called, you fucked up
	
	if (Object.__Class = "Spotify.Track") {
		if (IsLowValid(Object) &&  (Object.Album.__Class = "Spotify.Album") && Object.Artists.Count() && (Object.Type = "track") && (Object.duration_ms + 1 = Object.duration_ms + 1)) {
			return true
		}
	}
	else if (Object.__Class = "Spotify.Playlist") {
		if (IsLowValid(Object) && (Object.Owner.__Class = "Spotify.User") && Object.Tracks.Count() && (Object.Type = "playlist")) {
			return true
		}
	}
	else if (Object.__Class = "Spotify.Album") {
		if (IsLowValid(Object) && (Object.Artists[1].__Class = "Spotify.Artist") &&  Object.Tracks.Count() && (Object.Type = "album") && Object.Images.Count()) {
			return true
		}
	}
	return false
}
IsLowValid(Object) {
	if (Object.ID && Object.URI && Object.Name) {
		return true
	}
	return false
}

; EVERYTHING BELOW IS JUST FOR HTTP CACHING 
; EDIT HTTP.Request() TO JUST MAKE THE REQUEST
; AND YOU CAN REMOVE EVERYTHING ELSE

class HTTP {
	static _ := HTTP.Init()
	
	; A class that makes HTTP requests and accurately follows caching steps
	; when an HTTP response contains a caching-related header
	
	Init() {
		HTTP.CACHE_FOREVER := 0x1
		HTTP.CACHE_IGNORE_HEADERS := 0x2
	
		; store our COM object that actually does the requests
		this.WinHTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1")

		this.UseFile := false ; by default, we don't know what file to use as a cache, so we can't use any
		this.Cache := {} ; the object that actually serves as the cache
		
		for k, Method in ["GET", "HEAD", "POST", "PUT", "DELETE", "CONNECT", "OPTIONS", "TRACE", "PATCH"] {
			this.Cache[Method] := [] ; the cache is seperated by request methods for simplicity
		}
		
		this.EnableCache()
	}
	__Delete() {
		this.WinHTTP.Abort() ; Cancel any partial request
		this.WinHTTP := "" ; delete the COM object
	}
	
	EnableCache() {
		this.UseCache := true
	}
	DisableCache() {
		this.UseCache := false
	}
	
	SetCacheFile(FilePath) {
		if (FileExist(FilePath)) {
			;MsgBox, % "Cache Exists"
			; if the cache file does exist
			BadJSON := false
			
			try {
				LoadedCache := JSON.Load(FileOpen(FilePath, "r").Read())
			}
			catch E {
				BadJSON := true
			}
			
			if (!BadJSON && LoadedCache.HasKey("GET")) {
				;MsgBox, % "Cache is JSON"
				; and the loaded file is a proper JSON version of a cach
				this.Cache := LoadedCache
				; then we use the loaded cache instead
			}
			else {
				;MsgBox, % "Cache is not JSON"
				; else the JSON in the file isn't valid, so we'll write our either A) Blank cache, or B) a populated cache
				; it doesn't matter which, since we only load this file on startup
				CacheFile := FileOpen(FilePath, "w")
				CacheFile.Length := 0
				CacheFile.Write(JSON.Dump(this.Cache))
				CacheFile.Close()
			}
		}
		else if (IsObject(CreatedFile := FileOpen(FilePath, "w"))) {
			;MsgBox, % "Cache did not exist"
			CreatedFile.Write(JSON.Dump(this.Cache))
			CreatedFile.Close()
		}
		else {
			MsgBox, % "Cache file could not be created/loaded"
			this.UseFile := false
			return
		}
		
		this.CacheFile := FilePath
		this.UseFile := true
	}
	
	Request(Method, URL, Headers := "", Body := "", CacheMode := 0x0) {
		; When a request is made, first CacheCheck is called, which will return 
		; a cached version of the request if it has been cached, and the cached
		; version is not expired. CacheCheck returns false when a request isn't
		; in the cache, so in that case we call _Request, which is the function
		; that actually sends the web request. Then we try to cache the request
		; with CacheAdd, which will check if the response had any cache headers
		; and calculates when the response will expire (-if ever) and stores it
	
		if !(this.UseCache && (Response := this.CacheCheck(Method, URL, Headers, Body, CacheMode))) {
			Response := this._Request(Method, URL, Headers, Body)
			this.CacheAdd(Response.Clone(), Method, URL, Headers, Body, CacheMode)
		}
		
		return Response
	}
	_Request(Method, URL, Headers, Body) {
		; Anything to do with this.WinHTTP inside this function (the one making
		; requests) must be critical, otherwise this function could be run more
		; than once at the any time, and this.WinHTTP could be busy or swap out
		; data from one request to the other, which would be veryyy veryyyy bad
		; However, since only some of the function uses this.WinHTTP.*, only ~7
		; lines have to be critical, since all the rest work on local variables
		
		Critical, On
	
		this.WinHTTP.Open(Method, URL, false)
		for HeaderName, HeaderValue in Headers {
			this.WinHTTP.SetRequestHeader(HeaderName, HeaderValue)
		}
		this.WinHTTP.Send(Body)
		
		ResponseText := this.WinHTTP.ResponseText
		ResponseHeaders := this.WinHTTP.GetAllResponseHeaders() ; store for later so we can turn critical off
		ResponseStatus := this.WinHTTP.Status
		
		Critical, Off
		
		HeaderPairs := {} ; Object to store {HeaderName: HeaderValue} in
		for k, v in StrSplit(ResponseHeaders, "`r`n") {
			; WinHTTP returns headers seperated by \r\n
			SplitHeader := StrSplit(v, ":")
			; A header is formatted `Name: Value1, ValueN`
			; so splitting by : gives us the name and value(s)
			HeaderName := SplitHeader[1]
			HeaderValue := LTrim(SplitHeader[2])
			; remove the leading space on the values (if it is there)
			if (HeaderName && HeaderValue) {
				; if both the name, and value of the header are not none, store it
				HeaderPairs[HeaderName] := HeaderValue
			}
		}

		return {"Text": ResponseText, "Headers": HeaderPairs, "Status": ResponseStatus}
	}
	
	CacheCheck(Method, URL, Headers, Body, CacheMode) {
		for k, CachedRequest in this.Cache[Method] {
			if (A_Now > CachedRequest.Expire) {
				; remove any cached requests that are already expired
				this.Cache[Method][k] := ""
			}
			else if (CachedRequest.URL = URL && CachedRequest.Body = Body) {
				if ((CacheMode & HTTP.CACHE_IGNORE_HEADERS) || (JSON.Dump(CachedRequest.Headers) = JSON.Dump(Headers))) {
					ToolTip, % "Cache hit on " URL "`nwith mode: " CacheMode
		
					RequestStream := FileOpen(this.CacheFile ".bin:" this.Encode(CachedRequest.URL), "rw")
					Text := RequestStream.Read()
					;MsgBox, % IsObject(RequestStream) "`n" RequestStream.Length "`n" Text
					RequestStream.Close()
		
					return {"Headers": CachedRequest.Response.Headers, "Status": CachedRequest.Response.Status, "Text": Text}
				}
				
				; if the cached request is valid, and matches the params for the request we are looking up now
				; return the cached response to the cached requests
				; also, if we are supposed to ignore the headers for this request, short circuit on (CacheMode & HTTP.CACHE_IGNORE_HEADERS) to avoid the check
			}
		}
		
		return false
	}
	Encode(String) {
		Len := StrLen(String)
		VarSetCapacity(pString, Len, 0)
		StrPut(String, &pString, Len, "UTF-8")
		return SubStr(this.Hash(&pString, Len), 1, 10)
	}
	Hash(pData, DataSize) {
		static PROV_RSA_FULL := 1
		static PROV_RSA_AES := 0x00000018
		static CRYPT_VERIFYCONTEXT := 0xF0000000
		static CALG_MD5	:= 0x00008003
		static HP_HASHVAL := 0x2
		
		VarSetCapacity(pCSPHandle, 8, 0)
		VarSetCapacity(RandomBuffer, 8, 0)
		
		DllCall("advapi32.dll\CryptAcquireContextA", "Ptr", &pCSPHandle, "UInt", 0, "UInt", 0, "UInt", PROV_RSA_FULL, "UInt", CRYPT_VERIFYCONTEXT)
		CSPHandle := NumGet(&pCSPHandle, 0, "UInt64")
		;MsgBox, % "CSP: " CSPHandle
		
		VarSetCapacity(pHashHandle, 8, 0)
		DllCall("advapi32.dll\CryptCreateHash", "Ptr", CSPHandle, "UInt", CALG_MD5, "UInt", 0, "UInt", 0, "Ptr", &pHashHandle)
		HashHandle := NumGet(&pHashHandle, 0, "UInt64")
		;MsgBox, % "Hash: " HashHandle
		
		DllCall("advapi32.dll\CryptHashData", "Ptr", HashHandle, "Ptr", pData, "UInt", DataSize, "UInt", 0)
		
		VarSetCapacity(pHashSize, 8, 0)
		DllCall("advapi32.dll\CryptGetHashParam", "Ptr", HashHandle, "UInt", HP_HASHVAL, "UInt", 0, "Ptr", &pHashSize, "UInt", 0)
		HashSize := NumGet(pHashSize, 0, "UInt64")
		;MsgBox, % "Hash Size: " HashSize
		
		VarSetCapacity(pHashData, HashSize, 0)
		DllCall("advapi32.dll\CryptGetHashParam", "Ptr", HashHandle, "UInt", HP_HASHVAL, "Ptr", &pHashData, "Ptr", &pHashSize, "UInt", 0)
		
		FirstHalf := NumGet(&pHashData, 0, "UInt64")
		SecondHalf := NumGet(&pHashData, 7, "UInt64")
		Hash := this.IntToHex(FirstHalf, true) this.IntToHex(SecondHalf, true)
		
		DllCall("advapi32.dll\CryptDestroyHash", "Ptr", HashHandle)
		DllCall("advapi32.dll\CryptReleaseContext", "Ptr", CSPHandle, "UInt", 0)
		
		return Hash
	}
	IntToHex(Int, NoPrefix := True) {
		static HexCharacters := ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
		End := (NoPrefix ? "" : "0x")
		HexString := ""
		Quotient := Abs(Int)
		
		loop {
			Remainder := Mod(Quotient, 16)
			HexString := HexCharacters[Remainder + 1] HexString
			Quotient := Floor(Quotient / 16)
		} until (Quotient = 0)
		
		loop % 2 - StrLen(HexString) {
			HexString := "0" HexString
		}
		
		if (Mod(StrLen(HexString), 2)) {
			HexString := "0" HexString
		}
		
		return End HexString
	}
	CachePush(CachedRequest) {
		if (this.UseFile) {
			RequestStream := FileOpen(this.CacheFile ".bin:" this.Encode(CachedRequest.URL), "rw")
			;MsgBox, % this.CacheFile ":" this.Encode(CachedRequest.URL)
			;MsgBox, % IsObject(RequestStream) "`n" RequestStream.Length
			RequestStream.Length := StrLen(CachedRequest.Response.Text) + 1
			RequestStream.Write(CachedRequest.Response.Text)
			RequestStream.Close()
			CachedRequest.Response.Text := ""
		}
		
		this.Cache[CachedRequest.Method].Push(CachedRequest)
	
		if (this.UseFile) {
			CacheFile := FileOpen(this.CacheFile, "rw")
			CacheFile.Seek(0)
			CacheFile.Length := 0
			CacheFile.Write(JSON.Dump(this.Cache))
			CacheFile.Close()
		}
	}
	
	CacheAdd(Response, Method, URL, Headers, Body, CacheMode) {	
		if !(this.UseCache) {
			return
		}
	
		if (CacheMode & HTTP.CACHE_FOREVER) {
			;MsgBox, % "Force Perma-cache on`nURL: " URL "`nMethod: " Method
			Never := A_Now
			EnvAdd, Never, 1000, Days
			this.CachePush(new CachedHTTPRequest(Method, URL, (CacheMode & HTTP.CACHE_IGNORE_HEADERS ? {} : Headers), Body, Response, Never))
		}
		else {
			MaxAgeExpire := -1
			Expire := -1
		
			if (CacheControl := Response.Headers["Cache-Control"]) {
				; If a response has a cache control header, we need to extract if it gives us a max age for this request
				; we also need to know if we shouldn't cache it at all, or if it can be perminantly cached (immutable)
				MaxAge := -1
				SMaxAge := -1
				
				if (InStr(CacheControl, "no-cache")) {
					return
				}
				if (InStr(CacheControl, "no-store")) {
					return
				}
				; if the server doesn't want it cached, then return without caching it
				
				if (InStr(CacheControl, "immutable")) {
					; if the request will always be the same, we'll say it expires in 1000 days. Hopefully nobody runs this script for 1000 days
					
					Never := A_Now
					EnvAdd, Never, 1000, Days
					this.Cache[Method].Push(new CachedHTTPRequest(Method, URL, Headers, Body, Response, Never))
					return
				}
				
				if (InStr(CacheControl, "max-age=")) {
					MaxAge := Trim(StrSplit(SubStr(CacheControl, InStr(CacheControl, "max-age=") + StrLen("max-age=")), " ")[1], " `t,")
				}
				if (InStr(CacheControl, "s-maxage=")) {
					SMaxAge := Trim(StrSplit(SubStr(CacheControl, InStr(CacheControl, "s-maxage=") + StrLen("s-maxage=")), " ")[1], " `t,")
					; in order goes from
					; private, s-maxage=200
					; s-maxage=200
					; 200
				}
				; Parse out max-age=123 and s-maxage=1234
				; and pick the smaller of the two as the max-max age of the object
				
				if (MaxAge != -1 && SMaxAge != -1) {
					TotalMaxAge := Min(MaxAge, SMaxAge) ; if both are set, pick the smaller
				}
				else if (MaxAge != -1) {
					TotalMaxAge := MaxAge ; if only one of the two is set, pick the one that is
				}
				else if (SMaxAge != -1) {
					TotalMaxAge := SMaxAge
				}
				
				MaxAgeExpire := A_Now
				EnvAdd, MaxAgeExpire, % TotalMaxAge, Seconds
				
				; Add the max-max age to A_Now to get a timestamp for when the request expires
			}
			if (Expires := Response.Headers["Expires"]) {
				; if a response has a Expires header, it is a special date/time stamp format containing when the object expires
				Expire := this.ParseHTTPDate(Expires)
				; ParseHTTPDate turns it to YYY-whatever
			}
			
			if (Expire != -1 && MaxAgeExpire != -1) {
				TotalExpire := Min(Expire, MaxAgeExpire)
			}
			else if (Expire != -1) {
				TotalExpire := Expire
			}
			else if (MaxAgeExpire != -1) {
				TotalExpire := MaxAgeExpire
			}
			else {
				TotalExpire := -1
			}
			; pick the soonest expiration date, so we don't accidentally wait too long to refresh the request
			
			if (TotalExpire > A_Now) {
				; if the expiration date isn't in the future, the request has already expired
				; so we shouldn't bother to cache it at all
				this.CachePush(new CachedHTTPRequest(Method, URL, (CacheMode & HTTP.CACHE_IGNORE_HEADERS ? {} : Headers), Body, Response, TotalExpire))
				; Note: the CachedHTTPRequest class is just for data storage, it has little/no functionality
			}
		}
	}
	
	ParseHTTPDate(HTTPDate) {
		; see: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Expires
		; for the format of this stamp, it generally follows 
		; Wed, 21 Oct 2015 07:28:00 GMT - FirstThreeOfWeekday, DayOfMonth FirstThreeOfMonth FourDigitYear Hour:Minute:Second GMT
		
		DateTime := {}
		SplitDate := StrSplit(HTTPDate, " ")
		
		DateTime["DayName"] := Trim(SplitDate[1], " ,")
		DateTime["DayOfMonth"] := SplitDate[2]
		DateTime["MonthName"] := SplitDate[3]
		DateTime["Year"] := SplitDate[4]
		
		Time := SplitDate[5]
		SplitTime := StrSplit(Time, ":")
		DateTime["Hour"] := SplitTime[1]
		DateTime["Minute"] := SplitTime[2]
		DateTime["Second"] := SplitTime[3]
		
		for k, v in DateTime {
			if !(v) {
				; when the stamp doesn't have a value for a certain bit of the stamp
				; replace it with N 0s, where N = the length of that field normally
			
				if (k = "Hour" || k = "Minute" || k = "Second") {
					DateTime[k] := "00"
				}
				else if (k = "DayName" || k = "MonthName") {
					DateTime[k] := "000"
				}
				else if (k = "Year") {
					DateTime[k] := "0000"
				}
				else {
					DateTime[k] := "0"
				}
			}
			if (k = "MonthName") {
				; FirstThreeOfMonth -> Month Number (padded to 2 characters)
				DateTime["Month"] := {"Jan": "01", "Feb": "02", "Mar": "03", "Apr": "04", "May": "05", "Jun": "06", "Jul": "07", "Aug": "08", "Sep": "09", "Oct": "10", "Nov": "11", "Dec": "12"}[v]
			}
		}
		
		; stick everything we parsed out into a YYY-whatever stamp and return it
		YYYYMMDDHH24MISS := DateTime.Year DateTime.Month DateTime.DayOfMonth DateTime.Hour DateTime.Minute DateTime.Second
		return (YYYYMMDDHH24MISS ? YYYYMMDDHH24MISS : 0)
	}
}
class CachedHTTPRequest {
	__New(Method, URL, Headers, Body, Response, Expire) {
		this.Method := Method
		this.URL := URL
		this.Headers := Headers
		this.Body := Body
		this.Response := Response
		this.Expire := Expire
	}
}

#Include <AHKsock>
#Include <AHKhttp>
#Include <json>