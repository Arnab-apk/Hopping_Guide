import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../utils/puja_schedule.dart';
import 'main_navigation_screen.dart';

/// Rich post-login & cold-start greeting splash screen celebrating Durga Puja 2026.
///
/// Welcomes users with daily cultural greetings (e.g., "Shubho Maha Shashthi (Bodhon)"),
/// sacred devotional motifs, and seamless transition to the interactive map.
class GreetingSplashScreen extends StatefulWidget {
  const GreetingSplashScreen({
    super.key,
    this.minDisplayDuration = const Duration(milliseconds: 1800),
    this.onNavigate,
  });

  /// Duration to hold the greeting before auto-navigating to the main map.
  final Duration minDisplayDuration;

  /// Optional navigation callback for unit/widget testing.
  final VoidCallback? onNavigate;

  @override
  State<GreetingSplashScreen> createState() => _GreetingSplashScreenState();
}

class _GreetingSplashScreenState extends State<GreetingSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
  );

  Timer? _navTimer;
  bool _hasNavigated = false;
  int _emblemTapCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.forward();

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

  void _onEmblemTap() {
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
    _controller.dispose();
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

  TextStyle _getYatraOneStyle({
    required double fontSize,
    required Color color,
  }) {
    try {
      return GoogleFonts.yatraOne(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      );
    } catch (_) {
      // Offline-resilient fallback
      return TextStyle(
        fontFamily: 'Samarkan',
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w600,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = getTodaysPujaDay();
    final userName = _getUserName();
    final greeting = buildGreeting(day, userName);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: NeoTokens.bgDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: NeoTokens.bgDark,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigateToMap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Subtle radial warmth aura in center
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.08),
                      radius: 0.85,
                      colors: [
                        NeoTokens.accentGold.withValues(alpha: 0.12),
                        const Color(0xFF800020).withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              // Main animated greeting card
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Sacred Diya / Trishul Emblem (Tap 5x for debug QA menu)
                          GestureDetector(
                            onTap: _onEmblemTap,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1E181A),
                                border: Border.all(
                                  color: NeoTokens.accentGold.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: NeoTokens.accentGold.withValues(alpha: 0.25),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/icons/trishul_diya_gold.png',
                                  width: 46,
                                  height: 46,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: NeoTokens.accentGold,
                                    size: 46,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Bengali Agomoni script badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: NeoTokens.accentGold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: NeoTokens.accentGold.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Text(
                              'শারদীয়া দুর্গোৎসব ২০২৬',
                              style: TextStyle(
                                color: NeoTokens.goldBright,
                                fontSize: 13,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Main Greeting Title (Yatra One font)
                          Text(
                            greeting,
                            style: _getYatraOneStyle(
                              fontSize: 25,
                              color: NeoTokens.accentGold,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          // Day description or contextual festival subtext
                          const SizedBox(height: 12),
                          if (day != null) ...[
                            Text(
                              day.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13.5,
                                height: 1.45,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            const Text(
                              'Explore verified pandals, live crowd telemetry, and curated hopping routes.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom subtle hint / skip indicator
              Positioned(
                bottom: 36,
                left: 0,
                right: 0,
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Row(
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
