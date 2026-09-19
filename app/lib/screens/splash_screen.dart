import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import 'main_navigation_screen.dart';
import 'welcome_screen.dart';

/// Full-bleed in-app splash screen displaying the three-dancer Dhunuchi illustration.
///
/// Runs actual startup work (auth state check, session warm-up) in parallel
/// with a minimum 2200ms display duration, ensuring returning users skip
/// login directly to [MainNavigationScreen] without visual flashing.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.minDuration = const Duration(milliseconds: 2200),
  });

  /// Minimum duration the splash illustration stays visible before navigating.
  final Duration minDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _prepareAndNavigate();
  }

  Future<void> _prepareAndNavigate() async {
    // Run actual startup work in parallel with a minimum display duration,
    // so the splash never flashes too briefly on a fast device, and never
    // blocks longer than necessary on a slow one.
    final results = await Future.wait<dynamic>([
      Future<void>.delayed(widget.minDuration),
      _checkAuthState(),
    ]);

    final isLoggedIn = results[1] as bool;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn
            ? const MainNavigationScreen()
            : const WelcomeScreen(),
      ),
    );
  }

  Future<bool> _checkAuthState() async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        return true;
      }
    } catch (_) {
      // Offline / demo / test fallback
    }
    return AuthService.instance.isAuthenticated;
  }

  @override
  Widget build(BuildContext context) {
    // Fixed dark brand theme regardless of system light/dark mode setting
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
        body: SizedBox.expand(
          child: Image.asset(
            'assets/images/splash_illustration.webp',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              // Graceful fallback if asset decode takes a frame
              return Container(
                color: const Color(0xFF0E0B0C),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFFD54F),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
