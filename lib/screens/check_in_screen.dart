import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';

import '../alarm_service.dart';
import '../lock_screen.dart';
import '../settings_store.dart';
import '../surprise/speaker.dart';
import '../surprise/surprise.dart';
import '../theme.dart';

/// Shown by the check-in alarm two minutes after waking up: "Still sleeping?
/// If not, tap here." One big button.
/// The alarm starts very quietly; after 30 seconds without a tap it rings
/// at full volume (set up in AlarmService.scheduleCheckIn).
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key, required this.store});

  final SettingsStore store;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  StreamSubscription<AlarmSet>? _ringingSub;
  bool _done = false;

  Lang get _lang => widget.store.lang;

  @override
  void initState() {
    super.initState();
    LockScreen.showOver(true);
    Speaker.shared.say(tr(_lang, 'Still sleeping? If not, tap here.', 'Schläfst du noch? Wenn nicht, tippe hier.'));
    // Confirmed from the notification instead: just close.
    _ringingSub = Alarm.ringing.listen((ringing) {
      if (!ringing.containsId(AlarmService.checkInId) && !_done) _close();
    });
  }

  Future<void> _confirm() async {
    if (_done) return;
    await Alarm.stop(AlarmService.checkInId);
    await Speaker.shared.say(tr(_lang, 'Perfect. Have a great day!', 'Perfekt. Hab einen tollen Tag!'));
    _close();
  }

  void _close() {
    if (_done) return;
    _done = true;
    LockScreen.showOver(false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ringingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: DawnColors.royal,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                const Icon(Icons.wb_sunny_outlined, color: DawnColors.coral, size: 64),
                const SizedBox(height: 16),
                Text(
                  tr(_lang, 'Still sleeping?', 'Schläfst du noch?'),
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(_lang, 'If not, tap here.', 'Wenn nicht, tippe hier.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: DawnColors.onRoyalMuted, fontSize: 16),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: DawnColors.coral,
                      foregroundColor: DawnColors.royal,
                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _confirm,
                    child: Text(Surprise.imUpLabel(_lang)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
