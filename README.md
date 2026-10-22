# Rise & Surprise

*(Code name and project folder: `dawnbox`.)*

An alarm clock that gets you up with a small surprise every morning: a quiz, a song, a mini challenge or a riddle, read aloud in English or German.

Android first. An iPhone build works with limits (see the end).

---

## App logic at a glance

```
Alarm rings (music that's playing is paused; sound fades in, wake-up song after 20 s)
│
├─ Stop / Stop without surprise ──► alarm off. No surprise, no check-in, no feedback.
│
├─ Surprise me / tap on the notification / 40 s without a tap
│        │
│        ▼
│   Greeting + surprise read aloud (screen stays on until "I am awake")
│        │
│        ├─ Song ───────────────► song announced, plays in Spotify (also on a locked phone*)
│        │                        after 10 min: music paused, check-in
│        │
│        └─ Quiz, mini challenge, riddle
│                 │  30 s waiting music after the voice finishes, then repeated,
│                 │  until one of these is tapped:
│                 ├─ I am awake ─────► done (no check-in)
│                 ├─ Play some songs ► songs in Spotify*, after 10 min: check-in
│                 ├─ quiz answered / riddle solved
│                 │        ▼
│                 │   "Are you awake?" pop-up
│                 │     ├─ Yes ─────────────────────► done (no check-in)
│                 │     └─ No, or 10 s without a tap ► like Play some songs
│                 └─ no tap at all after 4 repeats ► alarm rings again, loud (start over)
│
└─ Check-in "Still sleeping? If not, tap here." (only after songs)
     ├─ I am awake ─────► done, no more check-ins
     └─ Play some songs ► songs again, check-in again after 10 min (repeats)

Feedback notification about 20 minutes after a surprise started.
* On a locked phone only with the Spotify connection set up (see "Spotify setup").
```

---

## 1. The alarm

- You set one wake-up time on the home screen. It repeats every day and is re-armed automatically after each ring.
- **When it rings,** any music that's playing (e.g. Spotify) is paused.
- **Sound:** Soft piano + song by default. Choose Chime, Marimba or Soft piano (each switches to an upbeat wake-up song after 20 seconds), or Classic beep (no song). The volume fades in over 10 seconds. You can preview every sound in the app.
- **The ringing screen** opens over the lock screen (and the screen stays on):
  - **Surprise me**: the alarm stops and the surprise starts.
  - **Stop without surprise**: the alarm stops. No surprise, no check-in, no feedback.
  - **No tap for 40 seconds**: the surprise starts by itself.
- **If only the notification shows** (it's now bigger, with a large title):
  - **Surprise me** / *Überrasch mich*: opens the app over the lock screen without unlocking; the surprise starts.
  - **Stop** / *Stopp*: only stops the alarm. No surprise, no check-in, no feedback.
  - Tapping the notification text also starts the surprise, but Android may ask you to unlock first.
- There is no snooze.

## 2. The surprise

- **The screen stays on** (the phone can't lock again) until you tap **I am awake** (or **Yes** in the pop-up). The processor is also kept awake (WakeLock, at most 30 minutes), so the voice, the waiting music and the Spotify call keep running even if the screen is switched off with the power button. The alarms themselves are scheduled with Android's exact AlarmManager, so they wake the phone on time.

**Picking.** Every morning one surprise is drawn at random (`lib/surprise/surprise_engine.dart`):
1. Only the types you switched on in the home screen are used.
2. The same type never comes twice in a row.
3. Within a type, every item is used once before any repeats.
4. Some mini challenges fit only weekdays or only weekends.
5. The pick is saved at once, so restarting the app can't repeat it.

**Greeting.** Every surprise starts with a spoken greeting:
- English: *"Hello there, Jana, it's the morning. I know you want to keep sleeping, but I have a surprise for you to start your day."*
- German: *"Hallooooooo Jana, es ist Zeit zum Aufstehen. Ich weiß, du willst wahrscheinlich lieber weiterschlafen, aber ich habe eine Überraschung für dich, mit der dein Tag gut beginnt."*

Then: *"Your surprise is …"* plus the surprise itself.

**The four types:**

| Type | What happens |
| --- | --- |
| **Quiz** (12) | A question with three answers (A, B, C). After answering: right or wrong, plus a fun fact. |
| **Song** (9) | The song is announced, then plays in Spotify (no buttons). After 10 minutes the music is paused and the check-in rings. |
| **Mini challenge** (19) | A small task, e.g. "Get up and drink a full glass of water" or "Take a different route to work today". |
| **Riddle / Rätsel** (12) | A riddle. **Show answer** reveals the solution and reads it out. |

**Making sure you're really awake** (quiz, mini challenge, riddle):
- After the voice has finished, **30 seconds of waiting music** play (`assets/quiz_wait.mp3`), then the voice repeats the greeting and the surprise.
- The repeats stop when you tap:
  - **I am awake**: "Great, you're awake!" Done, no check-in. **Start my day** then closes the screen.
  - **Play some songs** / *Spiel ein paar Songs*: songs play in Spotify; after 10 minutes they're paused and the check-in rings.
- When a quiz is answered or a riddle solved, an **Are you awake?** pop-up appears at once while the voice reads the result:
  - **Yes:** done, no check-in.
  - **No**, or no tap within 10 seconds after the voice finished: exactly like **Play some songs**.
- **Nobody reacts at all?** After the first reading plus 4 repeats (about 4 minutes), the surprise closes and the alarm rings again at full volume, with **Surprise me** / **Stop**. Then everything starts over. (Only for alarms, not for "Try a surprise now".)

## 3. After waking up

- **Check-in "Still sleeping?"** only follows songs (song surprise, Play some songs, No / no answer in the pop-up), each time 10 minutes after the songs started:
  - Spotify is paused. The alarm sound starts quietly and rings at full volume after 30 seconds. The voice asks once: *"Still sleeping? If not, tap here."* The screen stays on.
  - **I am awake** (app or lock-screen notification): done, no more check-ins.
  - **Play some songs**: songs again, and 10 minutes later the check-in comes back. This repeats until you tap I am awake.
  - No tap: it keeps ringing at full volume.
- **Feedback, about 20 minutes after a surprise started:** a notification asks *"Hey Jana, how did you wake up today?"* plus a question about the surprise:
  - "Did you enjoy the song?"
  - "Are you up for the challenge?"
  - "Did you like the quiz?"
  - "Did you solve the riddle?"

  Tapping it opens a short pop-up (Great / Okay / Still tired, plus yes/no). Answers are only saved on the phone.

## Spotify setup (songs on a locked phone)

Opening the Spotify app is blocked on a locked phone. With Spotify's own "App Remote" connection, the app tells Spotify to play in the background instead, which also works when the phone is locked. One-time setup:

1. Get the SHA-1 fingerprint of the key your APK is signed with (Flutter signs release builds with the debug key unless you set up your own):
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   Copy the line `SHA1: ...`.
2. Go to https://developer.spotify.com/dashboard, log in with your Spotify account, **Create app**:
   - App name / description: anything, e.g. "Rise & Surprise".
   - Redirect URI: `spotify-sdk://auth`
   - Tick **Android**. Package name: `com.example.surpise_wake_up`. SHA-1: from step 1.
3. Open the app's settings in the dashboard and copy the **Client ID** into `lib/spotify_config.dart` (`clientId = '...'`).
4. Build and install the app again. On the home screen, tap **Spotify → Connect (once)** with the phone unlocked and agree in Spotify.

From then on songs play without opening Spotify, also on a locked phone. Without this setup the app falls back to opening Spotify: on a locked phone the voice says "Unlock your phone and the music starts" and Android asks you to unlock.

Notes:
- The Spotify app must be installed and logged in.
- With Spotify **Free**, Spotify may play the songs shuffled or play similar songs instead of the exact track. With **Premium** you get the exact song.
- New Spotify developer apps are in "development mode": at most **5 people**, each added by their Spotify email under *User Management* in the dashboard. The **owner of the developer app needs Spotify Premium**.
- Each phone taps **Spotify → Connect (once)** one time. If you build on another computer, add its SHA-1 to the same Spotify app.
- More users (a public release) would need Spotify's "extended quota", which Spotify currently only grants to registered companies with at least 250,000 monthly users.

## 4. Settings (home screen)

- **EN / DE:** app texts, voice, everything spoken and the notifications.
- **Alarm** on/off and time.
- **Surprise types** to include (at least one).
- **Your name**, used in the greeting and the feedback.
- **Voice:** any offline voice of the chosen language installed on the phone, with a sample. Default: `iol` for English, `nfh` for German (Google voices), if installed.
- **Alarm sound**, with a preview.
- **Spotify → Connect (once)**: see Spotify setup.
- **Try a surprise now** and **Test: ring in 10 seconds** for testing.
- Rise & Surprise asks for **Full screen notifications** (Android 14+) and **Display over other apps** when it opens, until both are granted. A reminder card stays on the home screen until then. With both, a ringing alarm always switches to Rise & Surprise, also on a locked phone.

Colours: deep royal blue `#213E9A`, white and coral `#FF9E8F` (`lib/theme.dart`).

---

## Project files

| Path | What it does |
| --- | --- |
| `lib/main.dart` | Starts the app. Opens the ringing screen, check-in or surprise when the alarm rings or "Surprise me" is tapped. Shows startup errors on screen. |
| `lib/alarm_service.dart` | Schedules and re-arms the daily alarm and the check-in. Sets the notification texts and buttons. |
| `lib/settings_store.dart` | Saves time, name, language, voice, sound, surprise types, history and feedback. |
| `lib/feedback_service.dart` | The 20-minute feedback notification and pop-up. |
| `lib/lock_screen.dart` | Talks to `MainActivity.kt`: show over the lock screen, full-screen permission, "Surprise me" launches. |
| `lib/theme.dart` | Colours and icons. |
| `lib/screens/home_screen.dart` | Settings, pickers, permission pop-up, test buttons. |
| `lib/screens/ring_screen.dart` | Ringing screen: Surprise me / Stop without surprise, 60-second countdown. |
| `lib/screens/surprise_screen.dart` | Shows and reads the surprise: repeats, I am awake, surprise songs, Are you awake? pop-up. |
| `lib/screens/check_in_screen.dart` | "Still sleeping?" check-in. |
| `lib/surprise/content.dart` | All quizzes, songs, challenges and riddles (EN + DE). Add more here, each with a new unique id. |
| `lib/surprise/surprise.dart` | Surprise types and all spoken texts. |
| `lib/surprise/surprise_engine.dart` | The picking rules. |
| `lib/surprise/speaker.dart` | Text-to-speech: best voice, sentence by sentence, waits until really finished. |
| `lib/surprise/song_player.dart` | Plays songs via Spotify's App Remote (works when locked), else opens the track in Spotify. |
| `lib/spotify_config.dart` | Your Spotify Client ID (see Spotify setup). |
| `packages/alarm/` | the app's own copy of the `alarm` plugin 5.15.0 (MIT). Changed so the notification's second button ("Surprise me" / "Play some songs") opens Rise & Surprise over the lock screen, see `packages/alarm/DAWNBOX.md`. |
| `assets/` | The four alarm sounds and the quiz waiting music. |
| `lib/surprise/waiting_music.dart` | Waiting music during quiz, riddle and challenge pauses. |
| `tools/make_quiz_music.py` | Generates `assets/quiz_wait.mp3`. |
| `tools/make_alarm_sound.py` | Generates the alarm sounds: `python3 tools/make_alarm_sound.py [your_song.mp3]`. |
| `test/` | Tests for picking, translations, greeting, riddles and content ids. |
| `setup/` | `AndroidManifest.xml` and `MainActivity.kt` to copy into `android/` (already in place in the update zip). |

---

## Build and install (Android)

You need Flutter 3.41 or newer and the Android SDK.

```bash
cd ~/Documents/Projekte/SurpriseWakeUp/surpise_wake_up
flutter clean
flutter pub get
flutter test
flutter build apk --release
```

The APK is at `build/app/outputs/flutter-apk/app-release.apk`. Copy it to the phone and install it.

**One-time Android setup** (already done in your project):
- `android/app/src/main/AndroidManifest.xml` = `setup/AndroidManifest.xml`. It has the alarm permissions, the RING screen and the notification receivers.
- `MainActivity.kt` = `setup/MainActivity.kt`. Keep your own `package` line.
- In `android/app/build.gradle.kts`:
  - In the `release` block: `isMinifyEnabled = false` and `isShrinkResources = false`. Without this the release build shows a black screen.
  - Inside `compileOptions`: `isCoreLibraryDesugaringEnabled = true`.
  - Add this block:
    ```kotlin
    dependencies {
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    }
    ```

**On the phone:**
- Allow notifications.
- Allow full-screen notifications and "Display over other apps" (the app asks).
- Allow exact alarms.
- Phones by Samsung, Xiaomi, Huawei and Oppo may stop background apps. Turn off battery optimisation for Rise & Surprise.

**Testing:** tap **Test: ring in 10 seconds**, lock the phone, then try **Surprise me** and **Stop**.

## Known limits

- Songs need the Spotify app (installed and logged in). On a locked phone they only play with the Spotify connection set up (see Spotify setup); otherwise you have to unlock.
- The Stop button on the notification only stops the alarm: no surprise, no check-in, no feedback.
- Text-to-speech quality depends on the voices installed on the phone. Better ones can be added in Android settings under Text-to-speech, then Google, then Install voice data.
- **iPhone:** the alarm rings only while Rise & Surprise is running in the background. The "Surprise me" notification button and the lock-screen screen are Android only. A store version would use Apple's AlarmKit.
