/// Design system constants — colors, gradients, and shared styles.
library;

import 'package:flutter/material.dart';

// ── Color Palette ────────────────────────────────────────────────────────────
abstract final class AppColors {
  // Background
  static const Color bgDark = Color(0xFF0B0E1A);
  static const Color bgCard = Color(0xFF141828);
  static const Color bgCardLight = Color(0xFF1C2240);

  // Primary gradient (blue → violet)
  static const Color primaryStart = Color(0xFF4F6BF6);
  static const Color primaryEnd = Color(0xFF9B59F7);

  // Accent
  static const Color accent = Color(0xFFFFB84D);
  static const Color accentSoft = Color(0x33FFB84D);

  // Status colors
  static const Color working = Color(0xFF00E676);
  static const Color overtime = Color(0xFFFF9800);
  static const Color liquidatable = Color(0xFFFF5252);
  static const Color notStarted = Color(0xFF78909C);

  // Text
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF8B8FAD);
  static const Color textMuted = Color(0xFF545978);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryStart, primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A2040), Color(0xFF141828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient workingGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00E676)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient overtimeGradient = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF9800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient liquidatableGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ── Theme ────────────────────────────────────────────────────────────────────
ThemeData appTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryStart,
      secondary: AppColors.accent,
      surface: AppColors.bgCard,
    ),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: -0.3,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgCardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),
  );
}
