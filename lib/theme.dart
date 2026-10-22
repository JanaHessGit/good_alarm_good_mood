import 'package:flutter/material.dart';

import 'surprise/surprise.dart';

/// Deep royal blue, white and a coral accent, matching the Dawnbox screen sketches.
class DawnColors {
  static const royal = Color(0xFF213E9A);
  static const coral = Color(0xFFFF9E8F);
  static const royalDeep = Color(0xFF1E3A9E);
  static const royalSoft = Color(0xFFE8EEFC);
  static const royalLine = Color(0xFFB7C7F5);
  static const royalTrack = Color(0xFF4A64B5);
  static const onRoyalMuted = Color(0xFFF2F5FE);
  static const ink = Color(0xFF1B1E2B);
  static const muted = Color(0xFF4A5578);
  static const ground = Colors.white;

  static Color backgroundFor(SurpriseType type) => Colors.white;

  static IconData iconFor(SurpriseType type) => switch (type) {
        SurpriseType.quiz => Icons.quiz_outlined,
        SurpriseType.song => Icons.music_note_rounded,
        SurpriseType.adventure => Icons.explore_outlined,
        SurpriseType.story => Icons.auto_stories_outlined,
      };
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DawnColors.royal,
        primary: DawnColors.royal,
        secondary: DawnColors.coral,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: DawnColors.ground,
    );
