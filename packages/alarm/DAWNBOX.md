# Dawnbox copy of the `alarm` plugin

This is version 5.15.0 of https://github.com/gdelataillade/alarm (MIT licence,
see LICENSE), with one change in
`android/src/main/kotlin/com/gdelataillade/alarm/services/NotificationService.kt`
(search for "DAWNBOX CHANGE"):

- The notification's second button ("Surprise me") opens the app and starts
  the surprise, instead of snoozing. Its text is the `androidSnoozeButton` label.
- Tapping the notification also starts the surprise.
- The full-screen alarm still opens the ringing screen.

The "Stop" button is unchanged: it only stops the alarm.
