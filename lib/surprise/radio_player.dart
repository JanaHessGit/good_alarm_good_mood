import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'surprise.dart';

/// Plays a free radio live stream inside the app. Because the app plays it
/// itself (no other app is opened), it also works on a locked phone.
class RadioPlayer {
  RadioPlayer._();

  static final shared = RadioPlayer._();

  /// The station playing right now, or null. The screens listen to this to
  /// show a "Stop radio" button.
  final playing = ValueNotifier<Surprise?>(null);

  AudioPlayer? _player;
  StreamSubscription<void>? _endSub;
  int _run = 0; // bumped by every play()/stop(), cancels older attempts

  /// Plays [station], trying its stream addresses in order. False if none
  /// of them played (no internet, or all addresses down).
  Future<bool> play(Surprise station) async {
    await stop();
    final run = ++_run;
    for (final url in station.streamUrls) {
      if (run != _run) return false;
      final p = AudioPlayer();
      try {
        // Keeps playing with the screen off (holds a wake lock while playing).
        await p.setAudioContext(AudioContextConfig(stayAwake: true).build());
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(1.0);
        await p.play(UrlSource(url)).timeout(const Duration(seconds: 12));
        // Give the stream a moment, then check it really plays.
        await Future<void>.delayed(const Duration(seconds: 2));
        if (run != _run) {
          await p.dispose();
          return false;
        }
        if (p.state == PlayerState.playing) {
          _player = p;
          playing.value = station;
          // A live stream shouldn't end; if the connection drops, reconnect.
          _endSub = p.onPlayerComplete.listen((_) {
            if (run == _run && playing.value == station) play(station);
          });
          return true;
        }
      } catch (_) {
        // This address didn't work: try the next one.
      }
      await p.dispose();
    }
    return false;
  }

  Future<void> stop() async {
    _run++;
    playing.value = null;
    await _endSub?.cancel();
    _endSub = null;
    final p = _player;
    _player = null;
    try {
      await p?.stop();
      await p?.dispose();
    } catch (_) {}
  }
}
