import 'package:flutter/material.dart';

/// Comprehensive responsive sizing and dynamic scaling utility for the Puja app.
/// Prevents text truncation, icon overflow, and clipping across all screen sizes.
class AppResponsive {
  AppResponsive._();

  /// Standard reference mobile width (modern standard iPhone / Android: 390px)
  static const double referenceWidth = 390.0;

  /// Standard reference mobile height (844px)
  static const double referenceHeight = 844.0;

  /// Calculate scale factor based on screen width
  static double getScaleFactor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 0) return 1.0;
    // Clamped between 0.82 (e.g. small 320-360px phones) and 1.30 (large phablets/tablets)
    return (width / referenceWidth).clamp(0.82, 1.30);
  }

  /// Dynamic icon size that scales gracefully and prevents oversized/undersized icons
  static double dynamicIcon(BuildContext context, double baseSize) {
    final scale = getScaleFactor(context);
    return (baseSize * scale).clamp(baseSize * 0.85, baseSize * 1.35);
  }

  /// Dynamic font size that scales smoothly while respecting readability bounds
  static double dynamicFont(BuildContext context, double baseSize) {
    final scale = getScaleFactor(context);
    return (baseSize * scale).clamp(baseSize * 0.85, baseSize * 1.25);
  }

  /// Scale arbitrary dimensions (e.g. padding, container heights, margins)
  static double scale(BuildContext context, double value) {
    final scale = getScaleFactor(context);
    return (value * scale).clamp(value * 0.85, value * 1.30);
  }

  /// Breakpoint checks
  static bool isSmallScreen(BuildContext context) => MediaQuery.sizeOf(context).width < 360;
  static bool isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= 600;
  static bool isLandscape(BuildContext context) =>
      MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
}

/// Extension on BuildContext for effortless, clean access in widget build methods
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  double get scaleFactor => AppResponsive.getScaleFactor(this);

  /// Dynamically sized icon
  double dynamicIcon(double baseSize) => AppResponsive.dynamicIcon(this, baseSize);

  /// Dynamically sized font
  double dynamicFont(double baseSize) => AppResponsive.dynamicFont(this, baseSize);

  /// Dynamically scaled dimension
  double scale(double value) => AppResponsive.scale(this, value);

  /// Screen size queries
  bool get isSmallScreen => AppResponsive.isSmallScreen(this);
  bool get isTablet => AppResponsive.isTablet(this);
  bool get isLandscape => AppResponsive.isLandscape(this);
}
