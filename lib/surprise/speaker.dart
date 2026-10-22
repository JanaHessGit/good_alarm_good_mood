import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

/// Reads surprises aloud with the phone's built-in text-to-speech.
///
/// To sound less robotic it:
/// - picks the highest-quality English voice installed on the phone,
/// - speaks at normal speed,
/// - reads sentence by sentence with a short breath in between.
class Speaker {
  Speaker._();

  /// One voice for the whole app, loaded at startup so it speaks at once.
  static final shared = Speaker._();

  final FlutterTts _tts = FlutterTts();
  Future<void>? _ready;
  int _run = 0; // bumped on every new say() or stop(), cancels older ones

  /// Completes when the voice has really finished the current sentence.
  Completer<void>? _sentenceDone;

  void _finished() {
    final d = _sentenceDone;
    if (d != null && !d.isCompleted) d.complete();
  }

  Future<void> warmUp() => _init();

  Future<void> _init() => _ready ??= _setUp().catchError((_) {});

  Future<void> _setUp() async {
    await _tts.awaitSpeakCompletion(true);
    _tts.setCompletionHandler(_finished);
    _tts.setCancelHandler(_finished);
    _tts.setErrorHandler((_) => _finished());
    await _tts.setLanguage(_wantGerman ? 'de-DE' : 'en-US'); // follows the chosen language
    await _tts.setSpeechRate(0.5); // 0.5 is the phone's normal speed
    await _tts.setPitch(1.0);
    await _pickBestVoice();
  }

  /// The voice the user picked (saved in settings). Set before warmUp().
  VoiceOption? preferred;

  /// Language to speak when no voice was picked. Set before warmUp().
  bool german = false;

  bool get _wantGerman => preferred?.isGerman ?? german;

  /// Called when the user changes the app language.
  Future<void> switchLanguage({required bool german}) async {
    this.german = german;
    if (preferred != null && preferred!.isGerman != german) preferred = null;
    await _init();
    await _pickBestVoice();
  }

  /// All offline English and German voices on this phone, best quality first.
  /// Network voices are left out so the alarm still talks without internet.
  Future<List<VoiceOption>> availableVoices() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return const [];
      final voices = <VoiceOption>[];
      for (final v in raw) {
        if (v is! Map) continue;
        final voice = v.map((k, value) => MapEntry('$k', '$value'));
        final name = voice['name'];
        final locale = voice['locale'];
        if (name == null || locale == null) continue;
        final l = locale.toLowerCase();
        if (!l.startsWith('en') && !l.startsWith('de')) continue;
        if ((voice['features'] ?? '').contains('notInstalled')) continue;
        if (voice['network_required'] == '1') continue;
        voices.add(VoiceOption(name, locale, _qualityRank(voice['quality'])));
      }
      voices.sort((a, b) {
        if (a.isGerman != b.isGerman) return a.isGerman ? 1 : -1; // English first
        final q = b.quality.compareTo(a.quality);
        return q != 0 ? q : a.name.compareTo(b.name);
      });
      return voices;
    } catch (_) {
      return const [];
    }
  }

  /// Uses the picked voice if it's still installed, else the best one.
  Future<void> _pickBestVoice() async {
    final voices = await availableVoices();
    if (voices.isEmpty) return; // keep the phone's default voice
    final want = preferred;
    final sameLanguage = voices.where((v) => v.isGerman == _wantGerman);
    final chosen = voices.firstWhere(
      (v) => want != null && v.name == want.name && v.locale == want.locale,
      orElse: () => sameLanguage.isNotEmpty ? sameLanguage.first : voices.first,
    );
    await _apply(chosen);
  }

  Future<void> _apply(VoiceOption v) async {
    try {
      await _tts.setLanguage(v.isGerman ? 'de-DE' : 'en-US');
      await _tts.setVoice({'name': v.name, 'locale': v.locale});
    } catch (_) {}
  }

  /// Switches voice right away (used by the voice picker).
  Future<void> useVoice(VoiceOption v) async {
    preferred = v;
    await _init();
    await _apply(v);
  }

  static int _qualityRank(String? q) => switch (q) {
        'premium' => 5, // iOS
        'very high' || 'enhanced' => 4,
        'high' => 3,
        'normal' || 'default' => 2,
        'low' => 1,
        _ => 0,
      };

  /// Speaks [text]. Returns true if it was read to the end, false if it was
  /// interrupted by stop() or another say().
  Future<bool> say(String text) async {
    await _init();
    final run = ++_run;
    await _tts.stop();
    for (final sentence in splitSentences(text)) {
      if (run != _run) return false;
      final done = _sentenceDone = Completer<void>();
      final result = await _tts.speak(sentence);
      // Some phones return from speak() before the voice is done. Wait for
      // the "finished" signal too, so pauses really start after speaking.
      if (result == 1) {
        await done.future.timeout(const Duration(seconds: 60), onTimeout: () {});
      }
      if (run != _run) return false;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return run == _run;
  }

  Future<void> stop() async {
    _run++;
    _finished();
    await _tts.stop();
  }

  /// Splits at . ! ? but not after short words like "Mr." or initials "J.".
  static List<String> splitSentences(String text) {
    final parts = <String>[];
    var start = 0;
    for (final m in RegExp(r'[.!?]\s+').allMatches(text)) {
      final lastWord = text.substring(start, m.start).split(RegExp(r'\s+')).last;
      if (lastWord.length <= 2) continue;
      parts.add(text.substring(start, m.end).trim());
      start = m.end;
    }
    final rest = text.substring(start).trim();
    if (rest.isNotEmpty) parts.add(rest);
    return parts;
  }
}

/// One installed voice. [label] turns names like "en-gb-x-gba-local" into
/// something readable.
class VoiceOption {
  const VoiceOption(this.name, this.locale, [this.quality = 0]);

  final String name;
  final String locale;
  final int quality;

  bool get isGerman => locale.toLowerCase().startsWith('de');

  String get region {
    final l = locale.toLowerCase();
    if (isGerman) {
      if (l.contains('at')) return 'Deutsch (Österreich)';
      if (l.contains('ch')) return 'Deutsch (Schweiz)';
      return 'Deutsch';
    }
    if (l.contains('gb')) return 'British';
    if (l.contains('au')) return 'Australian';
    if (l.contains('in')) return 'Indian';
    if (l.contains('ie')) return 'Irish';
    if (l.contains('za')) return 'South African';
    if (l.contains('ng')) return 'Nigerian';
    if (l.contains('ca')) return 'Canadian';
    return 'American';
  }

  /// Short code that tells two voices of the same region apart, e.g. "gba".
  String get code {
    final parts = name.split(RegExp(r'[-_#]'));
    return parts.length >= 4 ? parts[3] : name;
  }

  String get label => isGerman ? '$region · $code' : '$region English · $code';
}
