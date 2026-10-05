/// Reusable animation configurations and utilities for consistent motion design.
/// Follows Material Motion guidelines: easing, duration, and choreography.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Standard animation durations matching Material Motion spec.
class AppDurations {
  AppDurations._();

  // Micro-interactions (< 100ms)
  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration quick = Duration(milliseconds: 150);

  // Standard transitions (100-300ms)
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration comfortable = Duration(milliseconds: 300);

  // Complex transitions (300-500ms)
  static const Duration emphasis = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration pageTransition = Duration(milliseconds: 320);

  // Delightful moments (500ms+)
  static const Duration celebration = Duration(milliseconds: 600);
  static const Duration entrance = Duration(milliseconds: 700);
}

/// Standard easing curves matching Material Motion.
class AppCurves {
  AppCurves._();

  // Standard productive easing
  static const Curve standardEaseOut = Curves.easeOutCubic;
  static const Curve standardEaseInOut = Curves.easeInOutCubic;
  static const Curve standardEaseIn = Curves.easeInCubic;

  // Emphasized motion for important transitions
  static const Curve emphasizedAccelerate = Curves.easeInOutQuart;
  static const Curve emphasizedDecelerate = Curves.easeOutQuart;

  // Playful/spring-like for delightful moments
  static const Curve springOut = Curves.elasticOut;
  static const Curve springInOut = Curves.bounceOut;
  static const Curve gentleSpring = Curves.decelerate;

  // Custom cubic-bezier for brand feel
  static const Curve brandEaseOut = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve brandEaseInOut = Cubic(0.33, 0.0, 0.67, 1.0);
  static const Curve brandSharp = Cubic(0.4, 0.0, 0.6, 1.0);
}

/// Stagger configuration for list/grid entrance animations.
class AppStagger {
  AppStagger._();

  static const Duration itemDelay = Duration(milliseconds: 60);
  static const Duration itemDuration = Duration(milliseconds: 350);
  static const Curve itemCurve = Curves.easeOutCubic;

  /// Creates a staggered animation for a list of widgets.
  static List<Widget> staggerList(
    List<Widget> children, {
    Duration? delay,
    Duration? duration,
    Curve? curve,
    int? startIndex,
  }) {
    final d = delay ?? itemDelay;
    final dur = duration ?? itemDuration;
    final c = curve ?? itemCurve;
    final start = startIndex ?? 0;

    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      return child
          .animate(delay: d * (index + start))
          .fadeIn(duration: dur, curve: c)
          .slideY(begin: 0.3, end: 0, duration: dur, curve: c);
    }).toList();
  }

  /// Creates a staggered animation for grid items with scale.
  static List<Widget> staggerGrid(
    List<Widget> children, {
    Duration? delay,
    Duration? duration,
    Curve? curve,
  }) {
    final d = delay ?? const Duration(milliseconds: 40);
    final dur = duration ?? const Duration(milliseconds: 300);
    final c = curve ?? Curves.easeOutBack;

    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      return child
          .animate(delay: d * index)
          .fadeIn(duration: dur, curve: c)
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0),
            duration: dur,
            curve: c,
          );
    }).toList();
  }
}

/// Pre-built Animate configurations for common patterns.
class AppAnimations {
  AppAnimations._();

  /// Standard fade-in for content appearance.
  static AnimateConfig<Widget> fadeIn({
    Duration duration = AppDurations.standard,
    Curve curve = AppCurves.standardEaseOut,
    Duration delay = Duration.zero,
  }) => AnimateConfig(
    effects: [FadeEffect(duration: duration, curve: curve, delay: delay)],
  );

  /// Fade in with subtle slide up.
  static AnimateConfig<Widget> fadeSlideUp({
    Duration duration = AppDurations.standard,
    Curve curve = AppCurves.standardEaseOut,
    Duration delay = Duration.zero,
    double beginOffset = 0.2,
  }) => AnimateConfig(
    effects: [
      FadeEffect(duration: duration, curve: curve, delay: delay),
      SlideEffect(
        begin: Offset(0, beginOffset),
        end: Offset.zero,
        duration: duration,
        curve: curve,
        delay: delay,
      ),
    ],
  );

  /// Scale up from center (for modals, dialogs, FABs).
  static AnimateConfig<Widget> scaleUp({
    Duration duration = AppDurations.medium,
    Curve curve = AppCurves.emphasizedDecelerate,
    Duration delay = Duration.zero,
    double beginScale = 0.9,
  }) => AnimateConfig(
    effects: [
      ScaleEffect(
        begin: Offset(beginScale, beginScale),
        end: const Offset(1.0, 1.0),
        duration: duration,
        curve: curve,
        delay: delay,
      ),
      FadeEffect(duration: duration, curve: curve, delay: delay),
    ],
  );

  /// Spring-scale for delightful micro-interactions (tap feedback).
  static AnimateConfig<Widget> springTap({
    Duration duration = AppDurations.quick,
    Curve curve = Curves.easeOutBack,
  }) => AnimateConfig(
    effects: [
      ScaleEffect(
        begin: const Offset(0.95, 0.95),
        end: const Offset(1.0, 1.0),
        duration: duration,
        curve: curve,
      ),
    ],
  );

  /// Shimmer sweep for loading states.
  static AnimateConfig<Widget> shimmerSweep({
    Duration duration = const Duration(milliseconds: 1500),
    Curve curve = Curves.linear,
  }) => AnimateConfig(
    effects: [
      ShimmerEffect(
        duration: duration,
        curve: curve,
        colors: const [Color(0xFFE0E0E0), Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
      ),
    ],
  );

  /// Pulse for attention-grabbing elements (notifications, badges).
  static AnimateConfig<Widget> pulse({
    Duration duration = const Duration(milliseconds: 1000),
    int count = 3,
  }) => AnimateConfig(
    effects: [
      ScaleEffect(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.05, 1.05),
        duration: duration ~/ 2,
        curve: Curves.easeInOut,
      ),
      ScaleEffect(
        begin: const Offset(1.05, 1.05),
        end: const Offset(1.0, 1.0),
        duration: duration ~/ 2,
        curve: Curves.easeInOut,
      ),
    ],
  ).repeat(count: count);

  /// Slide in from bottom (for bottom sheets, snackbars).
  static AnimateConfig<Widget> slideUpBottom({
    Duration duration = AppDurations.pageTransition,
    Curve curve = AppCurves.brandEaseOut,
    Duration delay = Duration.zero,
  }) => AnimateConfig(
    effects: [
      SlideEffect(
        begin: const Offset(0, 1),
        end: Offset.zero,
        duration: duration,
        curve: curve,
        delay: delay,
      ),
      FadeEffect(duration: duration, curve: curve, delay: delay),
    ],
  );

  /// Slide in from right (for navigation push).
  static AnimateConfig<Widget> slideFromRight({
    Duration duration = AppDurations.pageTransition,
    Curve curve = AppCurves.brandEaseOut,
  }) => AnimateConfig(
    effects: [
      SlideEffect(
        begin: const Offset(1, 0),
        end: Offset.zero,
        duration: duration,
        curve: curve,
      ),
      FadeEffect(duration: duration, curve: curve),
    ],
  );

  /// Slide out to left (for navigation pop).
  static AnimateConfig<Widget> slideToLeft({
    Duration duration = AppDurations.pageTransition,
    Curve curve = AppCurves.brandEaseInOut,
  }) => AnimateConfig(
    effects: [
      SlideEffect(
        begin: Offset.zero,
        end: const Offset(-1, 0),
        duration: duration,
        curve: curve,
      ),
      FadeEffect(duration: duration, curve: curve),
    ],
  );

  /// Shared axis transition (for list-detail, master-detail).
  static AnimateConfig<Widget> sharedAxisHorizontal({
    Duration duration = AppDurations.pageTransition,
    Curve curve = AppCurves.brandEaseInOut,
    bool forward = true,
  }) => AnimateConfig(
    effects: [
      SlideEffect(
        begin: Offset(forward ? 0.3 : -0.3, 0),
        end: Offset.zero,
        duration: duration,
        curve: curve,
      ),
      FadeEffect(duration: duration, curve: curve),
      ScaleEffect(
        begin: const Offset(0.98, 0.98),
        end: const Offset(1.0, 1.0),
        duration: duration,
        curve: curve,
      ),
    ],
  );

  /// Celebration burst (confetti, favorite added, achievement).
  static AnimateConfig<Widget> celebrationBurst({
    Duration duration = AppDurations.celebration,
  }) => AnimateConfig(
    effects: [
      ScaleEffect(
        begin: const Offset(0.5, 0.5),
        end: const Offset(1.1, 1.1),
        duration: duration * 2 ~/ 3,
        curve: Curves.elasticOut,
      ),
      ScaleEffect(
        begin: const Offset(1.1, 1.1),
        end: const Offset(1.0, 1.0),
        duration: duration ~/ 3,
        curve: Curves.easeOutCubic,
      ),
      RotateEffect(
        begin: -0.1,
        end: 0,
        duration: duration,
        curve: Curves.elasticOut,
      ),
    ],
  );

  /// Subtle shake for errors/validation.
  static AnimateConfig<Widget> shake({
    Duration duration = AppDurations.standard,
  }) => AnimateConfig(
    effects: [
      ShakeEffect(
        duration: duration,
        curve: Curves.easeInOut,
        offset: 10,
        rotations: 3,
      ),
    ],
  );
}

/// Extension for cleaner animate() calls with pre-built configs.
extension AppAnimateExtension on Widget {
  /// Apply a pre-built animation config.
  Widget animateWith(AppAnimations config) => animate().then(config);

  /// Quick fade in.
  Widget fadeIn({Duration? delay}) => animate(
    effects: [
      FadeEffect(
        duration: AppDurations.standard,
        curve: AppCurves.standardEaseOut,
        delay: delay ?? Duration.zero,
      ),
    ],
  );

  /// Quick fade + slide up.
  Widget fadeSlideUp({Duration? delay}) => animate(
    effects: [
      FadeEffect(
        duration: AppDurations.standard,
        curve: AppCurves.standardEaseOut,
        delay: delay ?? Duration.zero,
      ),
      SlideEffect(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
        duration: AppDurations.standard,
        curve: AppCurves.standardEaseOut,
        delay: delay ?? Duration.zero,
      ),
    ],
  );

  /// Quick scale up.
  Widget scaleUp({Duration? delay}) => animate(
    effects: [
      ScaleEffect(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1.0, 1.0),
        duration: AppDurations.medium,
        curve: AppCurves.emphasizedDecelerate,
        delay: delay ?? Duration.zero,
      ),
      FadeEffect(
        duration: AppDurations.medium,
        curve: AppCurves.emphasizedDecelerate,
        delay: delay ?? Duration.zero,
      ),
    ],
  );

  /// Staggered entrance for lists.
  Widget staggerEntrance(int index, {Duration? delay}) => animate(
    effects: [
      FadeEffect(
        duration: AppDurations.emphasis,
        curve: AppCurves.standardEaseOut,
        delay: (delay ?? AppStagger.itemDelay) * index,
      ),
      SlideEffect(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
        duration: AppDurations.emphasis,
        curve: AppCurves.standardEaseOut,
        delay: (delay ?? AppStagger.itemDelay) * index,
      ),
    ],
  );

  /// Tap feedback scale.
  Widget tapScale() => animate(
    effects: [
      ScaleEffect(
        begin: const Offset(1.0, 1.0),
        end: const Offset(0.96, 0.96),
        duration: AppDurations.instant,
        curve: Curves.easeOut,
      ),
      ScaleEffect(
        begin: const Offset(0.96, 0.96),
        end: const Offset(1.0, 1.0),
        duration: AppDurations.quick,
        curve: Curves.easeOutBack,
      ),
    ],
  );
}

/// Page route transitions for consistent navigation feel.
class AppPageTransitions {
  AppPageTransitions._();

  /// Standard Material 3 shared axis transition (horizontal).
  static PageRouteBuilder<T> sharedAxisHorizontal<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppDurations.pageTransition,
    bool forward = true,
  }) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (_, _, _) => page,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (_, animation, _, child) {
      final offsetAnimation =
          Tween<Offset>(
            begin: Offset(forward ? 0.3 : -0.3, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: AppCurves.brandEaseInOut),
          );

      final scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: AppCurves.brandEaseInOut),
      );

      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: AppCurves.standardEaseOut),
      );

      return SlideTransition(
        position: offsetAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        ),
      );
    },
  );

  /// Vertical shared axis (for bottom sheet like transitions).
  static PageRouteBuilder<T> sharedAxisVertical<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppDurations.pageTransition,
  }) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (_, _, _) => page,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (_, animation, _, child) {
      final offsetAnimation =
          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: AppCurves.brandEaseInOut),
          );

      final scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: AppCurves.brandEaseInOut),
      );

      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: AppCurves.standardEaseOut),
      );

      return SlideTransition(
        position: offsetAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        ),
      );
    },
  );

  /// Fade through (for tab switching, modal replacements).
  static PageRouteBuilder<T> fadeThrough<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppDurations.standard,
  }) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (_, _, _) => page,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: AppCurves.standardEaseOut),
        ),
        child: child,
      );
    },
  );
}
