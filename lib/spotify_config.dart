/// Spotify connection for playing songs while the phone is locked.
///
/// Without a client id the app opens Spotify instead, which only plays after
/// the phone is unlocked. To play on a locked phone:
/// 1. developer.spotify.com/dashboard -> Create app. Redirect URI:
///    spotify-sdk://auth . Tick "Android". Add the Android package
///    (com.example.surpise_wake_up) and the SHA-1 fingerprint (see README).
/// 2. Paste the app's Client ID below and build again.
/// 3. In the app, tap "Spotify: Connect" once (Spotify asks you to agree).
class SpotifyConfig {
  static const clientId = ''; // <- paste your Client ID here
  static const redirectUrl = 'spotify-sdk://auth';

  static bool get isSet => clientId.isNotEmpty;
}
