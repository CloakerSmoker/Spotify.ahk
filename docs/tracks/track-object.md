# Track Objects
Wrap around [this](https://developer.spotify.com/documentation/web-api/reference/object-model/#track-object-full) Spotify API object model.
### Note
Track objects should only be created with [`.Tracks.GetTrack()`](get-track.md) unless they are returned by, or included in other objects.
## Properties
| **Key**     |                                                **Value description**                                         |
|-------------|--------------------------------------------------------------------------------------------------------------|
| album | An [Album Object](../albums/album-object.md) of the album the track is from                                                                          |
| id          | The [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids) of the track  |
| name        | The name of the track                                                                                     |
| uri         | The [Spotify URI](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids) of the track |
| artists       | An array of [Artist Objects](/artists/artist-object.md) that represents the Artist(s) of the track             |
| duration      | The length of the track expressed in milliseconds                                                               |
| explicit      | True/false, if the track is explicit or not                                     |

## Methods
| **Definition** |                                                 **Description**                                           |
|----------------|-----------------------------------------------------------------------------------------------------------|
|[`.Save()`](save-track.md) | Saves a track to the current user's `Your Music` library |
|[`.UnSave()`](unsave-track.md) | Removes a saved track from the current user's `Your Music` library |
|[`.Play()`](play-track.md) | Tries to start playing the track on the active device, will cancel any other playback |