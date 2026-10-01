/// Animation duration and curve constants for consistent motion design.
/// Extracted from animations.dart for reuse without flutter_animate dependency.

import 'package:flutter/material.dart';

class AppDurations {
  AppDurations._();

  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration comfortable = Duration(milliseconds: 300);
  static const Duration emphasis = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration pageTransition = Duration(milliseconds: 320);
  static const Duration celebration = Duration(milliseconds: 600);
  static const Duration entrance = Duration(milliseconds: 700);
}

class AppCurves {
  AppCurves._();

  static const Curve standardEaseOut = Curves.easeOutCubic;
  static const Curve emphasizedDecelerate = Curves.easeOutQuart;
  static const Curve brandEaseOut = Curves.easeOutExpo;
}