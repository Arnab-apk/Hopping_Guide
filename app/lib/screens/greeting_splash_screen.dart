import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/preload_state.dart';
import '../services/auth_service.dart';
import '../utils/puja_schedule.dart';
import 'main_navigation_screen.dart';

/// Four day-aware Puja greeting phases tuned to the calendar.
enum GreetingPhase { countdown, prep, mainPuja, dashami }

/// Resolves the current festival phase based on the Puja day schedule.
GreetingPhase resolvePhase(PujaDay? day) {
  if (day == null) return GreetingPhase.countdown; // before Mahalaya or after Puja
  if (day.name == 'Vijaya Dashami') return GreetingPhase.dashami;
  final mainPujaNames = {'Maha Shashthi', 'Maha Saptami', 'Maha Ashtami', 'Maha Navami'};
  if (mainPujaNames.contains(day.name)) return GreetingPhase.mainPuja;
  return GreetingPhase.prep; // Mahalaya through Panchami
}

/// Unified Illustrated Greeting Splash Screen celebrating Durga Puja 2026.
///
/// Features:
/// - Full-bleed Dhunuchi dancers illustration (`splash_illustration.webp`)
/// - Uniform honest 50% dark scrim for rock-solid typography contrast
/// - 4-phase day-aware glowing ember particle layer (`EmberField`)
/// - Sacred Diya emblem with phase pulse and QA date debug selector
/// - Live progress status and real `LinearProgressIndicator`
/// - Glitch-free map handoff coordination
class GreetingSplashScreen extends StatefulWidget {
  const GreetingSplashScreen({
    super.key,
    this.minDisplayDuration = const Duration(milliseconds: 1800),
    this.onNavigate,
    this.preloadState,
  });

  /// Duration to hold the greeting before auto-navigating to the main map.
  final Duration minDisplayDuration;

  /// Optional navigation callback for unit/widget testing and coordinator handoff.
  final VoidCallback? onNavigate;

  /// Optional observable preload state driving the real progress bar.
  final ValueListenable<PreloadState>? preloadState;

  @override
  State<GreetingSplashScreen> createState() => _GreetingSplashScreenState();
}

class _GreetingSplashScreenState extends State<GreetingSplashScreen> {
  Timer? _navTimer;
  bool _hasNavigated = false;
  int _emblemTapCount = 0;

  @override
  void initState() {
    super.initState();

    if (widget.minDisplayDuration > Duration.zero) {
      _navTimer = Timer(widget.minDisplayDuration, () {
        if (mounted) _navigateToMap();
      });
    }
  }

  void _navigateToMap() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _navTimer?.cancel();

    if (widget.onNavigate != null) {
      widget.onNavigate!();
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _onGreetingTap() {
    if (kReleaseMode) return;
    _emblemTapCount++;
    if (_emblemTapCount >= 5) {
      _emblemTapCount = 0;
      _showDebugDateSelector();
    }
  }

  void _showDebugDateSelector() {
    _navTimer?.cancel();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161418),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Preview Puja Day (QA Debug)',
                      style: TextStyle(
                        color: NeoTokens.accentGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: const Text('Real Device Time (Default)', style: TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.restore, color: Colors.white70),
                        onTap: () {
                          AppClock.debugSetOverride(null);
                          Navigator.of(sheetContext).pop();
                          setState(() {});
                        },
                      ),
                      ListTile(
                        title: const Text('Oct 9 — 1 day before Mahalaya', style: TextStyle(color: Colors.white70)),
                        onTap: () {
                          AppClock.debugSetOverride(DateTime(2026, 10, 9));
                          Navigator.of(sheetContext).pop();
                          setState(() {});
                        },
                      ),
                      ...pujaSchedule2026.map((day) {
                        final dateStr = 'Oct ${day.date.day}';
                        return ListTile(
                          title: Text('$dateStr — ${day.name}', style: const TextStyle(color: Colors.white)),
                          subtitle: day.subtitle != null
                              ? Text(day.subtitle!, style: const TextStyle(color: Colors.white54, fontSize: 12))
                              : null,
                          onTap: () {
                            AppClock.debugSetOverride(day.date);
                            Navigator.of(sheetContext).pop();
                            setState(() {});
                          },
                        );
                      }),
                      ListTile(
                        title: const Text('Oct 22 — After Dashami', style: TextStyle(color: Colors.white70)),
                        onTap: () {
                          AppClock.debugSetOverride(DateTime(2026, 10, 22));
                          Navigator.of(sheetContext).pop();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  String _getUserName() {
    try {
      final user = AuthService.instance.currentUserModel;
      if (user != null && user.displayName != null && user.displayName!.trim().isNotEmpty) {
        final parts = user.displayName!.trim().split(' ');
        return parts.first;
      }
    } catch (_) {}
    return 'Pujo Hopper';
  }

  TextStyle _getSamarkanStyle({
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 0.4,
  }) {
    return TextStyle(
      fontFamily: 'Samarkan',
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = getTodaysPujaDay();
    final phase = resolvePhase(day);
    final userName = _getUserName();
    final greeting = buildGreeting(day, userName);
    final subtitle = day != null
        ? day.description
        : 'Explore verified pandals, live crowd telemetry, and curated hopping routes.';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0E0B0C),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0B0C),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigateToMap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Full-bleed background illustration (three dhunuchi dancers)
              Image.asset(
                'assets/images/splash_illustration.webp',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF0E0B0C),
                ),
              ),

              // 2. Uniform 50% dark scrim across the whole image for honest, reliable legibility
              Container(color: Colors.black.withValues(alpha: 0.50)),

              // 3. Day-phase tuned glowing ember particle layer
              EmberField(phase: phase),

              // 4. Foreground typography & interactive content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 52),

                      // Greeting Title (Tap 5x in debug mode for QA Debug Selector)
                      GestureDetector(
                        onTap: _onGreetingTap,
                        child: Text(
                          greeting,
                          style: _getSamarkanStyle(
                            fontSize: 25,
                            color: NeoTokens.accentGold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle / Cultural Subtext
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Spacer allowing the illustration's hero moment to shine through unobstructed
                      const Spacer(),
                      const Spacer(),

                      // Bottom: Status Message + Real Loading Bar or Hint
                      if (widget.preloadState != null)
                        ValueListenableBuilder<PreloadState>(
                          valueListenable: widget.preloadState!,
                          builder: (context, state, _) {
                            return _buildLoadingBar(context, state.statusMessage, state.progress);
                          },
                        )
                      else
                        _buildFallbackBottomHint(),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBar(BuildContext context, String statusMessage, double progress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          statusMessage,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 220,
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white24,
              color: NeoTokens.accentGold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackBottomHint() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Entering Kolkata Map',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white.withValues(alpha: 0.45),
          size: 14,
        ),
      ],
    );
  }
}

/// Day-phase tuned ember particle layer.
class EmberField extends StatefulWidget {
  const EmberField({super.key, required this.phase});

  final GreetingPhase phase;

  @override
  State<EmberField> createState() => _EmberFieldState();
}

class _EmberFieldState extends State<EmberField> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      _controller.repeat();
    }
  }

  int get _emberCount => switch (widget.phase) {
        GreetingPhase.countdown => 6,
        GreetingPhase.prep => 10,
        GreetingPhase.mainPuja => 18,
        GreetingPhase.dashami => 12,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: EmberPainter(
          progress: _controller.value,
          count: _emberCount,
          phase: widget.phase,
        ),
        size: Size.infinite,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Custom painter for glowing embers drifting upward.
class EmberPainter extends CustomPainter {
  EmberPainter({
    required this.progress,
    required this.count,
    required this.phase,
  });

  final double progress;
  final int count;
  final GreetingPhase phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final seed = i * 1337 + 73;
      final rng1 = math.sin(seed).abs();
      final rng2 = math.cos(seed * 2).abs();
      final rng3 = math.sin(seed * 3).abs();

      final double x = (0.08 + 0.84 * rng1) * size.width +
          math.sin((progress * 2 * math.pi) + i) * (size.width * 0.03);

      final double speed = switch (phase) {
        GreetingPhase.countdown => 0.6 + 0.3 * rng2,
        GreetingPhase.prep => 0.8 + 0.4 * rng2,
        GreetingPhase.mainPuja => 1.0 + 0.6 * rng2,
        GreetingPhase.dashami => 0.7 + 0.5 * rng2,
      };

      final double rawY = (rng2 - progress * speed) % 1.0;
      final double normalizedY = rawY < 0 ? rawY + 1.0 : rawY;
      final double y = normalizedY * size.height;

      final double verticalFade = math.sin(normalizedY * math.pi).clamp(0.0, 1.0);

      final double baseAlpha = switch (phase) {
        GreetingPhase.countdown => 0.28,
        GreetingPhase.prep => 0.45,
        GreetingPhase.mainPuja => 0.75,
        GreetingPhase.dashami => 0.40,
      };

      final double alpha = (baseAlpha * verticalFade).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;

      final double radius = switch (phase) {
        GreetingPhase.countdown => 1.5 + rng3 * 1.5,
        GreetingPhase.prep => 1.8 + rng3 * 1.8,
        GreetingPhase.mainPuja => 2.2 + rng3 * 2.4,
        GreetingPhase.dashami => 1.8 + rng3 * 2.0,
      };

      final Color emberColor = switch (phase) {
        GreetingPhase.dashami => const Color(0xFFFFCC80),
        GreetingPhase.mainPuja =>
          rng3 > 0.5 ? const Color(0xFFFFD54F) : const Color(0xFFFF9800),
        _ => const Color(0xFFFFD54F),
      };

      if (radius > 2.5 && phase == GreetingPhase.mainPuja) {
        paint
          ..color = emberColor.withValues(alpha: alpha * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
        canvas.drawCircle(Offset(x, y), radius * 1.8, paint);
      }

      paint
        ..color = emberColor.withValues(alpha: alpha)
        ..maskFilter = null;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant EmberPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.count != count ||
        oldDelegate.phase != phase;
  }
}
