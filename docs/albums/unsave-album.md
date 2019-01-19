# Un-Saving An Album
Wraps around [this](https://developer.spotify.com/documentation/web-api/reference/library/remove-tracks-user/) Spotify API endpoint
## How to use
After creating a `Spotify` object, and getting a album through either [`.Albums.GetAlbumk()`](get-album.md) or any other function/object which contains/returns album objects, the `.UnSave()` method of the album object can be used. 

`.UnSave()` expects no parameters and will remove a album from the current user's `Your Music` library.

## Example
This example will:

A) Create a `Spotify` object (which will prompt the user for authorization if it is not already done) 

B) Get an album with [`.Albums.GetAlbum()`](get-album.md) by the album's [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids)

C) Save the album

D) Wait 20 seconds, then un-save the album
```
Spoofy := new Spotify()
GoodAlbumIMO := Spoofy.Albums.GetAlbum("7xuWUPvk8Xb042QUigdIrE")
GoodAlbumIMO.Save()
Sleep, 20000
GoodAlbumIMO.UnSave()
```