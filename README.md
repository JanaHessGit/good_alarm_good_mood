# Dawnbox: prototype

An alarm clock with a small surprise every morning: a quiz, a song that starts playing in Spotify by itself, a mini challenge, a riddle, or a story read aloud.

**Riddles (Rätsel):** the voice reads a riddle; **Show answer** reveals and says the solution.

**Waking up for real:** a quiz, mini challenge, riddle or story is read out after the greeting and repeated until you tap **I am awake** or **Play surprise songs** (starts Spotify's "Wake Up Happy" playlist). The 20-second pause starts only after the voice has finished speaking. Once a quiz is answered or a riddle solved, an **Are you awake?** pop-up appears at once: **Yes** ends it; **No**, or no tap within 10 seconds after the voice finished, starts the playlist. A song surprise announces its first song and starts playing; Spotify continues with similar songs.

## How it behaves

1. You set a wake-up time on the home screen. The alarm repeats daily.
2. At that time the alarm rings with a gentle chime (`assets/alarm.wav`, made for this project, free to use).
3. The ringing screen (also shown over the lock screen) offers:
   - **Surprise me**: the alarm stops and the surprise starts right away.
   - **Wait 60 seconds**: the same happens on its own.
   - **Stop without surprise**: the alarm stops, no surprise.
   The notification offers the same two buttons. There is no snooze.
4. Songs start playing in Spotify by themselves (exact track via its Spotify id). On a locked phone, Android asks you to unlock first.
5. Every surprise opens with a spoken greeting: "Hello there, it's the morning. I know you want to keep sleeping, but I have a surprise for you to start your day." If you set a name on the home screen, it's added after "Hello there".

Colours: deep royal blue (#213E9A), white and a coral accent (#FF9E8F), defined in `lib/theme.dart`.

## The surprise logic (`lib/surprise/surprise_engine.dart`)

1. Only surprise types you switched on, with at least one item that fits today (weekday or weekend), are candidates.
2. Yesterday's type is left out, so you never get two quotes in a row.
3. A type is drawn at random (equal odds; weights are supported).
4. Inside that type, an unseen item is drawn. Once all have been seen, that type starts over.
5. The pick is saved immediately, so restarting the app can't repeat it.

"Another one" simply draws again, which by rule 2 gives a different type.

Content lives in `lib/surprise/content.dart`. Add items there, each with a unique id.

## Newer features

- **Wake-up song:** the alarm sound is 20 seconds of chime, then an upbeat original tune (`assets/alarm_*.mp3`, made by `tools/make_alarm_sound.py`, free to use). To use a song you own instead: `python3 tools/make_alarm_sound.py my_song.mp3`.
- **Show surprise after 60 s** of ringing (so the song has time to play), or tap the button any time.
- **Check-in:** 2 minutes after the alarm is stopped, a second alarm asks "Still sleeping? If not, tap here." It starts very quietly; after 30 seconds without a tap it rings at full volume.
- **Feedback:** 20 minutes after waking, a notification asks "Hey Jana! How did you wake up today?" plus a question about the surprise (song, challenge, story or quiz). Tapping it opens a short pop-up; answers are saved on the phone.

### Extra Android setup for the feedback notification

1. Use `setup/AndroidManifest.xml` (it now includes two notification receivers).
2. In `android/app/build.gradle.kts`, inside `android { ... }`, add to `compileOptions`: `isCoreLibraryDesugaringEnabled = true`, and at the end of the file:

```kotlin
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```
- **Language:** EN / DE switch at the top of the home screen. It changes the app texts, the voice, everything spoken (greeting, quizzes, challenges, stories) and the notifications.
- **Voices:** pick any installed voice of the chosen language.
- **Alarm sounds:** Chime, Marimba or Soft piano (each followed by the wake-up song after 20 s), or a Classic beep without song. Preview them in the app. Regenerate with `python3 tools/make_alarm_sound.py` (optionally with your own song file).

## Lock screen setup (Android)

When the alarm rings on a locked phone, the notification has two buttons: **Surprise me** and **Stop**.
- **Surprise me**, or a tap on the notification itself, opens Dawnbox over the lock screen and starts the surprise right away.
- **Stop** only stops the alarm. No surprise.
- If the full-screen alarm is allowed, Dawnbox's ringing screen appears instead, with the same choices: Surprise me or Stop without surprise.

This needs Dawnbox's own copy of the alarm plugin in `packages/alarm` (see `packages/alarm/DAWNBOX.md`).

- Replace `android/app/src/main/AndroidManifest.xml` with `setup/AndroidManifest.xml` (it declares MainActivity as the alarm screen).
- Replace `android/app/src/main/kotlin/.../MainActivity.kt` with `setup/MainActivity.kt` (keep your own `package` line).
- Android 14+: allow *Full screen notifications* for the app. The home screen shows a button if it's off.

## Run it

You need Flutter installed (https://docs.flutter.dev/get-started/install) and a real phone. Alarms don't work reliably in emulators.

```bash
cd dawnbox
flutter create . --platforms=android,ios --org com.example   # adds the android/ and ios/ folders, keeps lib/
flutter pub get
flutter test                                               # checks the surprise logic
```

### Android (easiest, start here)

1. In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`, above `<application>`:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW"/>
    <data android:scheme="https"/>
  </intent>
</queries>
```

2. In `android/app/build.gradle` (or `build.gradle.kts`), make sure `minSdk` is at least 23.
3. Plug in your phone with USB debugging on, then `flutter run`.
4. Tap **Test: ring in 10 seconds** to try the whole flow without waiting until morning.

Some phones (Samsung, Xiaomi, Huawei, Oppo) kill background apps aggressively. If the alarm doesn't show full screen, allow "autostart" and turn off battery optimisation for Dawnbox.

### iPhone

1. Open `ios/Runner.xcworkspace` in Xcode. Under Runner, Signing & Capabilities, add **Background Modes** and tick **Audio, AirPlay, and Picture in Picture** and **Background fetch**.
2. In `ios/Runner/Info.plist`, add:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
  <string>com.gdelataillade.fetch</string>
</array>
```

3. In `ios/Runner/AppDelegate.swift`, add `import alarm` at the top and, inside `application(_:didFinishLaunchingWithOptions:)`:

```swift
SwiftAlarmPlugin.registerBackgroundTasks()
```

4. Set the iOS deployment target to 13.0 or higher, then `flutter run` on your iPhone.

**iPhone limitation:** this prototype uses the `alarm` plugin, which keeps the app alive in the background to ring. If you swipe Dawnbox away in the app switcher, the alarm won't ring (you get a warning notification instead). A store version should switch to Apple's AlarmKit (iOS 26+), which rings like the Clock app even when the app is closed.

## Files

| File | What it does |
| --- | --- |
| `lib/main.dart` | Starts the app, opens the ringing screen when an alarm fires |
| `lib/alarm_service.dart` | Schedules and re-arms the daily alarm |
| `lib/settings_store.dart` | Saves time, on/off, chosen types and surprise history |
| `lib/screens/home_screen.dart` | Time, on/off switch, surprise types, test buttons |
| `lib/screens/ring_screen.dart` | Ringing screen with the 30-second countdown |
| `lib/screens/surprise_screen.dart` | Shows and reads out the surprise |
| `lib/surprise/` | Content, the picking logic and text-to-speech |
| `test/surprise_engine_test.dart` | Tests for the picking rules |

## Next steps

- Switch the iPhone version to AlarmKit.
- German content and voice (`Speaker` uses `en-US`; set `de-DE`).
- Weather- and season-aware picks.
- An evening check-in: "Did you do today's challenge?"
