# Album Objects
Wrap around [this](https://developer.spotify.com/documentation/web-api/reference/object-model/#album-object-full) Spotify API object model.
### Note
Album objects should only be created with [`.Albums.GetAlbums()`](get-album.md) unless they are returned by, or included in other objects.
## Properties
| **Key**     |                                                **Value description**                                         |
|-------------|--------------------------------------------------------------------------------------------------------------|
| genres | A string array of genres that fit the album                                                                           |
| id          | The [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids) of the album  |
| name        | The name of the album                                                                                     |
| uri         | The [Spotify URI](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids) of the album |
| artists       | An array of [Artist Objects](/artists/artist-object.md) that represents the Artist(s) of the album             |
| images      | An array of [Spotify Image Objects](https://developer.spotify.com/documentation/web-api/reference/object-model/#image-object)                                                               |
| tracks      | An array of [Track Objects](../tracks/track-object.md) inside the album                                    |

## Methods
| **Definition** |                                                 **Description**                                           |
|----------------|-----------------------------------------------------------------------------------------------------------|
|[`.Save()`](save-album.md) | Saves an album to the current user's `Your Music` library |
|[`.UnSave()`](unsave-album.md) | Removes a saved album from the current user's `Your Music` library |
|[`.Play()`](play-album.md) | Tries to start playing the album on the active device, will cancel any other playback |