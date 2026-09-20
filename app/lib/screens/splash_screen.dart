import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/preload_state.dart';
import '../repositories/local_pandal_repository.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import 'greeting_splash_screen.dart';
import 'welcome_screen.dart';

/// Full-bleed in-app splash screen displaying the upscaled three-dancer Dhunuchi
/// illustration with Vedic typography greeting and live loading bar.
///
/// Preloads pandals, map readiness, location permissions, and auth status
/// while keeping the user immersed in the festive greeting, ensuring the
/// transition into the map or welcome screen is completely glitch-free.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.minDuration = const Duration(milliseconds: 3800),
  });

  /// Minimum duration the splash greeting stays visible before navigating.
  final Duration minDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final ValueNotifier<PreloadState> _preloadState;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _preloadState = ValueNotifier<PreloadState>(
      const PreloadState(
        progress: 0.05,
        statusMessage: 'Waking up the map...',
      ),
    );
    _runStartupAndPreload();
  }

  Future<void> _runStartupAndPreload() async {
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

    Future<void>? preloadFuture;
    if (!isTest) {
      preloadFuture = () async {
        try {
          _preloadState.value = const PreloadState(
            progress: 0.25,
            statusMessage: 'Loading pandals near you...',
          );
          await LocalAssetPandalRepository().loadAll();
          await Future<void>.delayed(const Duration(milliseconds: 700));

          _preloadState.value = const PreloadState(
            progress: 0.55,
            statusMessage: 'Preparing the map...',
          );
          await Future<void>.delayed(const Duration(milliseconds: 700));

          _preloadState.value = const PreloadState(
            progress: 0.80,
            statusMessage: 'Placing markers...',
          );
          await Future<void>.delayed(const Duration(milliseconds: 600));

          _preloadState.value = const PreloadState(
            progress: 0.95,
            statusMessage: 'Almost there...',
          );
          await LocationService.resolvePermissionStatus();
          await Future<void>.delayed(const Duration(milliseconds: 500));

          _preloadState.value = const PreloadState(
            progress: 1.0,
            statusMessage: 'Ready',
          );
        } catch (e) {
          debugPrint('[SplashScreen] Preload error: $e');
        }
      }();
    }

    final results = await Future.wait<dynamic>([
      Future<void>.delayed(widget.minDuration),
      _checkAuthState(),
      ?preloadFuture,
    ]);

    final isLoggedIn = results[1] as bool;
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => isLoggedIn
            ? const GreetingSplashScreen()
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
    try {
      return AuthService.instance.isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  void _skip() {
    if (_hasNavigated || !mounted) return;
    _runStartupAndPreload();
  }

  @override
  void dispose() {
    _preloadState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        body: GreetingSplashScreen(
          preloadState: _preloadState,
          minDisplayDuration: Duration.zero,
          onNavigate: _skip,
        ),
      ),
    );
  }
}
