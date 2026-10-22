import 'dart:async';
import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

import '../lock_screen.dart';
import '../spotify_config.dart';
import 'content.dart';
import 'speaker.dart';
import 'surprise.dart';

/// Plays songs in Spotify.
///
/// 1. Preferred: Spotify's "App Remote" connection (needs a Client ID in
///    lib/spotify_config.dart and "Spotify: Connect" once). It tells the
///    Spotify app to play in the background, so it also works on a locked
///    phone, without opening Spotify.
/// 2. Fallback: opens the track in Spotify with its `spotify:track:<id>:play`
///    link. Spotify can't open over the lock screen, so on a locked phone
///    the voice asks to unlock first.
class SongPlayer {
  static const _spotify = 'com.spotify.music';

  /// Spotify's own "Wake Up Happy" playlist (checked on open.spotify.com).
  /// Used for "Play some songs" when the App Remote connection works.
  static const _wakeUpPlaylist = 'spotify:playlist:37i9dQZF1DX0UrRvztWcAU';

  static bool _connected = false;

  /// Connects to the Spotify app. The very first time, Spotify shows a
  /// screen to agree (phone must be unlocked); after that it's silent.
  ///
  /// With [onlyIfConnectedBefore] it does nothing until "Spotify: Connect"
  /// worked once, so the alarm never shows Spotify's agree screen.
  static Future<bool> connect({bool onlyIfConnectedBefore = false}) async {
    if (!Platform.isAndroid || !SpotifyConfig.isSet) return false;
    if (_connected) return true;
    const key = 'spotify_connected_once';
    try {
      final prefs = await SharedPreferences.getInstance();
      if (onlyIfConnectedBefore && !(prefs.getBool(key) ?? false)) return false;
      _connected = await SpotifySdk.connectToSpotifyRemote(
        clientId: SpotifyConfig.clientId,
        redirectUrl: SpotifyConfig.redirectUrl,
      ).timeout(const Duration(seconds: 15));
      if (_connected) await prefs.setBool(key, true);
    } catch (_) {
      _connected = false;
    }
    return _connected;
  }

  /// Plays [uri] through the App Remote connection. False if not set up or
  /// Spotify didn't respond (then the caller falls back to opening Spotify).
  static Future<bool> _remotePlay(String uri) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      if (!await connect(onlyIfConnectedBefore: true)) return false;
      try {
        await SpotifySdk.play(spotifyUri: uri).timeout(const Duration(seconds: 10));
        return true;
      } catch (_) {
        _connected = false; // connection dropped: connect again once
      }
    }
    return false;
  }

  /// Fallback only: Spotify can't open over the lock screen, so the voice
  /// asks to unlock and Android shows the unlock prompt. False if cancelled.
  static Future<bool> _unlockFirst() async {
    if (!await LockScreen.isLocked()) return true;
    final de = Speaker.shared.speaksGerman;
    await Speaker.shared.say(de
        ? 'Entsperre dein Handy, dann startet die Musik.'
        : 'Unlock your phone and the music starts.');
    return LockScreen.requestUnlock();
  }

  /// Returns false if nothing could be played or opened.
  static Future<bool> play(Surprise song) async {
    final id = song.spotifyId;
    if (id != null && await _remotePlay('spotify:track:$id')) return true;
    return _openInSpotify(song);
  }

  static Future<bool> _openInSpotify(Surprise song) async {
    if (!await _unlockFirst()) return false;
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

  /// "Play some songs". With the App Remote connection: the "Wake Up Happy"
  /// playlist, shuffled. Otherwise a random feel-good song from the app's
  /// list, opened in Spotify (Spotify's Autoplay continues after it).
  static Future<bool> playSurpriseSongs() async {
    if (await _remotePlay(_wakeUpPlaylist)) {
      try {
        await SpotifySdk.setShuffle(shuffle: true);
      } catch (_) {}
      return true;
    }
    final songs = starterContent
        .where((s) => s.type == SurpriseType.song && s.spotifyId != null)
        .toList()
      ..shuffle();
    if (songs.isEmpty) return false;
    return _openInSpotify(songs.first);
  }
}
