# Playing An Album
Wraps around [this](https://developer.spotify.com/documentation/web-api/reference/player/start-a-users-playback/) Spotify API endpoint
## Warning
##### ** This method requires Spotify Premium, and will NOT work without Spotify Premium (see [here](https://developer.spotify.com/documentation/web-api/reference/player/start-a-users-playback/#response-format))**
### Note
If an active device is not found, an error about the response status code not being 2xx will be thrown.
## How to use
After creating a `Spotify` object, and getting an album through either [`.Albums.GetAlbum()`](get-album.md) or any other function/object which contains/returns album objects, the `.Play()` method of the returned album object can be used. 

`.Play()` will start playing the album on the active device.

## Example
This example will:

A) Create a `Spotify` object (which will prompt the user for authorization if it is not already done) 

B) Get an album with [`.Albums.GetAlbum()`](get-album.md) by the album's [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids)

C) Play the album
```
Spoofy := new Spotify()
GoodAlbumIMO := Spoofy.Albums.GetAlbum("7xuWUPvk8Xb042QUigdIrE")
GoodAlbumIMO.Play()
```