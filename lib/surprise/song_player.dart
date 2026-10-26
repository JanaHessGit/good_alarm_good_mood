import 'package:shared_preferences/shared_preferences.dart';

import 'content.dart';
import 'radio_player.dart';
import 'surprise.dart';

/// Music for the surprise, "Play radio" and the check-in: a free radio
/// station played inside the app (see RadioPlayer), so it also works on a
/// locked phone, needs no account and no other app.
class SongPlayer {
  static const _kFavourite = 'radio_station';

  /// All radio stations in the app.
  static List<Surprise> get stations => starterContent
      .where((s) => s.type == SurpriseType.song && s.streamUrls.isNotEmpty)
      .toList();

  /// The station chosen in the settings, or null for "surprise me" (random).
  static Future<String?> favouriteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kFavourite);
  }

  static Future<void> setFavourite(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_kFavourite);
    } else {
      await prefs.setString(_kFavourite, id);
    }
  }

  static Future<Surprise?> _favourite() async {
    final id = await favouriteId();
    for (final s in stations) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Radio surprise: plays the announced [station]. If it doesn't play,
  /// the other stations are tried.
  static Future<bool> play(Surprise station) async {
    if (await RadioPlayer.shared.play(station)) return true;
    return _tryOthers(except: station);
  }

  /// "Play radio": the favourite station, or a random one.
  static Future<bool> playSurpriseSongs() async {
    final fav = await _favourite();
    if (fav != null && await RadioPlayer.shared.play(fav)) return true;
    return _tryOthers(except: fav);
  }

  static Future<bool> _tryOthers({Surprise? except}) async {
    final list = stations.where((s) => s.id != except?.id).toList()..shuffle();
    for (final s in list) {
      if (await RadioPlayer.shared.play(s)) return true;
    }
    return false;
  }

  static Future<void> stop() => RadioPlayer.shared.stop();
}
