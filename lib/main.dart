import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';

import 'alarm_service.dart';
import 'credits.dart';
import 'feedback_service.dart';
import 'screens/check_in_screen.dart';
import 'screens/home_screen.dart';
import 'lock_screen.dart';
import 'screens/ring_screen.dart';
import 'screens/surprise_screen.dart';
import 'surprise/song_player.dart';
import 'settings_store.dart';
import 'surprise/speaker.dart';
import 'surprise/surprise.dart';
import 'theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// Startup problems, shown on screen instead of a black page.
final startupErrors = <String>[];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerCredits(); // own notes on the About & licences page

  // Any error later on is also shown instead of disappearing silently.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    startupErrors.add(details.exceptionAsString());
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    startupErrors.add('$error');
    return true;
  };
  // If something on a screen fails, show the reason instead of a grey or
  // black box (release builds hide it otherwise).
  ErrorWidget.builder = (details) => Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong:\n\n${details.exceptionAsString()}',
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 13, color: DawnColors.ink),
          ),
        ),
      );

  try {
    await Alarm.init().timeout(const Duration(seconds: 10));
  } catch (e) {
    startupErrors.add('Alarm setup failed: $e');
  }

  SettingsStore? store;
  try {
    store = await SettingsStore.load().timeout(const Duration(seconds: 10));
  } catch (e) {
    startupErrors.add('Loading settings failed: $e');
  }

  runApp(store == null ? const StartupErrorApp() : DawnboxApp(store: store));

  if (store != null) {
    // Tomorrow's alarm, in case it was stopped from the notification.
    unawaited(AlarmService.ensureScheduled(store).catchError((_) {}));
    // Morning feedback notification (and its pop-up when tapped).
    unawaited(FeedbackService.init(navigatorKey, store).catchError((_) {}));
  }
  // Load the voice now, so the surprise can start talking instantly.
  Speaker.shared.preferred = store?.voice;
  Speaker.shared.german = store?.lang == Lang.de;
  unawaited(Speaker.shared.warmUp());
}

/// Shown only if the app could not start. Lists what went wrong.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Rise & Surprise could not start',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: DawnColors.royal),
              ),
              const SizedBox(height: 12),
              const Text('Please send a screenshot of this screen.'),
              const SizedBox(height: 16),
              for (final e in startupErrors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SelectableText(e, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DawnboxApp extends StatefulWidget {
  const DawnboxApp({super.key, required this.store});

  final SettingsStore store;

  @override
  State<DawnboxApp> createState() => _DawnboxAppState();
}

class _DawnboxAppState extends State<DawnboxApp> {
  StreamSubscription<AlarmSet>? _ringingSub;
  bool _ringScreenOpen = false;
  bool _surpriseOpen = false;

  /// How the alarm notification opened the app ("tap" or "button"), and
  /// when. Main alarm: start the surprise. Check-in: "button" plays songs.
  String? _requested;
  DateTime? _requestedAt;
  late final Future<void> _launchChecked;

  /// The pending request if it is fresh (under 2 minutes), and clears it.
  String? _takeRequest() {
    final r = _requested;
    final at = _requestedAt;
    _requested = null;
    _requestedAt = null;
    if (r == null || at == null) return null;
    return DateTime.now().difference(at) < const Duration(minutes: 2) ? r : null;
  }

  @override
  void initState() {
    super.initState();
    _launchChecked = _checkLaunch();
    // "Surprise me" tapped while the app is already open.
    LockScreen.onLaunchAction(() async {
      await _checkLaunch();
      final action = _takeRequest();
      if (action == null) return;
      if (await Alarm.isRinging(AlarmService.alarmId)) {
        _startSurprise();
      } else if (action == 'button' && await Alarm.isRinging(AlarmService.checkInId)) {
        await _playSongsFromCheckIn();
      }
    });
    // Fires when an alarm starts ringing, also if the app was opened
    // by tapping the alarm notification.
    _ringingSub = Alarm.ringing.listen(_onRinging);
  }

  Future<void> _checkLaunch() async {
    final action = await LockScreen.takeLaunchAction();
    if (action != null) {
      _requested = action;
      _requestedAt = DateTime.now();
    }
  }

  /// Check-in "Play radio": stop the check-in and start the radio.
  Future<void> _playSongsFromCheckIn() async {
    await Alarm.stop(AlarmService.checkInId); // the check-in screen closes itself
    await SongPlayer.playSurpriseSongs();
    // After 10 minutes of songs: pause them and ask again.
    await AlarmService.scheduleCheckIn(widget.store, delay: AlarmService.songsCheckInDelay);
  }

  /// Alarm off (tomorrow's re-armed) and straight into the surprise.
  void _startSurprise() {
    if (_surpriseOpen) return;
    final nav = navigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startSurprise());
      return;
    }
    _surpriseOpen = true;
    nav.popUntil((route) => route.isFirst); // closes the ringing screen if open
    nav
        .push(MaterialPageRoute<void>(
          builder: (_) => SurpriseScreen(store: widget.store, fromAlarm: true),
        ))
        .whenComplete(() => _surpriseOpen = false);
    unawaited(AlarmService.stopAndRearm(widget.store).catchError((_) {}));
  }

  Future<void> _onRinging(AlarmSet ringing) async {
    await _launchChecked;
    if (ringing.alarms.isEmpty) {
      // Alarm ended (also from the notification): keep tomorrow's alarm set.
      unawaited(AlarmService.ensureScheduled(widget.store).catchError((_) {}));
      return;
    }
    final ringingAlarm = ringing.alarms.first;
    // Any alarm (the morning alarm or the check-in) stops the radio first.
    unawaited(SongPlayer.stop());
    final action = _takeRequest();
    if (action != null) {
      if (ringingAlarm.id != AlarmService.checkInId) {
        _startSurprise();
        return;
      }
      // Check-in: the button plays songs; a tap shows the check-in screen.
      if (action == 'button') {
        await _playSongsFromCheckIn();
        return;
      }
    }
    if (_ringScreenOpen || _surpriseOpen) return;
    final nav = navigatorKey.currentState;
    if (nav == null) {
      // App still starting up: try again after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _onRinging(ringing));
      return;
    }
    _ringScreenOpen = true;
    final alarm = ringing.alarms.first;
    nav
        .push(MaterialPageRoute<void>(
          builder: (_) => alarm.id == AlarmService.checkInId
              // The "Still sleeping?" check-in two minutes after waking.
              ? CheckInScreen(store: widget.store)
              : RingScreen(store: widget.store, alarm: alarm),
        ))
        .whenComplete(() => _ringScreenOpen = false);
  }

  @override
  void dispose() {
    _ringingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rise & Surprise',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: buildTheme(),
      home: startupErrors.isEmpty
          ? HomeScreen(store: widget.store)
          : _HomeWithWarning(store: widget.store),
    );
  }
}

/// Opens the app normally but shows startup warnings (e.g. alarm setup
/// failed) at the top, so the rest of the app can still be tried.
class _HomeWithWarning extends StatelessWidget {
  const _HomeWithWarning({required this.store});

  final SettingsStore store;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: const Color(0xFFFFE9E6),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SelectableText(
                'Startup problem (please send a screenshot):\n${startupErrors.join('\n')}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A1F12)),
              ),
            ),
          ),
        ),
        Expanded(child: HomeScreen(store: store)),
      ],
    );
  }
}
