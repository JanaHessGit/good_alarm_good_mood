import 'package:audioplayers/audioplayers.dart';

/// Light "thinking" music (assets/quiz_wait.mp3, a 20-second loop) that
/// plays while a quiz, riddle or mini challenge waits for a tap. It only plays in the
/// pauses: it is stopped before the voice speaks again.
class WaitingMusic {
  WaitingMusic._();

  static final shared = WaitingMusic._();

  AudioPlayer? _player;
  bool _on = false;

  /// Starts the loop. Returns an error text if it couldn't play, else null.
  Future<String?> start() async {
    if (_on) return null;
    _on = true;
    try {
      // A fresh player each time: a player left in an error state can't
      // be reused reliably.
      await _player?.dispose();
      final p = _player = AudioPlayer();
      // Keep playing when the screen turns off (holds a wake lock while
      // the music plays).
      await p.setAudioContext(AudioContextConfig(stayAwake: true).build());
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(0.8);
      await p.setSource(AssetSource('quiz_wait.mp3')); // relative to assets/
      if (!_on) return null; // stopped while it was loading
      await p.resume();
      return null;
    } catch (e) {
      _on = false;
      return '$e';
    }
  }

  Future<void> stop() async {
    _on = false;
    try {
      await _player?.stop();
    } catch (_) {}
  }
}
