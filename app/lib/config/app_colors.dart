import 'package:flutter/material.dart';

/// Centralized design tokens matching the muted, low-saturation rose/mauve
/// palette used across Routes and Pandals.
class AppColors {
  AppColors._();

  /// Rose/salmon — the ONE interactive accent: buttons, CTAs, selected states, tags, badges.
  static const Color accentPrimary = Color(0xFFB5696B);

  /// Muted rose used for selected chips, primary action buttons, and outgoing message bubbles.
  static const Color chipMuted = Color(0xFF8B5A5A);

  /// Dark maroon card surface (OLED-friendly dark surface).
  static const Color cardSurface = Color(0xFF2A1D1D);

  /// Elevated card surface for subtle layering in dark mode.
  static const Color cardSurfaceElevated = Color(0xFF352424);

  /// Light mode card surface.
  static const Color cardSurfaceLight = Color(0xFFFAF2F2);

  /// Restrained sacred gold, strictly reserved for rating stars across all screens.
  static const Color accentGold = Color(0xFFC9A961);

  /// Muted red reserved strictly for genuine alerts, warnings, and destructive actions (e.g. Leave Squad).
  static const Color semanticAlert = Color(0xFFB55757);

  /// Muted green reserved strictly for live/active status, online indicators, and GPS sharing.
  static const Color semanticLive = Color(0xFF6B9B7A);
}
