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
        SurpriseType.song => Icons.radio_rounded,
        SurpriseType.challenge => Icons.explore_outlined,
        SurpriseType.riddle => Icons.lightbulb_outline,
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
      // Any other chip: selected = the dark blue of the alarm card.
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? DawnColors.royal : Colors.white,
        ),
        checkmarkColor: Colors.white,
        side: const BorderSide(color: DawnColors.royal),
      ),
      // Selected buttons (e.g. EN / DE) use the dark blue of the alarm card.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? DawnColors.royal : Colors.white,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? Colors.white : DawnColors.royal,
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: DawnColors.royal)),
          // Also no lighter tint while pressing a selected button.
          overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.12)),
        ),
      ),
    );
