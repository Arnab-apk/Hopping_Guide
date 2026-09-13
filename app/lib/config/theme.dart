import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens matching Theme 1: Crimson Gold Line Art
/// Palette: Deep Velvet Crimson, Royal Warm Gold, Ivory, and Dark Burgundy Night
class PujaColors {
  PujaColors._();

  // Crimson & Burgundy Tones
  static const Color durgaRed = Color(0xFFB71C1C);
  static const Color durgaRedDark = Color(0xFF5B0E1B);
  static const Color crimsonVelvet = Color(0xFF3A0810);
  static const Color durgaRedLight = Color(0xFFD32F2F);

  // Sacred Gold Tones (Theme 1 Line Art Accents)
  static const Color festivalGold = Color(0xFFDCA830);
  static const Color goldBright = Color(0xFFF3C759);
  static const Color goldSoft = Color(0xFFF6EEDC);

  // Surfaces & Backgrounds (Pure Minimalist OLED Dark & Clean Ivory)
  static const Color ivoryBg = Color(0xFFFFF8F0);
  static const Color nightBg = Color(0xFF0A0A0A);
  static const Color nightCard = Color(0xFF141414);
  static const Color nightSurface = Color(0xFF1E1E1E);
  static const Color nightBorder = Color(0xFF282828);

  // Status & Badges
  static const Color crowdLow = Color(0xFF3FA34D);
  static const Color crowdMedium = Color(0xFFE67E22);
  static const Color crowdHigh = Color(0xFFC0392B);

  // Transit lines
  static const Color metroBlue = Color(0xFF2E6BE6);
  static const Color railwayPurple = Color(0xFF8E44AD);
}

/// Centralized light theme matching Theme 1
ThemeData get appTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PujaColors.durgaRed,
        primary: PujaColors.durgaRed,
        secondary: PujaColors.festivalGold,
        surface: PujaColors.ivoryBg,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: PujaColors.ivoryBg,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: PujaColors.crimsonVelvet,
        foregroundColor: PujaColors.goldBright,
        elevation: 1,
        shadowColor: Colors.black26,
        iconTheme: const IconThemeData(color: PujaColors.goldBright),
        actionsIconTheme: const IconThemeData(color: PujaColors.goldBright),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: PujaColors.goldBright,
          fontSize: 18.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: PujaColors.crimsonVelvet.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: PujaColors.festivalGold.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: PujaColors.crimsonVelvet,
        secondarySelectedColor: PujaColors.crimsonVelvet,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w700, color: PujaColors.goldBright, fontSize: 12),
        side: BorderSide(color: PujaColors.festivalGold.withValues(alpha: 0.35), width: 1),
        shape: const StadiumBorder(),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: PujaColors.crimsonVelvet,
        foregroundColor: PujaColors.goldBright,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: PujaColors.festivalGold.withValues(alpha: 0.4), width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PujaColors.crimsonVelvet,
          foregroundColor: PujaColors.goldBright,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: PujaColors.festivalGold.withValues(alpha: 0.4)),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: PujaColors.crimsonVelvet,
          foregroundColor: PujaColors.goldBright,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: PujaColors.festivalGold.withValues(alpha: 0.3)),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PujaColors.crimsonVelvet,
          side: BorderSide(color: PujaColors.festivalGold.withValues(alpha: 0.5), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashColor: PujaColors.festivalGold.withValues(alpha: 0.12),
      highlightColor: PujaColors.festivalGold.withValues(alpha: 0.06),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: PujaColors.festivalGold,
        unselectedItemColor: Color(0xFF757575),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
    );

/// Dark theme: Pure Minimalist OLED Dark (#0A0A0A) & Sacred Gold Accents
ThemeData get appDarkTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PujaColors.durgaRed,
        primary: PujaColors.durgaRedLight,
        secondary: PujaColors.goldBright,
        surface: PujaColors.nightCard,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: PujaColors.nightBg,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: PujaColors.nightCard,
        foregroundColor: PujaColors.goldBright,
        elevation: 0,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(color: PujaColors.goldBright),
        actionsIconTheme: const IconThemeData(color: PujaColors.goldBright),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: PujaColors.goldBright,
          fontSize: 18.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
      cardTheme: CardThemeData(
        color: PujaColors.nightCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: PujaColors.nightBorder,
            width: 1,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: PujaColors.nightCard,
        selectedColor: PujaColors.nightSurface,
        secondarySelectedColor: PujaColors.nightSurface,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70, fontSize: 12),
        secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w700, color: PujaColors.goldBright, fontSize: 12),
        side: const BorderSide(color: PujaColors.nightBorder, width: 1),
        shape: const StadiumBorder(),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: PujaColors.nightSurface,
        foregroundColor: PujaColors.goldBright,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PujaColors.nightBorder, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PujaColors.nightSurface,
          foregroundColor: PujaColors.goldBright,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: PujaColors.nightBorder),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: PujaColors.durgaRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PujaColors.goldBright,
          side: const BorderSide(color: PujaColors.nightBorder, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashColor: PujaColors.festivalGold.withValues(alpha: 0.12),
      highlightColor: PujaColors.festivalGold.withValues(alpha: 0.05),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: PujaColors.nightCard,
        selectedItemColor: PujaColors.goldBright,
        unselectedItemColor: Color(0xFF888888),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
