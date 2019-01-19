# Playlist Objects
Wrap around [this](https://developer.spotify.com/documentation/web-api/reference/object-model/#playlist-object-full) Spotify API object model.
### Note
Playlist objects should only be created with [`.Playlists.GetPlaylist()`](get-playlist.md)/[`.Playlists.CreatePlaylist()`](create.md) unless they are returned by, or included in other objects.
## Properties
| **Key**     |                                                **Value description**                                         |
|-------------|--------------------------------------------------------------------------------------------------------------|
| description | The description of the the playlist                                                                          |
| id          | The [Spotify ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids) of the playlist  |
| name        | The name of the playlist                                                                                     |
| uri         | The [Spotify URI](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids) of the playlist |
| owner       | A [User Object](/users/user-obj/) representing the owner of the playlist                                     |
| public      | If the playlist is public or not (true/false)                                                                |
| tracks      | An array of [Track Objects](../tracks/track-object.md) that are in the playlist                                     |

## Methods
| **Definition** |                                                 **Description**                                           |
|----------------|-----------------------------------------------------------------------------------------------------------|
|[`.AddTrack(TrackIDOrTrackOBJ)`](add-tracks.md) | Takes a [Track Object](../tracks/track-object.md) or [Track ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids) and adds it to the playlist |
|[`.RemoveTrack(TrackIDOrTrackOBJ)`](remove-tracks.md) | Takes a [Track Object](../tracks/track-object.md) or [Track ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids) and removes it from the playlist |
|[`.Play()`](play.md) | Plays the playlist on the currently active device |
|[`.Delete()`](delete-playlist.md) | Deletes the playlist |