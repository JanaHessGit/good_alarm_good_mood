import 'dart:convert';
import 'dart:math';

import 'surprise.dart';

/// What the engine remembers between mornings.
class SurpriseHistory {
  SurpriseHistory({this.lastType, Set<String>? usedIds})
      : usedIds = usedIds ?? <String>{};

  /// The type delivered last time, so the next pick can be a different one.
  SurpriseType? lastType;

  /// Ids already shown. Works like a shuffle bag per type: an item comes back
  /// only after every other item of its type has been shown.
  final Set<String> usedIds;

  String toJson() => jsonEncode({
        'lastType': lastType?.name,
        'usedIds': usedIds.toList(),
      });

  factory SurpriseHistory.fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return SurpriseHistory();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final typeName = map['lastType'] as String?;
      SurpriseType? last;
      for (final t in SurpriseType.values) {
        if (t.name == typeName) last = t;
      }
      return SurpriseHistory(
        lastType: last,
        usedIds: ((map['usedIds'] as List?) ?? const [])
            .map((e) => e.toString())
            .toSet(),
      );
    } catch (_) {
      return SurpriseHistory();
    }
  }
}

/// Picks the morning surprise.
///
/// Rules, in order:
/// 1. Only enabled types that have at least one item fitting today
///    (weekday/weekend) are candidates.
/// 2. If more than one type is possible, yesterday's type is left out,
///    so you never get two quotes in a row.
/// 3. A type is drawn at random, weighted by [weights] (default: equal).
/// 4. Within the type, an unseen item fitting today is drawn at random.
///    When all of them have been seen, that type's bag is refilled.
/// 5. The pick is written into [SurpriseHistory].
class SurpriseEngine {
  SurpriseEngine({required this.content, Random? random})
      : _random = random ?? Random();

  final List<Surprise> content;
  final Random _random;

  Surprise? pick({
    required DateTime now,
    required Set<SurpriseType> enabled,
    required SurpriseHistory history,
    Map<SurpriseType, int> weights = const {},
  }) {
    List<Surprise> itemsFor(SurpriseType type) =>
        content.where((s) => s.type == type && s.fits(now)).toList();

    // Rule 1
    var types = enabled
        .where((t) => (weights[t] ?? 1) > 0 && itemsFor(t).isNotEmpty)
        .toList();
    if (types.isEmpty) return null;

    // Rule 2
    if (types.length > 1 && history.lastType != null) {
      types = types.where((t) => t != history.lastType).toList();
    }

    // Rule 3
    final type = _weightedType(types, weights);

    // Rule 4
    final items = itemsFor(type);
    var fresh = items.where((s) => !history.usedIds.contains(s.id)).toList();
    if (fresh.isEmpty) {
      final idsOfType =
          content.where((s) => s.type == type).map((s) => s.id).toSet();
      history.usedIds.removeAll(idsOfType);
      fresh = items;
    }
    final surprise = fresh[_random.nextInt(fresh.length)];

    // Rule 5
    history.lastType = type;
    history.usedIds.add(surprise.id);
    return surprise;
  }

  SurpriseType _weightedType(
    List<SurpriseType> types,
    Map<SurpriseType, int> weights,
  ) {
    final total = types.fold<int>(0, (sum, t) => sum + (weights[t] ?? 1));
    var roll = _random.nextInt(total);
    for (final t in types) {
      roll -= weights[t] ?? 1;
      if (roll < 0) return t;
    }
    return types.last;
  }
}
