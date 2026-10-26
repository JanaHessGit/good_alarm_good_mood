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

  /// While songs play (song surprise or Play some songs): after this long
  /// the songs are paused and the check-in rings. Again after every
  /// "Play some songs" on the check-in.
  static const songsCheckInDelay = Duration(minutes: 10);

  /// Next time [t] happens after [now]: today if still ahead, else tomorrow.
  /// Built from calendar fields, so daylight-saving changes don't shift it.
  static DateTime nextOccurrence(TimeOfDay t, DateTime now) {
    final today = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    if (today.isAfter(now)) return today;
    return DateTime(now.year, now.month, now.day + 1, t.hour, t.minute);
  }

  static AlarmSettings _settings(DateTime when, {int snoozeMinutes = 5, Lang lang = Lang.en, AlarmSound sound = AlarmSound.piano, bool fullVolume = false}) => AlarmSettings(
        id: alarmId,
        dateTime: when,
        assetAudioPath: sound.asset,
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: Platform.isIOS,
        androidFullScreenIntent: true,
        // Not const: the plugin checks the volume range when it builds this.
        volumeSettings: fullVolume
            // Not const: the plugin checks the volume range when it builds this.
            ? VolumeSettings.fixed(volume: 1.0)
            : VolumeSettings.fade(
                fadeDuration: const Duration(seconds: 10),
                volume: 0.8,
              ),
        // Needed for the notification's second button ("Surprise me").
        androidSnoozeDuration: Duration(minutes: snoozeMinutes),
        notificationSettings: NotificationSettings(
          // Tapping the notification or "Surprise me" opens the app and
          // starts the surprise. "Surprise me" works without unlocking
          // (packages/alarm, DawnboxActionReceiver).
          title: tr(lang, 'Good morning!', 'Guten Morgen!'),
          body: tr(lang, 'Tap here for your surprise.', 'Tippe hier für deine Überraschung.'),
          stopButton: tr(lang, 'Stop', 'Stopp'),
          // Shown as "Surprise me": in Dawnbox's copy of the plugin this
          // button starts the surprise instead of snoozing.
          androidSnoozeButton: tr(lang, 'Surprise me', 'Überrasch mich'),
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
  static Future<void> scheduleCheckIn(SettingsStore store, {Duration delay = checkInDelay}) async {
    final de = store.lang == Lang.de;
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: checkInId,
        dateTime: DateTime.now().add(delay),
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
          stopButton: de ? 'Ich bin wach' : 'I am awake',
          // Second button: opens the app, which starts the radio
          // (packages/alarm, DawnboxActionReceiver).
          androidSnoozeButton: de ? 'Radio abspielen' : 'Play radio',
        ),
        // Needed so the plugin accepts the second button.
        androidSnoozeDuration: const Duration(minutes: 5),
      ),
    );
  }

  /// Nobody reacted to the surprise: ring again in 2 seconds, at full
  /// volume and without fade-in, with Surprise me / Stop as usual.
  /// (Replaces tomorrow's alarm for now; it is re-armed once this one ends.)
  static Future<void> ringAgain(SettingsStore store) => Alarm.set(
      alarmSettings: _settings(DateTime.now().add(const Duration(seconds: 2)),
          snoozeMinutes: store.snoozeMinutes, lang: store.lang, sound: store.alarmSound, fullVolume: true));

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
