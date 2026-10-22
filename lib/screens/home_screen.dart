import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../alarm_service.dart';
import '../lock_screen.dart';
import '../settings_store.dart';
import '../spotify_config.dart';
import '../surprise/song_player.dart';
import '../surprise/speaker.dart';
import '../surprise/surprise.dart';
import '../theme.dart';
import 'surprise_screen.dart';

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _weekdaysDe = [
  'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag',
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store});

  final SettingsStore store;

  Lang get _l => store.lang;

  String _two(int n) => n.toString().padLeft(2, '0');

  String _nextRingText(DateTime now) {
    final next = AlarmService.nextOccurrence(store.alarmTime, now);
    final isToday = next.day == now.day;
    final diff = next.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final day = isToday ? tr(_l, 'Today', 'Heute') : tr(_l, 'Tomorrow', 'Morgen');
    final weekday = (_l == Lang.de ? _weekdaysDe : _weekdays)[next.weekday - 1];
    return '$day, $weekday · ${tr(_l, 'in', 'in')} $h h $m min';
  }

  Future<void> _toggleAlarm(bool on) async {
    if (on) await AlarmService.requestPermissions();
    await store.setAlarmEnabled(on);
    await AlarmService.scheduleDaily(store);
  }

  Future<void> _changeTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: store.alarmTime,
    );
    if (picked == null) return;
    await store.setAlarmTime(picked);
    if (!store.alarmEnabled) {
      await AlarmService.requestPermissions();
      await store.setAlarmEnabled(true);
    }
    await AlarmService.scheduleDaily(store);
  }

  /// Switches the app, the voice and all spoken texts to [l].
  Future<void> _setLang(Lang l) async {
    if (l == store.lang) return;
    await store.setLang(l);
    await Speaker.shared.switchLanguage(german: l == Lang.de);
    // Re-arm so the alarm notification texts use the new language.
    await AlarmService.scheduleDaily(store);
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: store.userName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(_l, 'What should the voice call you?', 'Wie soll dich die Stimme nennen?')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: tr(_l, 'Your name', 'Dein Name')),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr(_l, 'Cancel', 'Abbrechen'))),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(tr(_l, 'Save', 'Speichern')),
          ),
        ],
      ),
    );
    // Not disposed here: the dialog's closing animation still uses it.
    if (name != null) await store.setUserName(name);
  }

  Future<void> _ringSoon(BuildContext context) async {
    await AlarmService.requestPermissions();
    await AlarmService.ringIn(store, const Duration(seconds: 10));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(_l, 'Test alarm rings in 10 seconds. Lock your phone if you like.',
            'Der Testwecker klingelt in 10 Sekunden. Sperr dein Handy, wenn du magst.')),
      ),
    );
  }

  /// Connects to Spotify once, so songs can play on a locked phone.
  Future<void> _connectSpotify(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!SpotifyConfig.isSet) {
      messenger.showSnackBar(SnackBar(
        content: Text(tr(_l,
            'Add your Spotify Client ID in lib/spotify_config.dart first (see README).',
            'Trage zuerst deine Spotify Client ID in lib/spotify_config.dart ein (siehe README).')),
      ));
      return;
    }
    final ok = await SongPlayer.connect();
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? tr(_l, 'Spotify connected. Songs now also play on a locked phone.',
              'Spotify verbunden. Songs spielen jetzt auch bei gesperrtem Handy.')
          : tr(_l, "Couldn't connect. Is Spotify installed and are you logged in?",
              'Verbindung fehlgeschlagen. Ist Spotify installiert und bist du eingeloggt?')),
    ));
  }

  Widget _settingRow(String title, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: DawnColors.royalSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD3DDF9)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          title: Text(title, style: const TextStyle(fontSize: 15)),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: DawnColors.royal),
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final t = store.alarmTime;
        final enabled = store.alarmEnabled;
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Rise & Surprise',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: DawnColors.ink),
                      ),
                    ),
                    SegmentedButton<Lang>(
                      segments: const [
                        ButtonSegment(value: Lang.en, label: Text('EN')),
                        ButtonSegment(value: Lang.de, label: Text('DE')),
                      ],
                      selected: {store.lang},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => _setLang(s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _LockScreenCheck(lang: _l),
                _AlarmCard(
                  lang: _l,
                  time: '${_two(t.hour)}:${_two(t.minute)}',
                  subtitle: enabled ? _nextRingText(DateTime.now()) : tr(_l, 'Alarm is off', 'Wecker ist aus'),
                  enabled: enabled,
                  onToggle: _toggleAlarm,
                  onChangeTime: () => _changeTime(context),
                ),
                const SizedBox(height: 24),
                Text(
                  tr(_l, 'Your surprise could be…', 'Deine Überraschung kann sein …'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: DawnColors.ink),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in SurpriseType.values)
                      Builder(builder: (context) {
                        final on = store.enabledTypes.contains(type);
                        // Selected: the same dark blue as the alarm card.
                        return FilterChip(
                          label: Text(type.labelIn(_l)),
                          labelStyle: TextStyle(
                            color: on ? Colors.white : DawnColors.royal,
                            fontWeight: FontWeight.w500,
                          ),
                          avatar: Icon(DawnColors.iconFor(type), size: 18, color: on ? Colors.white : DawnColors.royal),
                          selected: on,
                          onSelected: (_) => store.toggleType(type),
                          selectedColor: DawnColors.royal,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: DawnColors.royal),
                          showCheckmark: false,
                        );
                      }),
                  ],
                ),
                const SizedBox(height: 24),
                _settingRow(
                  tr(_l, 'Wake-up voice calls you', 'Die Stimme nennt dich'),
                  store.userName.isEmpty ? tr(_l, 'Add your name', 'Name eingeben') : store.userName,
                  () => _editName(context),
                ),
                _settingRow(
                  tr(_l, 'Voice', 'Stimme'),
                  store.voice?.label ?? Speaker.shared.current?.label ?? tr(_l, 'Choose a voice', 'Stimme wählen'),
                  () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => VoicePicker(store: store),
                  ),
                ),
                _settingRow(
                  tr(_l, 'Alarm sound', 'Weckton'),
                  store.alarmSound.label(_l),
                  () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => SoundPicker(store: store),
                  ),
                ),
                _settingRow(
                  'Spotify',
                  SpotifyConfig.isSet
                      ? tr(_l, 'Connect (once)', 'Verbinden (einmalig)')
                      : tr(_l, 'Not set up, see README', 'Nicht eingerichtet, siehe README'),
                  () => _connectSpotify(context),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: DawnColors.coral,
                      foregroundColor: DawnColors.royal,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => SurpriseScreen(store: store)),
                    ),
                    child: Text(tr(_l, 'Try a surprise now', 'Überraschung jetzt testen')),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _ringSoon(context),
                  child: Text(tr(_l, 'Test: ring in 10 seconds', 'Test: in 10 Sekunden klingeln')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.lang,
    required this.time,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    required this.onChangeTime,
  });

  final Lang lang;
  final String time;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onChangeTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DawnColors.royal,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(tr(lang, 'Wake me at', 'Weck mich um'),
                    style: const TextStyle(color: DawnColors.onRoyalMuted, fontSize: 14)),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeTrackColor: DawnColors.coral,
                thumbColor: const WidgetStatePropertyAll(DawnColors.royal),
              ),
            ],
          ),
          Text(
            time,
            style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.w600, height: 1),
          ),
          const SizedBox(height: 12),
          Text(subtitle, style: const TextStyle(color: DawnColors.onRoyalMuted, fontSize: 15)),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: DawnColors.royalLine),
              ),
              onPressed: onChangeTime,
              child: Text(tr(lang, 'Change time', 'Zeit ändern')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Android 14+: warns if the alarm may not open full screen on a locked
/// phone (then only a small notification appears), with a button to fix it.
class _LockScreenCheck extends StatefulWidget {
  const _LockScreenCheck({required this.lang});

  final Lang lang;

  @override
  State<_LockScreenCheck> createState() => _LockScreenCheckState();
}

class _LockScreenCheckState extends State<_LockScreenCheck> with WidgetsBindingObserver {
  bool _fullScreenOk = true;
  bool _overlayOk = true;
  bool get _allowed => _fullScreenOk && _overlayOk;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check(); // back from Settings
  }

  /// Each permission is asked once per app start, until it is granted.
  static bool _askedFullScreen = false;
  static bool _askedOverlay = false;

  Future<void> _check() async {
    final full = await LockScreen.canUseFullScreen();
    var overlay = true;
    if (Platform.isAndroid) {
      try {
        overlay = await Permission.systemAlertWindow.isGranted;
      } catch (_) {}
    }
    if (!mounted) return;
    if (full != _fullScreenOk || overlay != _overlayOk) {
      setState(() {
        _fullScreenOk = full;
        _overlayOk = overlay;
      });
    }
    if (!full && !_askedFullScreen) {
      _askedFullScreen = true;
      await _ask(fullScreen: true);
    } else if (full && !overlay && !_askedOverlay) {
      _askedOverlay = true;
      await _ask(fullScreen: false);
    }
  }

  /// Opens the settings page for the first missing permission.
  Future<void> _openSettings() async {
    if (!_fullScreenOk) {
      await LockScreen.openFullScreenSettings();
    } else if (!_overlayOk) {
      await Permission.systemAlertWindow.request();
    }
  }

  /// Pop-up that explains the permission and opens the right settings page.
  Future<void> _ask({required bool fullScreen}) async {
    final l = widget.lang;
    final text = fullScreen
        ? tr(l,
            'So you can start your surprise or stop the alarm right on the locked phone, '
                'Rise & Surprise needs "Full screen notifications".\n\n'
                'On the next page, switch it on for Rise & Surprise, then come back.',
            'Damit du deine Überraschung direkt am gesperrten Handy starten oder den Wecker stoppen kannst, '
                'braucht Rise & Surprise „Vollbild-Benachrichtigungen“.\n\n'
                'Schalte es auf der nächsten Seite für Rise & Surprise ein und komm dann zurück.')
        : tr(l,
            'So the alarm always opens Rise & Surprise (and not just a small notification), '
                'Rise & Surprise needs "Display over other apps".\n\n'
                'On the next page, switch it on for Rise & Surprise, then come back.',
            'Damit der Wecker immer Rise & Surprise öffnet (und nicht nur eine kleine Benachrichtigung zeigt), '
                'braucht Rise & Surprise „Über anderen Apps einblenden“.\n\n'
                'Schalte es auf der nächsten Seite für Rise & Surprise ein und komm dann zurück.');
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(l, 'Show the alarm on the lock screen?', 'Wecker auf dem Sperrbildschirm zeigen?')),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr(l, 'Later', 'Später')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tr(l, 'Allow', 'Erlauben')),
          ),
        ],
      ),
    );
    if (open == true) await _openSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: const Color(0xFFFFE9E6),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(widget.lang, 'Allow the alarm on the lock screen', 'Wecker auf dem Sperrbildschirm erlauben'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF7A1F12)),
              ),
              const SizedBox(height: 6),
              Text(
                tr(widget.lang,
                    'Otherwise a locked phone only shows a small notification instead of the alarm screen.',
                    'Sonst zeigt ein gesperrtes Handy nur eine kleine Benachrichtigung statt des Weckers.'),
                style: const TextStyle(fontSize: 14, color: Color(0xFF7A1F12)),
              ),
              const SizedBox(height: 10),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: DawnColors.royal),
                onPressed: _openSettings,
                child: Text(tr(widget.lang, 'Open settings', 'Einstellungen öffnen')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lists the voices of the chosen language. Tapping one plays a sample and
/// saves it as the wake-up voice.
class VoicePicker extends StatefulWidget {
  const VoicePicker({super.key, required this.store});

  final SettingsStore store;

  @override
  State<VoicePicker> createState() => _VoicePickerState();
}

class _VoicePickerState extends State<VoicePicker> {
  // Wait until the speech engine is ready, then list its voices.
  late final Future<List<VoiceOption>> _voices =
      Speaker.shared.warmUp().then((_) => Speaker.shared.availableVoices()).then(
            (all) => all.where((v) => v.isGerman == (widget.store.lang == Lang.de)).toList(),
          );

  Future<void> _choose(VoiceOption v) async {
    await widget.store.setVoice(v);
    if (mounted) setState(() {});
    await Speaker.shared.useVoice(v);
    await Speaker.shared.say(v.isGerman
        ? 'Hallooooooo, es ist Zeit zum Aufstehen. So klinge ich.'
        : "Hello there, it's the morning. This is how I sound.");
  }

  @override
  void dispose() {
    Speaker.shared.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.store.voice ?? Speaker.shared.current;
    final l = widget.store.lang;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: FutureBuilder<List<VoiceOption>>(
          future: _voices,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final voices = snap.data!;
            if (voices.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(tr(
                  l,
                  'No offline English voices found. Install some in Settings → Text-to-speech output → '
                      'Speech Services by Google → Install voice data → English.',
                  'Keine deutschen Offline-Stimmen gefunden. Installiere welche unter Einstellungen → '
                      'Sprachausgabe → Sprachdienste von Google → Sprachdaten installieren → Deutsch.',
                )),
              );
            }
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                  child: Text(tr(l, 'Choose a voice', 'Stimme wählen'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(tr(l, 'Tap to hear it. Your choice is saved right away. Change the language with EN / DE at the top.',
                      'Tippen zum Anhören. Deine Wahl wird sofort gespeichert. Die Sprache änderst du oben mit EN / DE.')),
                ),
                for (final v in voices) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const Icon(Icons.record_voice_over_outlined),
                    title: Text(v.label),
                    trailing: current != null && current.name == v.name
                        ? const Icon(Icons.check_circle, color: DawnColors.royal)
                        : null,
                    onTap: () => _choose(v),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Lists the alarm sounds. Tapping one plays its start and selects it; the
/// music button plays the song part that begins after 20 seconds.
class SoundPicker extends StatefulWidget {
  const SoundPicker({super.key, required this.store});

  final SettingsStore store;

  @override
  State<SoundPicker> createState() => _SoundPickerState();
}

class _SoundPickerState extends State<SoundPicker> {
  final _player = AudioPlayer();

  Future<void> _preview(AlarmSound s, {bool song = false}) async {
    await _player.stop();
    // AssetSource paths are relative to assets/.
    await _player.play(
      AssetSource(s.asset.replaceFirst('assets/', '')),
      position: song ? const Duration(seconds: SettingsStore.songAfterSeconds) : Duration.zero,
    );
  }

  Future<void> _choose(AlarmSound s) async {
    await widget.store.setAlarmSound(s);
    if (mounted) setState(() {});
    await _preview(s);
    // Re-arm so the next alarm uses the new sound.
    await AlarmService.scheduleDaily(widget.store);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.store.lang;
    final current = widget.store.alarmSound;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: Text(tr(l, 'Alarm sound', 'Weckton'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(tr(l, 'Tap to hear and choose. The note button plays the song that follows after 20 seconds.',
                  'Tippen zum Anhören und Auswählen. Die Noten-Taste spielt den Song, der nach 20 Sekunden folgt.')),
            ),
            for (final s in AlarmSound.values)
              ListTile(
                contentPadding: const EdgeInsets.only(left: 24, right: 12),
                leading: Icon(
                  current == s ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: DawnColors.royal,
                ),
                title: Text(s.label(l)),
                trailing: s.hasSong
                    ? IconButton(
                        tooltip: tr(l, 'Play the song part', 'Song-Teil abspielen'),
                        icon: const Icon(Icons.music_note_outlined, color: DawnColors.royal),
                        onPressed: () => _preview(s, song: true),
                      )
                    : null,
                onTap: () => _choose(s),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: TextButton.icon(
                onPressed: () => _player.stop(),
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(tr(l, 'Stop preview', 'Vorschau stoppen')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
