import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

import '../alarm_service.dart';
import '../feedback_service.dart';
import '../lock_screen.dart';
import '../settings_store.dart';
import '../surprise/content.dart';
import '../surprise/song_player.dart';
import '../surprise/speaker.dart';
import '../surprise/surprise.dart';
import '../surprise/surprise_engine.dart';
import '../surprise/waiting_music.dart';
import '../theme.dart';

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _weekdaysDe = [
  'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag',
];

/// Waiting music between repeats until I am awake or Play some songs is tapped.
const _repeatPause = Duration(seconds: 30);

/// After the surprise was said once plus 4 repeats (5 times) without any
/// tap, the alarm rings again at full volume.
const _saysBeforeRingAgain = 5;

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

  /// I am awake or Play some songs was tapped: stop repeating.
  bool _awake = false;

  /// I am awake (or Yes) was tapped. Only then may the screen turn off.
  bool _confirmedAwake = false;

  /// The "Still sleeping?" check-in, only while songs are playing:
  /// - song surprise, Play some songs, or No / no tap in the "Are you
  ///   awake?" pop-up: songs play, after 10 minutes they're paused and the
  ///   check-in rings (its "Play some songs" starts the next 10 minutes);
  /// - I am awake, or Yes in the pop-up: no check-in.
  bool _checkInSet = false;

  void _scheduleSongsCheckIn() {
    if (!widget.fromAlarm) return;
    _checkInSet = true;
    AlarmService.scheduleCheckIn(widget.store, delay: AlarmService.songsCheckInDelay);
  }

  void _cancelCheckIn() {
    if (!_checkInSet) return;
    _checkInSet = false;
    Alarm.stop(AlarmService.checkInId);
  }

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
    // The screen also stays on until I am awake is tapped, so the phone
    // can't lock again in the middle of the surprise.
    for (final ms in [0, 600, 1500]) {
      Future<void>.delayed(Duration(milliseconds: ms), () {
        if (!mounted) return;
        LockScreen.showOver(true);
        if (!_confirmedAwake) LockScreen.keepScreenOn(true);
      });
    }
    _surprise = _pick();
    // Connect to Spotify right away (while the voice speaks), so songs can
    // start without delay later. Does nothing if Spotify isn't set up.
    unawaited(SongPlayer.connect(onlyIfConnectedBefore: true));
    // A song needs no tap: after 10 minutes of songs, the check-in.
    if (_surprise?.type == SurpriseType.song) _scheduleSongsCheckIn();
    if (widget.fromAlarm) FeedbackService.schedule(widget.store, _surprise?.type);
    final s = _surprise;
    if (s != null) _present(s, s.morningMessage(widget.store.userName, _lang));
  }

  /// Speaks [first]. Then:
  /// - song: starts the song (Spotify keeps playing similar songs after it),
  /// - everything else: 30 s of waiting music after the voice has finished,
  ///   then says it again, until the user taps I am awake or Play some songs. Answering a
  ///   quiz or solving a riddle opens the "Are you awake?" pop-up instead.
  Future<void> _present(Surprise s, String first) async {
    final loop = ++_loop;
    await _music.stop();
    var text = first;
    var said = 1;
    while (true) {
      final finished = await _speaker.say(text);
      if (!finished || !mounted || loop != _loop) return;
      if (s.type == SurpriseType.song) {
        await _playSong(s);
        return;
      }
      if (!_waitingForTap) return;
      // Quiz, riddle or challenge not done yet: waiting music in the pause.
      final music = _wantsWaitingMusic(s);
      if (music) unawaited(_startMusic());
      await Future<void>.delayed(_repeatPause);
      if (!mounted || loop != _loop) return; // a newer loop owns the music now
      if (music) await _music.stop();
      if (!_waitingForTap) return;
      // Still no reaction after 4 repeats: the alarm rings again, loud.
      if (widget.fromAlarm && said >= _saysBeforeRingAgain) {
        await _ringAgain();
        return;
      }
      said++;
      text = first;
    }
  }

  final _music = WaitingMusic.shared;

  /// Closes the surprise and lets the alarm ring again at full volume. Its
  /// ringing screen / notification offers Surprise me and Stop again.
  Future<void> _ringAgain() async {
    _loop++;
    await _music.stop();
    await _speaker.stop();
    await AlarmService.ringAgain(widget.store);
    if (mounted) Navigator.of(context).pop();
  }

  /// Starts the thinking music; says why on screen if it can't play.
  Future<void> _startMusic() async {
    final error = await _music.start();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(_lang, 'Waiting music could not play: $error', 'Wartemusik konnte nicht starten: $error'))),
      );
    }
  }

  /// Waiting music in every pause while the surprise waits for a tap
  /// (quiz, riddle and mini challenge alike).
  bool _wantsWaitingMusic(Surprise s) => s.type != SurpriseType.song && _waitingForTap;

  Future<void> _playSong(Surprise s) async {
    await _speaker.stop();
    final ok = await SongPlayer.play(s);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(_lang, "The song didn't start. Check that Spotify is installed and connected (home screen).", 'Der Song ist nicht gestartet. Prüfe, ob Spotify installiert und verbunden ist (Startbildschirm).'))),
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
    unawaited(_music.stop());
    setState(() {
      _awake = true;
      _confirmedAwake = true;
    });
    LockScreen.keepScreenOn(false); // awake: the screen may turn off again
    _cancelCheckIn(); // awake: no check-in
    _speaker.say(tr(_lang, "Great, you're awake! Have a lovely day.", 'Super, du bist wach! Hab einen schönen Tag.'));
  }

  /// Stops repeating and starts the surprise songs in Spotify. With
  /// [checkIn], the songs are paused after 10 minutes and the check-in rings.
  Future<void> _playSurpriseSongs({bool checkIn = true}) async {
    _loop++;
    await _music.stop();
    setState(() => _awake = true); // the screen stays on: not confirmed awake
    if (checkIn) {
      _scheduleSongsCheckIn();
    } else {
      _cancelCheckIn();
    }
    await _speaker.stop();
    final ok = await SongPlayer.playSurpriseSongs();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(_lang, "The songs didn't start. Check that Spotify is installed and connected (home screen).", 'Die Songs sind nicht gestartet. Prüfe, ob Spotify installiert und verbunden ist (Startbildschirm).'))),
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
    unawaited(_music.stop());
    final voice = _speaker.say('$said ${tr(_lang, 'Are you awake?', 'Bist du wach?')}');
    // true = Yes, false = No, null = no tap within 10 seconds.
    final answer = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AwakeDialog(lang: _lang, voiceDone: voice),
    );
    if (!mounted || _awake) return;
    if (answer == true) {
      _imUp();
    } else {
      // No, or no tap: like Play some songs (check-in after 10 min).
      await _playSurpriseSongs();
    }
  }

  @override
  void dispose() {
    _loop++;
    _music.stop();
    // From the alarm, only I am awake lets the screen turn off again
    // (a song has no I am awake: leaving its screen is enough).
    if (_confirmedAwake || !widget.fromAlarm || _surprise?.type == SurpriseType.song) {
      LockScreen.keepScreenOn(false);
    }
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
    };
  }

  String get _repeatHint => tr(_lang,
      'The voice repeats this every 30 seconds until you tap I am awake or Play some songs.',
      'Die Stimme wiederholt das alle 30 Sekunden, bis du auf Ich bin wach oder Spiel ein paar Songs tippst.');

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

    // Waiting for a tap: only I am awake or Play some songs.
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

    // Song: Spotify plays, no buttons needed.
    if (s.type == SurpriseType.song) return const [];
    return [
      FilledButton(
        style: primary,
        onPressed: () => Navigator.of(context).pop(),
        child: Text(tr(_lang, 'Start my day', 'Los geht der Tag')),
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
          _close(null); // no tap
        } else {
          setState(() => _left = left);
        }
      });
    });
  }

  void _close(bool? awake) {
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
              ? tr(l, 'If not, some songs will wake you up.', 'Wenn nicht, wecken dich gleich ein paar Songs.')
              : tr(l, 'Songs start in $left s.', 'Songs starten in $left s.'),
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
