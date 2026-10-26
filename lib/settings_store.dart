import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'surprise/speaker.dart';
import 'surprise/surprise.dart';
import 'surprise/surprise_engine.dart';

/// Everything the user sets, plus the surprise history. Saved on the phone.
class SettingsStore extends ChangeNotifier {
  SettingsStore._(this._prefs);

  static Future<SettingsStore> load() async =>
      SettingsStore._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _kHour = 'alarm_hour';
  static const _kMinute = 'alarm_minute';
  static const _kEnabled = 'alarm_enabled';
  static const _kTypes = 'enabled_types';
  static const _kTypesKnown = 'types_known';
  static const _kHistory = 'surprise_history';
  static const _kAutoSeconds = 'auto_surprise_seconds';
  static const _kSnoozeMinutes = 'snooze_minutes';
  static const _kName = 'user_name';
  static const _kVoice = 'voice';
  static const _kFeedback = 'feedback';
  static const _kLang = 'language';
  static const _kSound = 'alarm_sound';

  TimeOfDay get alarmTime => TimeOfDay(
        hour: _prefs.getInt(_kHour) ?? 7,
        minute: _prefs.getInt(_kMinute) ?? 0,
      );

  Future<void> setAlarmTime(TimeOfDay t) async {
    await _prefs.setInt(_kHour, t.hour);
    await _prefs.setInt(_kMinute, t.minute);
    notifyListeners();
  }

  /// Used in the spoken greeting. Empty means "Good morning" without a name.
  String get userName => _prefs.getString(_kName) ?? '';

  Future<void> setUserName(String name) async {
    await _prefs.setString(_kName, name.trim());
    notifyListeners();
  }

  bool get alarmEnabled => _prefs.getBool(_kEnabled) ?? false;

  Future<void> setAlarmEnabled(bool on) async {
    await _prefs.setBool(_kEnabled, on);
    notifyListeners();
  }

  /// Seconds of ringing before the surprise starts on its own.
  int get autoSurpriseSeconds => _prefs.getInt(_kAutoSeconds) ?? 40;

  /// Seconds of alarm chime before the wake-up song takes over (built into
  /// assets/alarm.wav, so keep the two in sync).
  static const songAfterSeconds = 20;

  int get snoozeMinutes => _prefs.getInt(_kSnoozeMinutes) ?? 5;

  Set<SurpriseType> get enabledTypes {
    final names = _prefs.getStringList(_kTypes);
    if (names == null) return SurpriseType.values.toSet();
    // Types that existed when the choice was saved. Newer ones start on.
    final known = _prefs.getStringList(_kTypesKnown) ?? const ['quiz', 'song', 'challenge', 'adventure', 'story'];
    final types = SurpriseType.values
        .where((t) =>
            names.contains(t.name) ||
            !known.contains(t.name) ||
            // 'adventure' is the old name of 'challenge'.
            (t == SurpriseType.challenge && names.contains('adventure')))
        .toSet();
    // Saved by an older version with types that no longer exist: use all.
    return types.isEmpty ? SurpriseType.values.toSet() : types;
  }

  /// The chosen voice, or null for "best available".
  VoiceOption? get voice {
    final v = _prefs.getStringList(_kVoice);
    if (v == null || v.length != 2) return null;
    return VoiceOption(v[0], v[1]);
  }

  /// App and voice language, chosen by the user. Before a choice is made,
  /// it follows the voice (German voice, German texts).
  Lang get lang {
    final saved = _prefs.getString(_kLang);
    for (final l in Lang.values) {
      if (l.name == saved) return l;
    }
    return (voice?.isGerman ?? false) ? Lang.de : Lang.en;
  }

  /// Switches language. A saved voice of the other language is dropped, so
  /// the best voice of the new language is used until the user picks one.
  Future<void> setLang(Lang l) async {
    await _prefs.setString(_kLang, l.name);
    final v = voice;
    if (v != null && v.isGerman != (l == Lang.de)) await _prefs.remove(_kVoice);
    notifyListeners();
  }

  AlarmSound get alarmSound {
    final saved = _prefs.getString(_kSound);
    return AlarmSound.values.firstWhere((s) => s.name == saved, orElse: () => AlarmSound.piano); // default: Soft piano + song
  }

  /// Redraws the screens (e.g. after the radio station changed).
  void refresh() => notifyListeners();

  Future<void> setAlarmSound(AlarmSound s) async {
    await _prefs.setString(_kSound, s.name);
    notifyListeners();
  }

  Future<void> setVoice(VoiceOption v) async {
    await _prefs.setStringList(_kVoice, [v.name, v.locale]);
    notifyListeners();
  }

  /// Morning feedback answers, newest last (kept on the phone only).
  List<Map<String, dynamic>> get feedback => (_prefs.getStringList(_kFeedback) ?? const [])
      .map((e) => jsonDecode(e) as Map<String, dynamic>)
      .toList();

  Future<void> addFeedback(Map<String, dynamic> entry) async {
    final list = _prefs.getStringList(_kFeedback) ?? <String>[];
    list.add(jsonEncode(entry));
    await _prefs.setStringList(_kFeedback, list);
  }

  Future<void> toggleType(SurpriseType type) async {
    final types = enabledTypes;
    if (types.contains(type)) {
      if (types.length == 1) return; // keep at least one
      types.remove(type);
    } else {
      types.add(type);
    }
    await _prefs.setStringList(_kTypes, types.map((t) => t.name).toList());
    await _prefs.setStringList(_kTypesKnown, SurpriseType.values.map((t) => t.name).toList());
    notifyListeners();
  }

  SurpriseHistory get history =>
      SurpriseHistory.fromJson(_prefs.getString(_kHistory));

  Future<void> saveHistory(SurpriseHistory h) =>
      _prefs.setString(_kHistory, h.toJson());
}

/// Alarm sounds in assets/ (made by tools/make_alarm_sound.py). All but the
/// beep switch to the wake-up song after 20 seconds.
enum AlarmSound {
  chime('Chime + song', 'Glocken + Song'),
  marimba('Marimba + song', 'Marimba + Song'),
  piano('Soft piano + song', 'Sanftes Klavier + Song'),
  beep('Classic beep (no song)', 'Klassisches Piepen (ohne Song)');

  const AlarmSound(this.en, this.de);
  final String en;
  final String de;

  String label(Lang l) => tr(l, en, de);
  String get asset => 'assets/alarm_$name.mp3';
  bool get hasSong => this != AlarmSound.beep;
}
