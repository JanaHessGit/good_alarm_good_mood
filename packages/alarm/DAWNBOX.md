# Dawnbox copy of the `alarm` plugin

This is version 5.15.0 of https://github.com/gdelataillade/alarm (MIT licence,
see LICENSE), with these changes (search for "DAWNBOX CHANGE"):

- `services/NotificationService.kt`: the notification's second button uses
  the `androidSnoozeButton` label ("Surprise me" on the alarm, "Play some
  songs" on the check-in) instead of snoozing. It sends a broadcast, which
  works on the lock screen without unlocking.
- `alarm/DawnboxActionReceiver.kt` (new, declared in `AndroidManifest.xml`):
  receives that button and posts a full-screen notification that opens
  Dawnbox over the lock screen at once, with the extra `dawnboxAction=button`.
- Tapping the notification opens Dawnbox with `dawnboxAction=tap`.
- The full-screen alarm still opens the ringing screen.

The "Stop" button is unchanged: it only stops the alarm.
- `alarm/AlarmService.kt`: before an alarm rings, music that is playing
  (e.g. Spotify) gets a "pause" key, so the check-in is heard and the songs
  stop.
- `alarm/AlarmService.kt`: if "Display over other apps" is allowed, the
  alarm screen is also opened directly when an alarm rings, so the phone
  always switches to Dawnbox instead of sometimes only showing the
  notification.
- `services/NotificationService.kt` + `res/layout/dawnbox_alarm_notification.xml`:
  the alarm notification uses a bigger title (26sp) and text (18sp).
