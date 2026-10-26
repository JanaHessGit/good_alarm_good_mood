import 'dart:math';

import 'package:dawnbox/surprise/content.dart';
import 'package:dawnbox/surprise/speaker.dart';
import 'package:dawnbox/surprise/surprise.dart';
import 'package:dawnbox/surprise/surprise_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final monday = DateTime(2026, 10, 19, 7);
  final saturday = DateTime(2026, 10, 24, 7);
  final all = SurpriseType.values.toSet();

  test('never the same type two mornings in a row', () {
    final engine = SurpriseEngine(content: starterContent, random: Random(1));
    final history = SurpriseHistory();
    SurpriseType? previous;
    for (var i = 0; i < 300; i++) {
      final s = engine.pick(now: monday, enabled: all, history: history)!;
      expect(s.type, isNot(previous));
      previous = s.type;
    }
  });

  test('no repeats within a type until all items were shown', () {
    final engine = SurpriseEngine(content: starterContent, random: Random(2));
    final history = SurpriseHistory();
    final quizzes = starterContent.where((s) => s.type == SurpriseType.quiz).length;
    final seen = <String>{};
    for (var i = 0; i < quizzes; i++) {
      final s = engine.pick(now: monday, enabled: {SurpriseType.quiz}, history: history)!;
      expect(seen.add(s.id), isTrue, reason: '${s.id} came back too early');
    }
    // Bag is empty now: the next pick refills it instead of failing.
    expect(engine.pick(now: monday, enabled: {SurpriseType.quiz}, history: history), isNotNull);
  });

  test('every quiz has three options and a valid answer', () {
    for (final q in starterContent.where((s) => s.type == SurpriseType.quiz)) {
      expect(q.options.length, 3, reason: q.id);
      expect(q.answerIndex, inInclusiveRange(0, 2), reason: q.id);
    }
  });

  test('quiz is read with its options and feedback names the right answer', () {
    const q = Surprise(id: 'q', type: SurpriseType.quiz, text: 'Which is biggest?',
        options: ['Ant', 'Whale', 'Cat'], answerIndex: 1, fact: 'Whales are huge.');
    expect(q.spokenText, 'Which is biggest? A: Ant. B: Whale. C: Cat. Tap your answer.');
    expect(q.quizFeedback(1), 'Correct, well done! Whales are huge.');
    expect(q.quizFeedback(0), 'Not quite. The answer is B: Whale. Whales are huge.');
    expect(q.needsResponse, isTrue);
  });

  test('weekend picks skip weekday-only items', () {
    final engine = SurpriseEngine(content: starterContent, random: Random(3));
    final history = SurpriseHistory();
    for (var i = 0; i < 200; i++) {
      final s = engine.pick(now: saturday, enabled: all, history: history)!;
      expect(s.dayFit, isNot(DayFit.weekday));
    }
  });

  test('history survives a save and load', () {
    final h = SurpriseHistory(lastType: SurpriseType.song, usedIds: {'s01', 'q02'});
    final back = SurpriseHistory.fromJson(h.toJson());
    expect(back.lastType, SurpriseType.song);
    expect(back.usedIds, {'s01', 'q02'});
    expect(SurpriseHistory.fromJson('not json').usedIds, isEmpty);
  });

  test('nothing enabled gives no surprise', () {
    final engine = SurpriseEngine(content: starterContent);
    expect(engine.pick(now: monday, enabled: {}, history: SurpriseHistory()), isNull);
  });

  test('morning message greets by name and announces the surprise', () {
    const song = Surprise(id: 'x', type: SurpriseType.song, text: 'Lovely Day', artist: 'Bill Withers');
    expect(
      song.morningMessage(''),
      "Hello there, it's the morning. "
      'I know you want to keep sleeping, but I have a surprise for you to start your day. '
      'Your surprise is a radio station. Lovely Day, by Bill Withers.',
    );
    expect(song.morningMessage(' Jana '), startsWith("Hello there, Jana, it's the morning."));
  });

  test('speech is split into sentences, but not after "Mr." or initials', () {
    expect(
      Speaker.splitSentences('Your surprise is a song. Mr. Blue Sky, by ELO. Not all those who wander are lost. By J. R. R. Tolkien.'),
      ['Your surprise is a song.', 'Mr. Blue Sky, by ELO.', 'Not all those who wander are lost.', 'By J. R. R. Tolkien.'],
    );
  });

  test('German voice gets the German greeting and content', () {
    const q = Surprise(id: 'q', type: SurpriseType.quiz, text: 'Which is biggest?',
        options: ['Ant', 'Whale', 'Cat'], answerIndex: 1,
        textDe: 'Was ist am größten?', optionsDe: ['Ameise', 'Wal', 'Katze']);
    expect(
      q.morningMessage('Jana', Lang.de),
      'Hallooooooo Jana, es ist Zeit zum Aufstehen. Ich weiß, du willst wahrscheinlich lieber '
      'weiterschlafen, aber ich habe eine Überraschung für dich, mit der dein Tag gut beginnt. Deine Überraschung ist ein kleines Quiz. '
      'Was ist am größten? A: Ameise. B: Wal. C: Katze. Tippe auf deine Antwort.',
    );
    expect(q.quizFeedback(0, Lang.de), 'Nicht ganz. Die richtige Antwort ist B: Wal.');
  });

  test('all quizzes, challenges and riddles have a German version', () {
    for (final s in starterContent.where((s) => s.type != SurpriseType.song)) {
      expect(s.textDe, isNotNull, reason: s.id);
      if (s.type == SurpriseType.quiz) expect(s.optionsDe.length, 3, reason: s.id);
    }
  });

  test('every riddle has an answer in both languages', () {
    final riddles = starterContent.where((s) => s.type == SurpriseType.riddle).toList();
    expect(riddles, isNotEmpty);
    for (final r in riddles) {
      expect(r.answer, isNotNull, reason: r.id);
      expect(r.answerDe, isNotNull, reason: r.id);
      expect(r.needsResponse, isTrue);
    }
    expect(riddles.first.riddleAnswerIn(Lang.de), startsWith('Die Lösung ist:'));
  });

  test('everything but songs waits for I am awake', () {
    for (final s in starterContent) {
      expect(s.needsResponse, s.type != SurpriseType.song, reason: s.id);
    }
    expect(Surprise.imUpLabel(Lang.de), 'Ich bin wach');
  });

  test('every radio station has a stream address and a German description', () {
    final radios = starterContent.where((s) => s.type == SurpriseType.song).toList();
    expect(radios, isNotEmpty);
    for (final r in radios) {
      expect(r.streamUrls, isNotEmpty, reason: r.id);
      expect(r.moodDe, isNotNull, reason: r.id);
    }
    expect(radios.first.spokenIn(Lang.de), contains('.'));
  });

  test('content ids are unique', () {
    final ids = starterContent.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
