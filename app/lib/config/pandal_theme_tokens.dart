import 'package:flutter/material.dart';

/// Design system tokens for offline-resilient UI and OLED-safe dark mode.
///
/// Designed with WCAG AAA contrast ratios and an OLED-safe card surface (`0xFF16171D`)
/// that avoids pure #000000 black to prevent OLED pixel turn-off latency and scroll smearing.
@immutable
class PandalOfflineThemeTokens extends ThemeExtension<PandalOfflineThemeTokens> {
  // Brand Foundation
  final Color crimsonVelvet;     // 0xFF800020
  final Color festivalGold;      // 0xFFFFD700
  final Color nightSurface;      // 0xFF0E0E10

  // Card Surfaces & Borders (OLED-safe, prevents smearing)
  final Color surfaceCard;        // 0xFF16171D
  final Color surfaceElevated;    // 0xFF22232C
  final Color borderSubtle;       // 0xFF2E303D
  final Color borderFocused;      // 0xFF4F5269

  // Status Badges & Telemetry
  final Color offlineBg;          // 0xFF10281C
  final Color offlineFg;          // 0xFF4ADE80
  final Color staleBg;            // 0xFF2C1F0E
  final Color staleFg;            // 0xFFFBBF24
  final Color liveCrowdBg;        // 0xFF351318
  final Color liveCrowdFg;        // 0xFFF87171

  const PandalOfflineThemeTokens({
    this.crimsonVelvet = const Color(0xFF800020),
    this.festivalGold = const Color(0xFFFFD700),
    this.nightSurface = const Color(0xFF0E0E10),
    this.surfaceCard = const Color(0xFF16171D),
    this.surfaceElevated = const Color(0xFF22232C),
    this.borderSubtle = const Color(0xFF2E303D),
    this.borderFocused = const Color(0xFF4F5269),
    this.offlineBg = const Color(0xFF10281C),
    this.offlineFg = const Color(0xFF4ADE80),
    this.staleBg = const Color(0xFF2C1F0E),
    this.staleFg = const Color(0xFFFBBF24),
    this.liveCrowdBg = const Color(0xFF351318),
    this.liveCrowdFg = const Color(0xFFF87171),
  });

  @override
  PandalOfflineThemeTokens copyWith({
    Color? crimsonVelvet,
    Color? festivalGold,
    Color? nightSurface,
    Color? surfaceCard,
    Color? surfaceElevated,
    Color? borderSubtle,
    Color? borderFocused,
    Color? offlineBg,
    Color? offlineFg,
    Color? staleBg,
    Color? staleFg,
    Color? liveCrowdBg,
    Color? liveCrowdFg,
  }) {
    return PandalOfflineThemeTokens(
      crimsonVelvet: crimsonVelvet ?? this.crimsonVelvet,
      festivalGold: festivalGold ?? this.festivalGold,
      nightSurface: nightSurface ?? this.nightSurface,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderFocused: borderFocused ?? this.borderFocused,
      offlineBg: offlineBg ?? this.offlineBg,
      offlineFg: offlineFg ?? this.offlineFg,
      staleBg: staleBg ?? this.staleBg,
      staleFg: staleFg ?? this.staleFg,
      liveCrowdBg: liveCrowdBg ?? this.liveCrowdBg,
      liveCrowdFg: liveCrowdFg ?? this.liveCrowdFg,
    );
  }

  @override
  PandalOfflineThemeTokens lerp(ThemeExtension<PandalOfflineThemeTokens>? other, double t) {
    if (other is! PandalOfflineThemeTokens) return this;
    return PandalOfflineThemeTokens(
      crimsonVelvet: Color.lerp(crimsonVelvet, other.crimsonVelvet, t)!,
      festivalGold: Color.lerp(festivalGold, other.festivalGold, t)!,
      nightSurface: Color.lerp(nightSurface, other.nightSurface, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderFocused: Color.lerp(borderFocused, other.borderFocused, t)!,
      offlineBg: Color.lerp(offlineBg, other.offlineBg, t)!,
      offlineFg: Color.lerp(offlineFg, other.offlineFg, t)!,
      staleBg: Color.lerp(staleBg, other.staleBg, t)!,
      staleFg: Color.lerp(staleFg, other.staleFg, t)!,
      liveCrowdBg: Color.lerp(liveCrowdBg, other.liveCrowdBg, t)!,
      liveCrowdFg: Color.lerp(liveCrowdFg, other.liveCrowdFg, t)!,
    );
  }
}

/// Convenience extension on [BuildContext] to access [PandalOfflineThemeTokens].
extension PandalOfflineThemeContext on BuildContext {
  PandalOfflineThemeTokens get pandalTokens =>
      Theme.of(this).extension<PandalOfflineThemeTokens>() ??
      const PandalOfflineThemeTokens();
}
