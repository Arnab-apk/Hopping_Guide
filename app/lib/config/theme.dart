import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pandal_theme_tokens.dart';
export 'app_colors.dart';

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
  static const Color crowdLow = Color(0xFF1E8E3E); // Google Green
  static const Color crowdMedium = Color(0xFFE37400); // Google Amber
  static const Color crowdHigh = Color(0xFFD93025); // Google Red

  // Transit lines
  static const Color metroBlue = Color(0xFF1A73E8); // Google Blue
  static const Color railwayPurple = Color(0xFF9334E6); // Google Purple
}

/// Centralized light theme: Google Material Design 3 / Material You
ThemeData get appTheme {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: PujaColors.durgaRed,
    brightness: Brightness.light,
    surface: const Color(0xFFFDF8F7),
  );

  return _polishTheme(
    ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ),
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
            color: isSelected
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: isSelected
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(1.5),
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerHigh,
        ),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        hintStyle: WidgetStatePropertyAll(
          GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          width: 1,
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      extensions: const [PandalOfflineThemeTokens()],
    ),
  );
}

/// Centralized dark theme: Google Material Design 3 / Material You Dark
ThemeData get appDarkTheme {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: PujaColors.durgaRed,
    brightness: Brightness.dark,
    surface: const Color(0xFF141213),
  );

  return _polishTheme(
    ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ),
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
            color: isSelected
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: isSelected
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(1.5),
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerHigh,
        ),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        hintStyle: WidgetStatePropertyAll(
          GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      extensions: const [PandalOfflineThemeTokens()],
    ),
  );
}

ThemeData _polishTheme(ThemeData theme) {
  final isDark = theme.brightness == Brightness.dark;
  final colors = theme.colorScheme.copyWith(
    primary: isDark ? const Color(0xFFFFB4AC) : const Color(0xFFA32935),
    onPrimary: isDark ? const Color(0xFF5D101D) : Colors.white,
    primaryContainer: isDark
        ? const Color(0xFF48252D)
        : const Color(0xFFFBE6E8),
    onPrimaryContainer: isDark
        ? const Color(0xFFFFDADD)
        : const Color(0xFF771D2B),
    secondaryContainer: isDark
        ? const Color(0xFF3E3035)
        : const Color(0xFFF4E8EA),
    onSecondaryContainer: isDark
        ? const Color(0xFFF1DADF)
        : const Color(0xFF53333B),
    surface: isDark ? const Color(0xFF141416) : const Color(0xFFF7F7F8),
    surfaceContainerLowest: isDark ? const Color(0xFF101012) : Colors.white,
    surfaceContainerLow: isDark ? const Color(0xFF1D1D21) : Colors.white,
    surfaceContainer: isDark
        ? const Color(0xFF232328)
        : const Color(0xFFF0F0F3),
    surfaceContainerHigh: isDark
        ? const Color(0xFF2B2B31)
        : const Color(0xFFEDEDF1),
    surfaceContainerHighest: isDark
        ? const Color(0xFF35353D)
        : const Color(0xFFE4E4EA),
    onSurface: isDark ? const Color(0xFFF2F0F4) : const Color(0xFF222127),
    onSurfaceVariant: isDark
        ? const Color(0xFFC4C0CA)
        : const Color(0xFF5D5864),
    outline: isDark ? const Color(0xFF8E8795) : const Color(0xFF79717F),
    outlineVariant: isDark ? const Color(0xFF414047) : const Color(0xFFDDD9E1),
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  const target = Size(48, 48);
  final buttons = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(target),
    tapTargetSize: MaterialTapTargetSize.padded,
    shape: WidgetStatePropertyAll(shape),
  );
  return theme.copyWith(
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    canvasColor: colors.surface,
    textTheme: theme.textTheme
        .copyWith(
          headlineSmall: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
            height: 1.2,
          ),
          titleLarge: theme.textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleMedium: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
          bodyLarge: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.5,
          ),
          bodyMedium: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.5,
          ),
          bodySmall: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            height: 1.4,
          ),
        )
        .apply(bodyColor: colors.onSurface, displayColor: colors.onSurface),
    appBarTheme: theme.appBarTheme.copyWith(
      centerTitle: false,
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: colors.onSurface, size: 24),
      actionsIconTheme: IconThemeData(color: colors.onSurface, size: 24),
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
        letterSpacing: -0.4,
      ),
    ),
    navigationBarTheme: theme.navigationBarTheme.copyWith(
      backgroundColor: colors.surfaceContainerLow,
      indicatorColor: colors.primaryContainer,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => theme.textTheme.labelMedium?.copyWith(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? colors.primary
              : colors.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? colors.onPrimaryContainer
              : colors.onSurfaceVariant,
        ),
      ),
    ),
    searchBarTheme: theme.searchBarTheme.copyWith(
      backgroundColor: WidgetStatePropertyAll(colors.surfaceContainerLow),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      hintStyle: WidgetStatePropertyAll(
        TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
      ),
    ),
    chipTheme: theme.chipTheme.copyWith(
      backgroundColor: colors.surfaceContainerLow,
      selectedColor: colors.primaryContainer,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: theme.textTheme.labelMedium?.copyWith(
        color: colors.onPrimaryContainer,
      ),
      side: BorderSide(color: colors.outlineVariant),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colors.primary,
      textColor: colors.onSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: theme.textTheme.bodyMedium?.copyWith(
        color: colors.onSurfaceVariant,
        height: 1.4,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface),
    ),
    floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      elevation: 2,
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    filledButtonTheme: FilledButtonThemeData(
      style: theme.filledButtonTheme.style
          ?.merge(buttons)
          .copyWith(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? colors.onSurface.withValues(alpha: 0.12)
                  : colors.primary,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? colors.onSurface.withValues(alpha: 0.38)
                  : colors.onPrimary,
            ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: theme.outlinedButtonTheme.style
          ?.merge(buttons)
          .copyWith(foregroundColor: WidgetStatePropertyAll(colors.primary)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: theme.elevatedButtonTheme.style
          ?.merge(buttons)
          .copyWith(
            backgroundColor: WidgetStatePropertyAll(
              colors.surfaceContainerHigh,
            ),
            foregroundColor: WidgetStatePropertyAll(colors.primary),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: target,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: shape,
        foregroundColor: colors.primary,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: target,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: colors.secondaryContainer,
        selectedForegroundColor: colors.onSecondaryContainer,
        backgroundColor: colors.surfaceContainerLow,
        foregroundColor: colors.onSurfaceVariant,
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.5),
          width: 0.8,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: colors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: colors.onSurfaceVariant),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
          width: 0.8,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.primary, width: 1.8),
      ),
      errorMaxLines: 3,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.4),
          width: 0.8,
        ),
      ),
      constraints: const BoxConstraints(maxWidth: 560),
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: theme.textTheme.bodyMedium?.copyWith(
        color: colors.onSurfaceVariant,
        height: 1.5,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surfaceContainerLow,
      modalBackgroundColor: colors.surfaceContainerLow,
      showDragHandle: true,
      dragHandleColor: colors.onSurfaceVariant.withValues(alpha: 0.35),
      dragHandleSize: const Size(36, 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: const BoxConstraints(maxWidth: 640),
      clipBehavior: Clip.antiAlias,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.inverseSurface,
      contentTextStyle: TextStyle(
        color: colors.onInverseSurface,
        fontSize: 14,
        height: 1.4,
      ),
      actionTextColor: colors.inversePrimary,
      showCloseIcon: true,
      closeIconColor: colors.onInverseSurface,
      shape: shape,
      elevation: 6,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 500),
      showDuration: const Duration(seconds: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 280),
      textStyle: TextStyle(color: colors.onInverseSurface, fontSize: 13),
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colors.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.5),
      thickness: 0.7,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.primary,
      linearMinHeight: 3,
    ),
  );
}
