import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'settings_store.dart';
import 'surprise/surprise.dart';
import 'theme.dart';

/// Sends "Hey Jana, how did you wake up today?" 20 minutes after waking,
/// and shows the feedback pop-up when that notification is tapped.
class FeedbackService {
  static const delay = Duration(minutes: 20);
  static const _id = 100;
  static final _plugin = FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? _navigator;
  static SettingsStore? _store;

  /// Call once at startup.
  static Future<void> init(GlobalKey<NavigatorState> navigator, SettingsStore store) async {
    _navigator = navigator;
    _store = store;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (r) => _open(r.payload),
    );
    // App was started by tapping the feedback notification.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _open(launch?.notificationResponse?.payload);
    }
  }

  /// [type] is today's surprise, or null if the alarm was stopped without one.
  static Future<void> schedule(SettingsStore store, SurpriseType? type) async {
    final lang = store.lang;
    final name = store.userName.trim();
    final hey = name.isEmpty ? 'Hey!' : 'Hey $name!';
    final body = '${tr(lang, 'How did you wake up today?', 'Wie bist du heute aufgewacht?')}'
        '${type == null ? '' : ' ${_question(type, lang)}'}';
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'feedback',
        tr(lang, 'Morning feedback', 'Morgen-Feedback'),
        channelDescription: tr(lang, 'A short question after you wake up',
            'Eine kurze Frage nach dem Aufwachen'),
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    final when = tz.TZDateTime.now(tz.UTC).add(delay);
    final payload = jsonEncode({'type': type?.name, 'day': DateTime.now().toIso8601String()});
    await _plugin.cancel(id: _id);
    try {
      await _plugin.zonedSchedule(
        id: _id,
        title: hey,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (_) {
      // No exact-alarm permission: a few minutes late is fine for feedback.
      await _plugin.zonedSchedule(
        id: _id,
        title: hey,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

  static String _question(SurpriseType type, Lang lang) => switch (type) {
        SurpriseType.song => tr(lang, 'Did you enjoy the song?', 'Hat dir der Song gefallen?'),
        SurpriseType.challenge =>
          tr(lang, 'Are you up for the challenge?', 'Bist du bereit für die Challenge?'),
        SurpriseType.story => tr(lang, 'Did you enjoy the story?', 'Hat dir die Geschichte gefallen?'),
        SurpriseType.quiz => tr(lang, 'Did you like the quiz?', 'Hat dir das Quiz gefallen?'),
        SurpriseType.riddle => tr(lang, 'Did you solve the riddle?', 'Hast du das Rätsel gelöst?'),
      };

  static void _open(String? payload) {
    final store = _store;
    if (store == null) return;
    SurpriseType? type;
    try {
      final name = (jsonDecode(payload ?? '{}') as Map)['type'];
      for (final t in SurpriseType.values) {
        if (t.name == name) type = t;
      }
    } catch (_) {}
    // Wait for the first screen, then show the pop-up on top of it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _navigator?.currentContext;
      if (context == null) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => FeedbackSheet(store: store, type: type),
      );
    });
  }

  static String questionFor(SurpriseType type, Lang lang) => _question(type, lang);
}

/// The feedback pop-up: how was waking up, and did today's surprise work?
class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key, required this.store, required this.type});

  final SettingsStore store;
  final SurpriseType? type;

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  String? _wake;
  bool? _liked;

  Lang get _lang => widget.store.lang;

  bool get _complete => _wake != null && (widget.type == null || _liked != null);

  Future<void> _save() async {
    await widget.store.addFeedback({
      'date': DateTime.now().toIso8601String(),
      'wake': _wake,
      'type': widget.type?.name,
      'liked': _liked,
    });
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text(tr(_lang, 'Thanks! See you tomorrow morning.', 'Danke! Bis morgen früh.'))),
    );
  }

  Widget _choices(List<(String, String)> options, String? selected, ValueChanged<String> onPick) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: selected == value,
            onSelected: (_) => onPick(value),
            selectedColor: DawnColors.coral,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.store.userName.trim();
    final type = widget.type;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isEmpty ? 'Hey!' : 'Hey $name!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: DawnColors.royal),
            ),
            const SizedBox(height: 16),
            Text(tr(_lang, 'How did you wake up today?', 'Wie bist du heute aufgewacht?'),
                style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 8),
            _choices(
              [
                ('great', tr(_lang, 'Great', 'Super')),
                ('okay', tr(_lang, 'Okay', 'Okay')),
                ('tired', tr(_lang, 'Still tired', 'Noch müde')),
              ],
              _wake,
              (v) => setState(() => _wake = v),
            ),
            if (type != null) ...[
              const SizedBox(height: 20),
              Text(FeedbackService.questionFor(type, _lang), style: const TextStyle(fontSize: 17)),
              const SizedBox(height: 8),
              _choices(
                [
                  ('yes', tr(_lang, 'Yes!', 'Ja!')),
                  ('no', tr(_lang, 'Not really', 'Eher nicht')),
                ],
                _liked == null ? null : (_liked! ? 'yes' : 'no'),
                (v) => setState(() => _liked = v == 'yes'),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: DawnColors.royal),
                onPressed: _complete ? _save : null,
                child: Text(tr(_lang, 'Send', 'Absenden')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
