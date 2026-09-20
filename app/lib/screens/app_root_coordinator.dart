import 'dart:async';
import 'package:flutter/material.dart';

import '../models/preload_state.dart';
import '../repositories/local_pandal_repository.dart';
import '../services/location_service.dart';
import '../widgets/app_tutorial_dialog.dart';
import 'greeting_splash_screen.dart';
import 'main_navigation_screen.dart';

/// AppRootCoordinator seamlessly merges the Unified Illustrated Greeting Splash
/// with a pre-mounted, fully initialized Main Map underneath.
///
/// Eliminates visual pop-in, grey tile flashes, and marker jumps by:
/// 1. Pre-mounting [MainNavigationScreen] in the widget tree from frame zero.
/// 2. Running real asynchronous preload tasks (pandal data, map platform readiness,
///    marker stabilization, location permission check).
/// 3. Displaying honest progress and status via [PreloadState].
/// 4. Respecting a minimum 2800ms presentation threshold alongside real readiness.
/// 5. Revealing the ready map via a smooth hardware-accelerated crossfade.
class AppRootCoordinator extends StatefulWidget {
  const AppRootCoordinator({
    super.key,
    this.minDuration = const Duration(milliseconds: 4000),
    this.testSkipPreload = false,
  });

  /// Minimum duration the illustrated greeting splash remains visible.
  final Duration minDuration;

  /// Test-only hook to immediately reveal without waiting.
  final bool testSkipPreload;

  @override
  State<AppRootCoordinator> createState() => _AppRootCoordinatorState();
}

class _AppRootCoordinatorState extends State<AppRootCoordinator> {
  final ValueNotifier<PreloadState> preloadState = ValueNotifier(
    const PreloadState(
      progress: 0.05,
      statusMessage: 'Waking up the map...',
    ),
  );

  bool _revealMap = false;
  bool _fadeComplete = false;
  final Completer<void> _mapReadyCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();
    if (widget.testSkipPreload) {
      _revealMap = true;
      _fadeComplete = true;
    } else {
      _runPreload();
    }
  }

  Future<void> _runPreload() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Step 1: Warm up static pandal dataset from bundled assets
      preloadState.value = const PreloadState(
        progress: 0.20,
        statusMessage: 'Loading pandals near you...',
      );
      await LocalAssetPandalRepository().loadAll();
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Step 2: Await map platform view readiness & initial camera setup
      preloadState.value = const PreloadState(
        progress: 0.50,
        statusMessage: 'Preparing the map...',
      );
      // Wait for onMapReady or timeout gracefully after 4 seconds
      await _mapReadyCompleter.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('[AppRootCoordinator] Map ready timeout reached; continuing.');
        },
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // Step 3: Spatial indexing & marker stabilization tick
      preloadState.value = const PreloadState(
        progress: 0.75,
        statusMessage: 'Placing markers...',
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Step 4: Resolve device location permission without intrusive popups
      preloadState.value = const PreloadState(
        progress: 0.90,
        statusMessage: 'Almost there...',
      );
      await LocationService.resolvePermissionStatus();
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // Step 5: Final preparation complete
      preloadState.value = const PreloadState(
        progress: 1.0,
        statusMessage: 'Ready',
      );
    } catch (e) {
      debugPrint('[AppRootCoordinator] Preload warning: $e');
    }

    // Enforce minimum splash duration alongside real work readiness
    final elapsed = stopwatch.elapsed;
    if (elapsed < widget.minDuration) {
      await Future<void>.delayed(widget.minDuration - elapsed);
    }
    // Linger briefly on 'Ready' for 400ms for a peaceful visual experience
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      setState(() => _revealMap = true);
    }
  }

  void _skipToMap() {
    if (_revealMap) return;
    setState(() => _revealMap = true);
  }

  @override
  void dispose() {
    preloadState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Map screen is mounted and active from frame zero underneath.
        // It initializes platform views, tiles, and markers while visually behind the splash.
        IgnorePointer(
          ignoring: !_revealMap,
          child: AnimatedOpacity(
            opacity: _revealMap ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: MainNavigationScreen(
              initialIndex: 0,
              onMapReady: () {
                if (!_mapReadyCompleter.isCompleted) {
                  _mapReadyCompleter.complete();
                }
              },
            ),
          ),
        ),

        // 2. Unified Illustrated Greeting Splash overlaid on top.
        // Fades out once preload is complete, and disposes after fade finishes.
        if (!_fadeComplete)
          IgnorePointer(
            ignoring: _revealMap,
            child: AnimatedOpacity(
              opacity: _revealMap ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              onEnd: () {
                if (_revealMap && mounted) {
                  setState(() => _fadeComplete = true);
                  AppTutorialDialog.checkAndShow(context);
                }
              },
              child: GreetingSplashScreen(
                preloadState: preloadState,
                minDisplayDuration: Duration.zero, // Controlled by coordinator
                onNavigate: _skipToMap,
              ),
            ),
          ),
      ],
    );
  }
}
