import 'dart:io' show Platform;

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'settings_store.dart';
import 'surprise/surprise.dart';

/// Thin layer over the `alarm` plugin. Dawnbox uses one alarm id and
/// re-arms it for the next day every time it is stopped.
class AlarmService {
  static const alarmId = 1;

  /// Second, one-off alarm a few minutes after waking: "Still sleeping?".
  static const checkInId = 2;
  static const checkInDelay = Duration(minutes: 2);

  /// Next time [t] happens after [now]: today if still ahead, else tomorrow.
  /// Built from calendar fields, so daylight-saving changes don't shift it.
  static DateTime nextOccurrence(TimeOfDay t, DateTime now) {
    final today = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    if (today.isAfter(now)) return today;
    return DateTime(now.year, now.month, now.day + 1, t.hour, t.minute);
  }

  static AlarmSettings _settings(DateTime when, {int snoozeMinutes = 5, Lang lang = Lang.en, AlarmSound sound = AlarmSound.chime}) => AlarmSettings(
        id: alarmId,
        dateTime: when,
        assetAudioPath: sound.asset,
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: Platform.isIOS,
        androidFullScreenIntent: true,
        // Not const: the plugin checks the volume range when it builds this.
        volumeSettings: VolumeSettings.fade(
          fadeDuration: const Duration(seconds: 10),
          volume: 0.8,
        ),
        // Snooze straight from the lock-screen notification (Android).
        androidSnoozeDuration: Duration(minutes: snoozeMinutes),
        notificationSettings: NotificationSettings(
          // Tapping the notification opens the ringing screen, even on a
          // locked phone (see setup/MainActivity.kt), with Start surprise.
          title: tr(lang, 'Good morning! Tap to start your surprise', 'Guten Morgen! Tippe für deine Überraschung'),
          body: tr(lang, 'Or use Stop or Snooze below.', 'Oder unten Stopp oder Schlummern wählen.'),
          stopButton: tr(lang, 'Stop', 'Stopp'),
          androidSnoozeButton: tr(lang, 'Snooze', 'Schlummern'),
        ),
      );

  /// Arms (or disarms) the daily alarm from the saved settings.
  static Future<void> scheduleDaily(SettingsStore store) async {
    if (!store.alarmEnabled) {
      await Alarm.stop(alarmId);
      return;
    }
    final when = nextOccurrence(store.alarmTime, DateTime.now());
    await Alarm.set(alarmSettings: _settings(when, snoozeMinutes: store.snoozeMinutes, lang: store.lang, sound: store.alarmSound));
  }

  /// Re-arms tomorrow's alarm if it is on but nothing is scheduled, e.g.
  /// after it was stopped from the notification.
  static Future<void> ensureScheduled(SettingsStore store) async {
    if (!store.alarmEnabled) return;
    if (await Alarm.getAlarm(alarmId) != null) return;
    await scheduleDaily(store);
  }

  /// Stops the ringing alarm and arms tomorrow's.
  static Future<void> stopAndRearm(SettingsStore store) async {
    await Alarm.stop(alarmId);
    await scheduleDaily(store);
  }

  /// Silences the alarm and rings again in a few minutes. No surprise yet.
  static Future<void> snooze(SettingsStore store) async {
    await Alarm.stop(alarmId);
    final when = DateTime.now().add(Duration(minutes: store.snoozeMinutes));
    await Alarm.set(alarmSettings: _settings(when, snoozeMinutes: store.snoozeMinutes, lang: store.lang, sound: store.alarmSound));
  }

  /// Schedules the check-in. It starts very quietly (a gentle nudge) and
  /// after 30 seconds without a tap it rings at full volume.
  static Future<void> scheduleCheckIn(SettingsStore store) async {
    final de = store.lang == Lang.de;
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: checkInId,
        dateTime: DateTime.now().add(checkInDelay),
        assetAudioPath: store.alarmSound.asset,
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: Platform.isIOS,
        androidFullScreenIntent: true,
        allowAlarmOverlap: true,
        volumeSettings: VolumeSettings.staircaseFade(
          volume: 0.8,
          fadeSteps: [
            VolumeFadeStep(Duration.zero, 0.15),
            VolumeFadeStep(const Duration(seconds: 30), 0.15),
            VolumeFadeStep(const Duration(seconds: 31), 1.0),
          ],
        ),
        notificationSettings: NotificationSettings(
          title: de ? 'Schläfst du noch?' : 'Still sleeping?',
          body: de ? 'Wenn nicht, tippe hier.' : 'If not, tap here.',
          stopButton: de ? 'Ich bin wach' : "I'm up",
        ),
      ),
    );
  }

  /// For testing on the phone: ring a few seconds from now.
  static Future<void> ringIn(SettingsStore store, Duration delay) => Alarm.set(
      alarmSettings: _settings(DateTime.now().add(delay), lang: store.lang, sound: store.alarmSound));

  /// Notification permission everywhere, exact alarms on Android 12+.
  static Future<void> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    if (Platform.isAndroid && await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }
}
