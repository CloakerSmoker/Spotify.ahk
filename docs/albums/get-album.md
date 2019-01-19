# Getting An Album By ID
Wraps around [this](https://developer.spotify.com/documentation/web-api/reference/albums/get-album/) Spotify API endpoint
## How to use
After creating a `Spotify` object, you can use `.Albums.GetAlbum()` to get a album by its [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids).

This will return an [Album Object](album-object.md) which can then be used for the methods outlined on [this](album-object.md) page.

## Example
This example will:

A) Create a `Spotify` object (which will prompt the user for authorization if it is not already done) 

B) Get a album with `.Albums.GetAlbum()` by the album's [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids)

C) Save the album
```
Spoofy := new Spotify()
GoodAlbumIMO := Spoofy.Albums.GetAlbum("7xuWUPvk8Xb042QUigdIrE")
GoodAlbumIMO.Save()
```