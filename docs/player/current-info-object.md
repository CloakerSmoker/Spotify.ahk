# Current Playback Info Objects
Wrap around [this](https://developer.spotify.com/documentation/web-api/reference/player/get-information-about-the-users-current-playback/#currently-playing-context) Spotify API object model.
### Note
Current Playback Info Objects can **NOT** be created, they are only returned by [`.Player.GetCurrentPlaybackInfo()`](get-current-info.md).
## Properties
| **Key**     |                                                **Value description**                                         |
|-------------|--------------------------------------------------------------------------------------------------------------|
| device | A [Device Object](../devices/device-object.md) of the active device   |
| repeat_state  | The repeat mode of the player, is `off`, `track`, or `context`  |
| shuffle_state        | The shuffle state of the player, is `true` for on, `false` for off  |
| context         | A [Context Object](../contexts/context-object.md) of the current context |
| timestamp       | A Unix Millisecond Timestamp of when this data was fetched            |
| progress_ms      | How many Milliseconds the player is into the current track          |
| is_playing      | True/false is the player playing, or is it paused                     |
| track          | A [Track Object](../tracks/track-object.md) of the currently playing track |