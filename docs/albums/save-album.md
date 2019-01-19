# Saving An Album
Wraps around [this](https://developer.spotify.com/documentation/web-api/reference/library/save-albums-user/) Spotify API endpoint
## How to use
After creating a `Spotify` object, and getting an album through either [`.Albums.GetAlbum()`](get-album.md) or any other function/object which contains/returns album objects, the `.Save()` method of the album object can be used. 

`.Save()` expects no parameters and will save an album to the current user's `Your Music` library.

## Example
This example will:

A) Create a `Spotify` object (which will prompt the user for authorization if it is not already done) 

B) Get a track with [`.Albums.GetAlbum()`](get-album.md) by the album's [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids)

C) Save the album
```
Spoofy := new Spotify()
GoodAlbumIMO := Spoofy.Albums.GetAlbum("7xuWUPvk8Xb042QUigdIrE")
GoodAlbumIMO.Save()
```