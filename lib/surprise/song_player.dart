import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

import 'surprise.dart';

/// Starts today's song in Spotify.
///
/// Spotify ignores Android's general "play this search" command (it only
/// shows search results), so the app opens the exact track with Spotify's
/// own `spotify:track:<id>:play` link, which starts playback.
class SongPlayer {
  static const _spotify = 'com.spotify.music';

  /// Returns false if nothing could be opened.
  static Future<bool> play(Surprise song) async {
    final id = song.spotifyId;

    // 1. Exact track, starts playing (Android + Spotify app installed).
    if (Platform.isAndroid && id != null) {
      try {
        await AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'spotify:track:$id:play',
          package: _spotify,
        ).launch();
        return true;
      } catch (_) {
        // Spotify not installed: fall through.
      }
    }

    // 2. Track page (app or browser), or a search if no id is known.
    final url = id != null
        ? 'https://open.spotify.com/track/$id'
        : 'https://open.spotify.com/search/${Uri.encodeComponent(song.songQuery)}';
    try {
      return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Spotify's own "Wake Up Happy" playlist (checked on open.spotify.com).
  static const surprisePlaylistId = '37i9dQZF1DX0UrRvztWcAU';

  /// "Play surprise songs": starts the upbeat morning playlist in Spotify.
  static Future<bool> playSurpriseSongs() async {
    if (Platform.isAndroid) {
      try {
        await AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'spotify:playlist:$surprisePlaylistId:play',
          package: _spotify,
        ).launch();
        return true;
      } catch (_) {
        // Spotify not installed: fall through.
      }
    }
    try {
      return await launchUrl(
        Uri.parse('https://open.spotify.com/playlist/$surprisePlaylistId'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
