/// The kinds of surprise Dawnbox can deliver after the alarm.
enum SurpriseType { quiz, song, adventure, story }

/// Language of everything the voice says. Follows the chosen voice.
enum Lang { en, de }

/// Picks the English or German version of a text.
String tr(Lang lang, String en, String de) => lang == Lang.de ? de : en;

extension SurpriseTypeLabel on SurpriseType {
  String get label => labelIn(Lang.en);

  String labelIn(Lang lang) => switch (this) {
        SurpriseType.quiz => 'Quiz',
        SurpriseType.song => 'Song',
        SurpriseType.adventure => tr(lang, 'Mini adventure', 'Mini-Abenteuer'),
        SurpriseType.story => tr(lang, 'Story time', 'Geschichte'),
      };
}

/// Which days an item fits. Lets weekend-only adventures stay off Mondays.
enum DayFit { any, weekday, weekend }

/// One piece of surprise content, in English and (optionally) German.
class Surprise {
  const Surprise({
    required this.id,
    required this.type,
    required this.text,
    this.textDe,
    this.artist,
    this.spotifyId,
    this.options = const [],
    this.optionsDe = const [],
    this.answerIndex = 0,
    this.fact,
    this.factDe,
    this.title,
    this.titleDe,
    this.mood,
    this.moodDe,
    this.dayFit = DayFit.any,
  });

  /// Stable id, used to avoid repeats. Never reuse an id for different text.
  final String id;
  final SurpriseType type;

  /// Quiz question, song title, adventure description or the whole story.
  final String text;
  final String? textDe;

  /// Song artist (songs only).
  final String? artist;

  /// Spotify track id (songs only), the part after open.spotify.com/track/.
  final String? spotifyId;

  /// Quiz: exactly three answer options, and which one is right (0, 1 or 2).
  final List<String> options;
  final List<String> optionsDe;
  final int answerIndex;

  /// Quiz: a short fun fact read after the answer.
  final String? fact;
  final String? factDe;

  /// Story: title and mood ("Funny", "Heartwarming", ...).
  final String? title;
  final String? titleDe;
  final String? mood;
  final String? moodDe;

  final DayFit dayFit;

  // --- Language-aware getters (German falls back to English if missing) ---

  bool _de(Lang l) => l == Lang.de;
  String textIn(Lang l) => _de(l) ? (textDe ?? text) : text;
  List<String> optionsIn(Lang l) =>
      _de(l) && optionsDe.length == options.length ? optionsDe : options;
  String? factIn(Lang l) => _de(l) ? (factDe ?? fact) : fact;
  String? titleIn(Lang l) => _de(l) ? (titleDe ?? title) : title;
  String? moodIn(Lang l) => _de(l) ? (moodDe ?? mood) : mood;

  bool fits(DateTime day) {
    final weekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    return switch (dayFit) {
      DayFit.any => true,
      DayFit.weekday => !weekend,
      DayFit.weekend => weekend,
    };
  }

  /// Quiz and adventure keep asking until the user taps a button, so a
  /// half-asleep person can't just ignore them.
  bool get needsResponse =>
      type == SurpriseType.quiz || type == SurpriseType.adventure;

  static const letters = ['A', 'B', 'C'];

  /// Label of the adventure confirm button (also said by the voice).
  static String imUpLabel(Lang l) => tr(l, "I'm up", 'Ich bin wach');

  /// The surprise itself, read aloud. English unless [lang] is given.
  String get spokenText => spokenIn(Lang.en);

  String spokenIn(Lang l) {
    switch (type) {
      case SurpriseType.quiz:
        final opts = optionsIn(l);
        final list = [for (var i = 0; i < opts.length; i++) '${letters[i]}: ${opts[i]}.'].join(' ');
        return '${textIn(l)} $list ${tr(l, 'Tap your answer.', 'Tippe auf deine Antwort.')}';
      case SurpriseType.song:
        return '$text, ${tr(l, 'by', 'von')} $artist.';
      case SurpriseType.adventure:
        return '${textIn(l)} ${tr(l, "Tap I'm up, when you're out of bed.", 'Tippe auf Ich bin wach, sobald du aufgestanden bist.')}';
      case SurpriseType.story:
        return '${titleIn(l) ?? tr(l, 'A little story', 'Eine kleine Geschichte')}. ${textIn(l)}';
    }
  }

  /// Said every 10 seconds while nobody has tapped yet.
  String get repeatText => repeatIn(Lang.en);

  String repeatIn(Lang l) => switch (type) {
        SurpriseType.quiz =>
          '${tr(l, 'Still waiting for your answer!', 'Ich warte noch auf deine Antwort!')} ${spokenIn(l)}',
        SurpriseType.adventure =>
          '${tr(l, "Still in bed? Here's your mini adventure again.", 'Noch im Bett? Hier ist noch mal dein Mini-Abenteuer.')} ${spokenIn(l)}',
        _ => spokenIn(l),
      };

  /// How the greeting announces this kind of surprise.
  String get announcement => announcementIn(Lang.en);

  String announcementIn(Lang l) => switch (type) {
        SurpriseType.quiz => tr(l, 'a little quiz', 'ein kleines Quiz'),
        SurpriseType.song => tr(l, 'a song', 'ein Song'),
        SurpriseType.adventure => tr(l, 'a mini adventure', 'ein Mini-Abenteuer'),
        SurpriseType.story => tr(l, 'a story', 'eine Geschichte'),
      };

  /// Used by "Another one".
  String anotherIn(Lang l) =>
      '${tr(l, 'Here is', 'Hier ist')} ${announcementIn(l)}. ${spokenIn(l)}';

  /// What the voice says after a quiz answer.
  String quizFeedback(int picked, [Lang l = Lang.en]) {
    final opts = optionsIn(l);
    final head = picked == answerIndex
        ? tr(l, 'Correct, well done!', 'Richtig, super gemacht!')
        : tr(l, 'Not quite. The answer is', 'Nicht ganz. Die richtige Antwort ist') +
            ' ${letters[answerIndex]}: ${opts[answerIndex]}.';
    final f = factIn(l);
    return f == null ? head : '$head $f';
  }

  /// The full wake-up message: greeting first, then the surprise.
  String morningMessage(String name, [Lang l = Lang.en]) {
    final n = name.trim();
    final greeting = l == Lang.de
        ? 'Hallooooooo${n.isEmpty ? '' : ' $n'}, es ist Zeit zum Aufstehen. '
            'Ich weiß, du willst wahrscheinlich lieber weiterschlafen, aber ich habe eine '
            'Überraschung für dich, mit der dein Tag gut beginnt. '
        : "Hello there${n.isEmpty ? '' : ', $n'}, it's the morning. "
            'I know you want to keep sleeping, but I have a surprise for you to start your day. ';
    return '$greeting${tr(l, 'Your surprise is', 'Deine Überraschung ist')} '
        '${announcementIn(l)}. ${spokenIn(l)}';
  }

  /// Search text for opening the song in a music app.
  String get songQuery => '$text ${artist ?? ''}'.trim();
}
