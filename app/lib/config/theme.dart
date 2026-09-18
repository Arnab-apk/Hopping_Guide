import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pandal_theme_tokens.dart';

/// Design tokens matching the Google Material 3 / Material You aesthetic
/// adapted for Kolkata Durga Puja. Combines authentic Google tonal surfaces,
/// pill indicators, stadium search bars, and crisp Google typography.
class PujaColors {
  PujaColors._();

  // Crimson & Burgundy Tones (Google Carmine Seed)
  static const Color durgaRed = Color(0xFFB71C1C);
  static const Color durgaRedDark = Color(0xFF5B0E1B);
  static const Color crimsonVelvet = Color(0xFF3A0810);
  static const Color durgaRedLight = Color(0xFFD32F2F);

  // Sacred Gold Tones (Refined Material You Warm Accents)
  static const Color festivalGold = Color(0xFFDCA830);
  static const Color goldBright = Color(0xFFF3C759);
  static const Color goldSoft = Color(0xFFF6EEDC);

  // Surfaces & Backgrounds (Google M3 Tonal Surfaces)
  static const Color ivoryBg = Color(0xFFFDF8F7);
  static const Color nightBg = Color(0xFF141213);
  static const Color nightCard = Color(0xFF1E1A1B);
  static const Color nightSurface = Color(0xFF2B2425);
  static const Color nightBorder = Color(0xFF44383A);

  // Status & Badges (Google Standard Status Colors)
  static const Color crowdLow = Color(0xFF1E8E3E);     // Google Green
  static const Color crowdMedium = Color(0xFFE37400);  // Google Amber
  static const Color crowdHigh = Color(0xFFD93025);    // Google Red

  // Transit lines
  static const Color metroBlue = Color(0xFF1A73E8);     // Google Blue
  static const Color railwayPurple = Color(0xFF9334E6); // Google Purple
}

/// Centralized light theme: Google Material Design 3 / Material You
ThemeData get appTheme {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: PujaColors.durgaRed,
    brightness: Brightness.light,
    surface: const Color(0xFFFDF8F7),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 74,
      elevation: 1.5,
      backgroundColor: colorScheme.surfaceContainer,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
        );
      }),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(1.5),
      backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerHigh),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      hintStyle: WidgetStatePropertyAll(
        GoogleFonts.plusJakartaSans(
          fontSize: 14.5,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.secondaryContainer,
      secondarySelectedColor: colorScheme.secondaryContainer,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: colorScheme.onSurface,
      ),
      secondaryLabelStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSecondaryContainer,
        fontSize: 12,
      ),
      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.7), width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 2.5,
      shape: const CircleBorder(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHigh,
        foregroundColor: colorScheme.primary,
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outlineVariant, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      },
    ),
    splashColor: colorScheme.primary.withValues(alpha: 0.08),
    highlightColor: colorScheme.primary.withValues(alpha: 0.04),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    extensions: const [
      PandalOfflineThemeTokens(),
    ],
  );
}

/// Centralized dark theme: Google Material Design 3 / Material You Dark
ThemeData get appDarkTheme {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: PujaColors.durgaRed,
    brightness: Brightness.dark,
    surface: const Color(0xFF141213),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 74,
      elevation: 1.5,
      backgroundColor: colorScheme.surfaceContainer,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
        );
      }),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(1.5),
      backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerHigh),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      hintStyle: WidgetStatePropertyAll(
        GoogleFonts.plusJakartaSans(
          fontSize: 14.5,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.secondaryContainer,
      secondarySelectedColor: colorScheme.secondaryContainer,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: colorScheme.onSurface,
      ),
      secondaryLabelStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSecondaryContainer,
        fontSize: 12,
      ),
      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 2.5,
      shape: const CircleBorder(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHigh,
        foregroundColor: colorScheme.onSurface,
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outlineVariant, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      },
    ),
    splashColor: colorScheme.primary.withValues(alpha: 0.12),
    highlightColor: colorScheme.primary.withValues(alpha: 0.05),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    extensions: const [
      PandalOfflineThemeTokens(),
    ],
  );
}
