import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';

import '../alarm_service.dart';
import '../feedback_service.dart';
import '../lock_screen.dart';
import '../settings_store.dart';
import '../surprise/surprise.dart';
import '../theme.dart';
import 'surprise_screen.dart';

/// Shown while the alarm rings, also over the lock screen. Ways out:
/// - Start surprise -> alarm off, tomorrow re-armed, surprise starts at once
/// - wait          -> after N seconds the same happens on its own
/// - Snooze        -> alarm off, rings again in a few minutes
/// - Stop          -> alarm off, tomorrow re-armed, no surprise today
class RingScreen extends StatefulWidget {
  const RingScreen({super.key, required this.store, required this.alarm});

  final SettingsStore store;
  final AlarmSettings alarm;

  @override
  State<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends State<RingScreen> {
  Timer? _ticker;
  StreamSubscription<AlarmSet>? _ringingSub;
  late int _secondsLeft;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.store.autoSurpriseSeconds;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _handled) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _showSurprise();
    });
    // Keep this screen on top of the lock screen while it rings.
    LockScreen.showOver(true);
    // Stopped or snoozed from the notification instead of this screen:
    // close quietly and make sure tomorrow's alarm is set.
    _ringingSub = Alarm.ringing.listen((ringing) async {
      if (ringing.containsId(widget.alarm.id) || _handled) return;
      _handled = true;
      _ticker?.cancel();
      await AlarmService.ensureScheduled(widget.store);
      await LockScreen.showOver(false);
      if (mounted) Navigator.of(context).pop();
    });
  }

  /// Stops the alarm and goes straight to the surprise, which starts
  /// speaking right away.
  Future<void> _showSurprise() async {
    if (_handled) return;
    _handled = true;
    _ticker?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => SurpriseScreen(store: widget.store, fromAlarm: true)),
    );
    await AlarmService.stopAndRearm(widget.store);
  }

  /// Just switch the alarm off: no surprise today.
  Future<void> _stopOnly() async {
    if (_handled) return;
    _handled = true;
    _ticker?.cancel();
    await AlarmService.stopAndRearm(widget.store);
    await AlarmService.scheduleCheckIn(widget.store);
    await FeedbackService.schedule(widget.store, null);
    await LockScreen.showOver(false);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _snooze() async {
    if (_handled) return;
    _handled = true;
    _ticker?.cancel();
    await AlarmService.snooze(widget.store);
    await LockScreen.showOver(false);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ringingSub?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final total = widget.store.autoSurpriseSeconds;
    final left = _secondsLeft < 0 ? 0 : _secondsLeft;
    final lang = widget.store.lang;
    final outlined = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: DawnColors.royalLine),
      textStyle: const TextStyle(fontSize: 16),
    );
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: DawnColors.royal,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
            child: Column(
              children: [
                Text(
                  '${_two(now.hour)}:${_two(now.minute)}',
                  style: const TextStyle(color: Colors.white, fontSize: 96, fontWeight: FontWeight.w600, height: 1),
                ),
                const SizedBox(height: 12),
                Text(tr(lang, 'Good morning', 'Guten Morgen'), style: const TextStyle(color: Colors.white, fontSize: 24)),
                const Spacer(),
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: left / total,
                          strokeWidth: 10,
                          color: DawnColors.coral,
                          backgroundColor: DawnColors.royalTrack,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.card_giftcard_rounded, color: DawnColors.coral, size: 34),
                          Text('$left s', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w600)),
                          Text(tr(lang, 'until your surprise', 'bis zur Überraschung'), style: const TextStyle(color: DawnColors.onRoyalMuted, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  !widget.store.alarmSound.hasSong || left > total - SettingsStore.songAfterSeconds
                      ? tr(lang, "Tap Start surprise, or wait, and today's surprise starts by itself.",
                          'Tippe auf Überraschung starten oder warte, dann startet sie von selbst.')
                      : tr(lang, 'Your wake-up song is playing.', 'Dein Wach-Song läuft.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: DawnColors.onRoyalMuted, fontSize: 15, height: 1.5),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: DawnColors.coral,
                      foregroundColor: DawnColors.royal,
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _showSurprise,
                    child: Text(tr(lang, 'Start surprise', 'Überraschung starten')),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    style: outlined,
                    onPressed: _snooze,
                    child: Text('${tr(lang, 'Snooze', 'Schlummern')} ${widget.store.snoozeMinutes} min'),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _stopOnly,
                  style: TextButton.styleFrom(foregroundColor: DawnColors.onRoyalMuted),
                  child: Text(tr(lang, 'Stop alarm without surprise', 'Wecker ohne Überraschung stoppen')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
