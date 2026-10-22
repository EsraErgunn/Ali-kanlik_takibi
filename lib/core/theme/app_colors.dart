import 'package:flutter/material.dart';

/// Design tokens for BloomHabit "Botanical Vitality" palette.
class AppColors {
  const AppColors._();

  // Primary: Forest Emerald
  static const Color primary = Color(0xFF1B6B48);
  static const Color primaryDark = Color(0xFF0F4A31);
  static const Color primaryContainer = Color(0xFFDCEFE3);

  // Secondary: Warm Coral / Flame (Quit / Relapse / Streak Flame)
  static const Color secondary = Color(0xFFF07152);
  static const Color secondaryContainer = Color(0xFFFDE3DB);

  // Tertiary: Golden Amber (Savings / XP / Shield Joker)
  static const Color tertiary = Color(0xFFECA038);
  static const Color tertiaryContainer = Color(0xFFFBEBCF);

  // Neutrals (Light)
  static const Color neutral = Color(0xFF2B2824);
  static const Color neutralVariant = Color(0xFF6E6862);
  static const Color background = Color(0xFFFBF7F2); // Warm Cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF3EEE8);
  static const Color outline = Color(0xFFE7E0D8);

  // Neutrals (Dark)
  static const Color darkBackground = Color(0xFF141311);
  static const Color darkSurface = Color(0xFF1E1C1A);
  static const Color darkSurfaceMuted = Color(0xFF2A2724);
  static const Color darkPrimary = Color(0xFF7FD1A6);
  static const Color darkNeutral = Color(0xFFF3EEE8);
  static const Color darkNeutralVariant = Color(0xFFA8A29E);
  static const Color darkOutline = Color(0xFF33312E);

  // Soft shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
