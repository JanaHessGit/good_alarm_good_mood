import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../alarm_service.dart';
import '../feedback_service.dart';
import '../lock_screen.dart';
import '../settings_store.dart';
import '../surprise/content.dart';
import '../surprise/song_player.dart';
import '../surprise/speaker.dart';
import '../surprise/surprise.dart';
import '../surprise/surprise_engine.dart';
import '../theme.dart';

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _weekdaysDe = [
  'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag',
];

/// Pause between repeats until I am awake or Play surprise songs is tapped.
const _repeatPause = Duration(seconds: 20);

class SurpriseScreen extends StatefulWidget {
  const SurpriseScreen({super.key, required this.store, this.fromAlarm = false});

  final SettingsStore store;

  /// Opened by the alarm (not by "Try a surprise now"): schedules the
  /// 2-minute check-in.
  final bool fromAlarm;

  @override
  State<SurpriseScreen> createState() => _SurpriseScreenState();
}

class _SurpriseScreenState extends State<SurpriseScreen> {
  final _engine = SurpriseEngine(content: starterContent);
  final _speaker = Speaker.shared;
  Surprise? _surprise;

  /// Bumped whenever the current speech/repeat loop should end.
  int _loop = 0;

  /// Quiz: the option the user picked, null while unanswered.
  int? _picked;

  /// Riddle: answer revealed.
  bool _confirmed = false;

  /// I am awake or Play surprise songs was tapped: stop repeating.
  bool _awake = false;

  Lang get _lang => widget.store.lang;

  bool get _waitingForTap {
    final s = _surprise;
    if (s == null || !s.needsResponse) return false;
    return !_awake;
  }

  @override
  void initState() {
    super.initState();
    // Stay visible over the lock screen. The alarm plugin turns this off
    // when the alarm stops, so set it again shortly after.
    for (final ms in [0, 600, 1500]) {
      Future<void>.delayed(Duration(milliseconds: ms), () {
        if (mounted) LockScreen.showOver(true);
      });
    }
    if (widget.fromAlarm) AlarmService.scheduleCheckIn(widget.store);
    _surprise = _pick();
    if (widget.fromAlarm) FeedbackService.schedule(widget.store, _surprise?.type);
    final s = _surprise;
    if (s != null) _present(s, s.morningMessage(widget.store.userName, _lang));
  }

  /// Speaks [first]. Then:
  /// - song: starts the song (Spotify keeps playing similar songs after it),
  /// - everything else: 20 s after the voice has finished, says it again,
  ///   until the user taps I am awake or Play surprise songs. Answering a
  ///   quiz or solving a riddle opens the "Are you awake?" pop-up instead.
  Future<void> _present(Surprise s, String first) async {
    final loop = ++_loop;
    var text = first;
    while (true) {
      final finished = await _speaker.say(text);
      if (!finished || !mounted || loop != _loop) return;
      if (s.type == SurpriseType.song) {
        await _playSong(s);
        return;
      }
      if (!_waitingForTap) return;
      await Future<void>.delayed(_repeatPause);
      if (!mounted || loop != _loop || !_waitingForTap) return;
      text = first;
    }
  }

  Future<void> _playSong(Surprise s) async {
    await _speaker.stop();
    final ok = await SongPlayer.play(s);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(_lang, "Couldn't start the song. Is Spotify installed?", 'Der Song konnte nicht starten. Ist Spotify installiert?'))),
      );
    }
  }

  /// Draws the next surprise and saves the history right away, so a closed
  /// app can't hand out the same one twice.
  Surprise? _pick() {
    final history = widget.store.history;
    final surprise = _engine.pick(
      now: DateTime.now(),
      enabled: widget.store.enabledTypes,
      history: history,
    );
    widget.store.saveHistory(history);
    return surprise;
  }

  void _answer(int i) {
    final s = _surprise;
    if (s == null || _picked != null) return;
    setState(() => _picked = i);
    _askAwake(s.quizFeedback(i, _lang));
  }

  void _imUp() {
    if (_awake) return;
    _loop++;
    setState(() => _awake = true);
    _speaker.say(tr(_lang, "Great, you're awake! Have a lovely day.", 'Super, du bist wach! Hab einen schönen Tag.'));
  }

  /// Stops repeating and starts the surprise songs in Spotify.
  Future<void> _playSurpriseSongs() async {
    _loop++;
    setState(() => _awake = true);
    await _speaker.stop();
    final ok = await SongPlayer.playSurpriseSongs();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(_lang, "Couldn't start the songs. Is Spotify installed?", 'Die Songs konnten nicht starten. Ist Spotify installiert?'))),
      );
    }
  }

  void _showAnswer() {
    final s = _surprise;
    if (s == null || _confirmed) return;
    setState(() => _confirmed = true);
    _askAwake(s.riddleAnswerIn(_lang));
  }

  /// After a quiz answer or riddle solution: says [said] plus "Are you
  /// awake?" and shows the pop-up at once. Yes: done. No, or no tap within
  /// 10 seconds after the voice finished: the surprise songs start.
  Future<void> _askAwake(String said) async {
    _loop++; // no more repeats
    final voice = _speaker.say('$said ${tr(_lang, 'Are you awake?', 'Bist du wach?')}');
    final yes = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AwakeDialog(lang: _lang, voiceDone: voice),
    );
    if (!mounted || _awake) return;
    if (yes == true) {
      _imUp();
    } else {
      await _playSurpriseSongs();
    }
  }

  void _readAgain() {
    final s = _surprise;
    if (s != null) _present(s, s.spokenIn(_lang));
  }

  void _stopReading() {
    _loop++;
    _speaker.stop();
  }

  void _another() {
    setState(() {
      _surprise = _pick();
      _picked = null;
      _confirmed = false;
      _awake = false;
    });
    final s = _surprise;
    if (widget.fromAlarm) FeedbackService.schedule(widget.store, s?.type);
    if (s != null) _present(s, s.anotherIn(_lang));
  }

  Future<void> _open(String url) async {
    await _speaker.stop();
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the music app.")),
      );
    }
  }

  @override
  void dispose() {
    _loop++;
    _speaker.stop();
    LockScreen.showOver(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _surprise;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(tr(_lang, 'Turn on at least one surprise type.', 'Schalte mindestens eine Art von Überraschung ein.'))),
      );
    }
    final dayName = (_lang == Lang.de ? _weekdaysDe : _weekdays)[DateTime.now().weekday - 1];
    return PopScope(
      // While waiting for a tap, the back button doesn't skip the surprise.
      canPop: !_waitingForTap,
      child: Scaffold(
        backgroundColor: DawnColors.backgroundFor(s.type),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: SizedBox(
                key: ValueKey(s.id),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(_lang, "$dayName's surprise", 'Deine Überraschung am $dayName'), style: const TextStyle(fontSize: 15, color: DawnColors.muted)),
                    const SizedBox(height: 10),
                    Chip(
                      avatar: Icon(DawnColors.iconFor(s.type), color: DawnColors.coral, size: 18),
                      label: Text(s.type.labelIn(_lang)),
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      backgroundColor: DawnColors.royal,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _body(s)),
                    const SizedBox(height: 16),
                    ..._actions(s),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _big = TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.2, color: DawnColors.ink);
  static const _sub = TextStyle(fontSize: 17, color: DawnColors.muted, height: 1.4);

  Widget _body(Surprise s) {
    return switch (s.type) {
      SurpriseType.quiz => _quizBody(s),
      SurpriseType.song => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.text, style: _big),
            const SizedBox(height: 8),
            Text(s.artist ?? '', style: _sub),
          ],
        ),
      SurpriseType.challenge => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.textIn(_lang), style: _big),
            const SizedBox(height: 16),
            if (s.dayFit != DayFit.any)
              Chip(
                label: Text(s.dayFit == DayFit.weekend
                    ? tr(_lang, 'Weekend pick', 'Fürs Wochenende')
                    : tr(_lang, 'Weekday pick', 'Für unter der Woche')),
                backgroundColor: DawnColors.royalSoft,
                side: BorderSide.none,
              ),
            if (!_awake)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_repeatHint, style: _sub),
              ),
          ],
        ),
      SurpriseType.riddle => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.textIn(_lang), style: _big),
            const SizedBox(height: 20),
            if (_confirmed)
              Text(
                s.riddleAnswerIn(_lang),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: DawnColors.royal),
              )
            else
              OutlinedButton(
                onPressed: _showAnswer,
                style: OutlinedButton.styleFrom(
                  foregroundColor: DawnColors.royal,
                  side: const BorderSide(color: DawnColors.royal),
                  minimumSize: const Size(0, 52),
                ),
                child: Text(Surprise.showAnswerLabel(_lang)),
              ),
            if (!_awake) ...[
              const SizedBox(height: 16),
              Text(_repeatHint, style: _sub),
            ],
          ],
        ),
      SurpriseType.story => ListView(
          children: [
            Text(s.titleIn(_lang) ?? tr(_lang, 'A little story', 'Eine kleine Geschichte'), style: _big),
            const SizedBox(height: 8),
            if (s.moodIn(_lang) != null) Text(s.moodIn(_lang)!, style: _sub),
            const SizedBox(height: 16),
            Text(s.textIn(_lang).trim(), style: const TextStyle(fontSize: 17, height: 1.6, color: DawnColors.ink)),
          ],
        ),
    };
  }

  String get _repeatHint => tr(_lang,
      'The voice repeats this every 20 seconds until you tap I am awake or Play surprise songs.',
      'Die Stimme wiederholt das alle 20 Sekunden, bis du auf Ich bin wach oder Überraschungssongs abspielen tippst.');

  Widget _quizBody(Surprise s) {
    final options = s.optionsIn(_lang);
    final fact = s.factIn(_lang);
    return ListView(
      children: [
        Text(s.textIn(_lang), style: _big),
        const SizedBox(height: 20),
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _QuizOption(
              letter: Surprise.letters[i],
              text: options[i],
              state: _picked == null
                  ? _OptionState.open
                  : i == s.answerIndex
                      ? _OptionState.right
                      : i == _picked
                          ? _OptionState.wrong
                          : _OptionState.dimmed,
              onTap: () => _answer(i),
            ),
          ),
        if (_picked != null) ...[
          const SizedBox(height: 4),
          Text(
            _picked == s.answerIndex
                ? tr(_lang, 'Correct, well done!', 'Richtig, super gemacht!')
                : tr(_lang, 'Not quite!', 'Nicht ganz!'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: DawnColors.royal),
          ),
          if (fact != null) ...[
            const SizedBox(height: 6),
            Text(fact, style: _sub),
          ],
        ],
        if (!_awake) ...[
          const SizedBox(height: 12),
          Text(_repeatHint, style: _sub),
        ],
      ],
    );
  }

  List<Widget> _actions(Surprise s) {
    final primary = FilledButton.styleFrom(
      backgroundColor: DawnColors.royal,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(56),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
    final secondary = OutlinedButton.styleFrom(
      foregroundColor: DawnColors.royal,
      side: const BorderSide(color: DawnColors.royal),
      minimumSize: const Size.fromHeight(56),
    );

    // Waiting for a tap: only I am awake or Play surprise songs.
    if (_waitingForTap) {
      return [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: DawnColors.coral,
            foregroundColor: DawnColors.royal,
            minimumSize: const Size.fromHeight(64),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          onPressed: _imUp,
          child: Text(Surprise.imUpLabel(_lang)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: secondary,
          onPressed: _playSurpriseSongs,
          icon: const Icon(Icons.music_note_rounded),
          label: Text(Surprise.playSongsLabel(_lang)),
        ),
      ];
    }

    final query = Uri.encodeComponent(s.songQuery);
    return [
      if (s.type == SurpriseType.song) ...[
        FilledButton(style: primary, onPressed: () => _playSong(s), child: Text(tr(_lang, 'Play again', 'Nochmal abspielen'))),
        const SizedBox(height: 12),
        OutlinedButton(
          style: secondary,
          onPressed: () => _open('https://www.youtube.com/results?search_query=$query'),
          child: Text(tr(_lang, 'Find on YouTube', 'Auf YouTube suchen')),
        ),
        const SizedBox(height: 12),
      ],
      if (s.type == SurpriseType.story)
        Row(
          children: [
            TextButton.icon(
              onPressed: _readAgain,
              icon: const Icon(Icons.replay, color: DawnColors.ink),
              label: Text(tr(_lang, 'Read again', 'Nochmal vorlesen'), style: const TextStyle(color: DawnColors.ink)),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _stopReading,
              icon: const Icon(Icons.stop_circle_outlined, color: DawnColors.ink),
              label: Text(tr(_lang, 'Stop reading', 'Vorlesen stoppen'), style: const TextStyle(color: DawnColors.ink)),
            ),
          ],
        ),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(style: secondary, onPressed: _another, child: Text(tr(_lang, 'Another one', 'Noch eine'))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              style: primary,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr(_lang, 'Start my day', 'Los geht der Tag')),
            ),
          ),
        ],
      ),
    ];
  }
}

/// "Are you awake?" with Yes / No. Counts down 10 seconds once the voice
/// has finished; no answer counts as No.
class _AwakeDialog extends StatefulWidget {
  const _AwakeDialog({required this.lang, required this.voiceDone});

  final Lang lang;
  final Future<void> voiceDone;

  @override
  State<_AwakeDialog> createState() => _AwakeDialogState();
}

class _AwakeDialogState extends State<_AwakeDialog> {
  static const _seconds = 10;
  Timer? _timer;
  int? _left; // null while the voice is still speaking

  @override
  void initState() {
    super.initState();
    widget.voiceDone.whenComplete(() {
      if (!mounted) return;
      setState(() => _left = _seconds);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final left = (_left ?? _seconds) - 1;
        if (left <= 0) {
          _close(false);
        } else {
          setState(() => _left = left);
        }
      });
    });
  }

  void _close(bool awake) {
    _timer?.cancel();
    if (mounted) Navigator.of(context).pop(awake);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lang;
    final left = _left;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(tr(l, 'Are you awake?', 'Bist du wach?'), style: const TextStyle(fontSize: 26)),
        content: Text(
          left == null
              ? tr(l, 'If not, the surprise songs will wake you up.', 'Wenn nicht, wecken dich gleich die Überraschungssongs.')
              : tr(l, 'Surprise songs start in $left s.', 'Überraschungssongs starten in $left s.'),
          style: const TextStyle(fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => _close(false),
            child: Text(tr(l, 'No', 'Nein'), style: const TextStyle(fontSize: 18)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: DawnColors.coral, foregroundColor: DawnColors.royal),
            onPressed: () => _close(true),
            child: Text(tr(l, 'Yes', 'Ja'), style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

enum _OptionState { open, right, wrong, dimmed }

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (state) {
      _OptionState.open => (DawnColors.royalSoft, DawnColors.ink, DawnColors.royalLine),
      _OptionState.right => (DawnColors.royal, Colors.white, DawnColors.royal),
      _OptionState.wrong => (DawnColors.coral, DawnColors.ink, DawnColors.coral),
      _OptionState.dimmed => (Colors.white, DawnColors.muted, DawnColors.royalLine),
    };
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: state == _OptionState.open ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: state == _OptionState.right ? Colors.white : DawnColors.royal,
                child: Text(
                  letter,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: state == _OptionState.right ? DawnColors.royal : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(text, style: TextStyle(fontSize: 18, color: fg))),
              if (state == _OptionState.right) const Icon(Icons.check_circle, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
