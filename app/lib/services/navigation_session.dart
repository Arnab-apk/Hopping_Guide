import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'live_tracking_enhancements.dart';
import 'location_service.dart';
import 'route_guidance.dart';
import 'routing_service.dart';

enum NavigationState { idle, previewing, navigating, rerouting, arrived }

/// Coordinates the existing routing/location engine without owning map widgets.
class NavigationSession extends ChangeNotifier {
  NavigationSession({
    LiveTrackingEngine? engine,
    DateTime Function()? now,
    Future<Position?> Function()? refreshPosition,
  }) : engine = engine ?? LiveTrackingEngine.instance,
       _now = now ?? DateTime.now,
       _refreshPosition =
           refreshPosition ??
           (() async => LocationService.enableTestMode
               ? LocationService.instance.currentPositionSync
               : LocationService.instance.updateLiveLocation()) {
    this.engine.addListener(_onEngineChanged);
  }
  static final instance = NavigationSession();
  static const _channel = MethodChannel('uma/navigation');
  final LiveTrackingEngine engine;
  final DateTime Function() _now;
  final Future<Position?> Function() _refreshPosition;
  NavigationState state = NavigationState.idle;
  WalkingRoute? route;
  String? error;
  bool following = true;
  bool starting = false;
  bool _ownsLocation = false;
  int _generation = 0;
  Timer? _freshnessTimer, _arrivalTimer;

  bool get active =>
      state == NavigationState.navigating ||
      state == NavigationState.rerouting ||
      state == NavigationState.arrived;
  bool get hasPreview => state == NavigationState.previewing;
  RouteGuidance? get guidance => active ? engine.guidance : null;
  bool get live {
    final fix = LocationService.instance.currentPositionSync;
    if (fix == null || fix.accuracy >= 30) return false;
    final age = _now().difference(fix.timestamp);
    return !age.isNegative && age < const Duration(seconds: 5);
  }

  int get etaMinutes => state == NavigationState.arrived
      ? 0
      : math.max(
          1,
          ((guidance?.remainingSeconds ?? route?.durationSeconds ?? 0) / 60)
              .ceil(),
        );
  double get remainingMeters => state == NavigationState.arrived
      ? 0
      : guidance?.remainingMeters ?? route?.distanceMeters ?? 0;
  String get title => state == NavigationState.arrived
      ? 'You have arrived'
      : state == NavigationState.rerouting
      ? 'Rerouting…'
      : guidance?.step.type == 'depart'
      ? 'Head out'
      : guidance?.step.type == 'arrive'
      ? (route != null &&
                route!.waypoints.length > 2 &&
                guidance!.step.legIndex < route!.waypoints.length - 2
            ? (guidance!.distanceToTurnMeters <= 20
                  ? 'Reached your stop'
                  : 'Continue to next stop')
            : 'Continue to ${route?.destinationTitle ?? 'destination'}')
      : guidance?.step.instruction ?? 'Head out';
  double get arrowRotation => maneuverRotation(guidance?.step.modifier);

  void preview(WalkingRoute? next) {
    end(notify: false);
    if (next == null ||
        next.isFallback ||
        !next.isWalk ||
        next.steps.isEmpty ||
        next.points.length < 2) {
      notifyListeners();
      return;
    }
    route = next;
    state = NavigationState.previewing;
    notifyListeners();
  }

  Future<bool> begin() async {
    if (!hasPreview || route == null || starting) return false;
    final generation = _generation;
    final selected = route!;
    starting = true;
    error = null;
    notifyListeners();
    try {
      if (!LocationService.enableTestMode &&
          await Geolocator.getLocationAccuracy() ==
              LocationAccuracyStatus.reduced) {
        error =
            'Enable precise location in Android app permissions to navigate.';
        return false;
      }
      final location = LocationService.instance;
      location.setNavigationMode(true);
      // One additional reference to the shared stream, never a second GPS watcher.
      _ownsLocation = true;
      final ok = await location.startLiveTracking(
        callbackKey: this,
        throttleInterval: const Duration(seconds: 1),
      );
      if (!ok) {
        _ownsLocation = false;
        error = location.error ?? 'Turn on location to navigate.';
        return false;
      }
      if (generation != _generation) return false;
      var fix = location.currentPositionSync;
      if (fix == null ||
          fix.accuracy > 50 ||
          _now().difference(fix.timestamp).abs() >
              const Duration(seconds: 10)) {
        fix = await _refreshPosition();
        if (generation != _generation) return false;
      }
      if (fix == null ||
          fix.accuracy > 50 ||
          _now().difference(fix.timestamp).abs() >
              const Duration(seconds: 10)) {
        error = 'Waiting for an accurate GPS fix. Try Start again.';
        return false;
      }
      following = true;
      state = NavigationState.navigating;
      await engine.startTracking(
        destination: selected.points.last,
        destinationName: selected.destinationTitle,
        targetPandal: selected.targetPandal,
        precomputedRoute: selected,
      );
      if (generation != _generation) return false;
      await _keepScreenOn(true);
      if (generation != _generation) {
        await _keepScreenOn(false);
        return false;
      }
      _freshnessTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (active) notifyListeners();
      });
      _onEngineChanged();
      return true;
    } catch (_) {
      if (generation != _generation) return false;
      error = 'Could not start navigation. Check location and try again.';
      state = NavigationState.previewing;
      engine.stopTracking();
      await _keepScreenOn(false);
      return false;
    } finally {
      if (generation == _generation) {
        starting = false;
        if (!active && _ownsLocation) {
          _ownsLocation = false;
          LocationService.instance.stopLiveTracking(callbackKey: this);
        }
        if (!active) LocationService.instance.setNavigationMode(false);
        notifyListeners();
      }
    }
  }

  void _onEngineChanged() {
    if (!active) return;
    route = engine.activeRoute ?? route;
    error = engine.navigationError;
    if (engine.guidance?.arrived == true) {
      state = NavigationState.arrived;
      _arrivalTimer ??= Timer(const Duration(seconds: 3), end);
    } else {
      state = engine.isRecalculating
          ? NavigationState.rerouting
          : NavigationState.navigating;
    }
    notifyListeners();
  }

  void panAway() {
    if (active && following) {
      following = false;
      notifyListeners();
    }
  }

  void recenter() {
    following = true;
    notifyListeners();
  }

  void end({bool notify = true}) {
    _generation++;
    state = NavigationState.idle;
    route = null;
    starting = false;
    error = null;
    _freshnessTimer?.cancel();
    _freshnessTimer = null;
    _arrivalTimer?.cancel();
    _arrivalTimer = null;
    engine.stopTracking();
    LocationService.instance.setNavigationMode(false);
    if (_ownsLocation) {
      _ownsLocation = false;
      LocationService.instance.stopLiveTracking(callbackKey: this);
    }
    unawaited(_keepScreenOn(false));
    if (notify) notifyListeners();
  }

  Future<void> _keepScreenOn(bool enabled) async {
    if (LocationService.enableTestMode ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('keepScreenOn', enabled);
    } on MissingPluginException {
      /* Other supported platforms keep normal lifecycle. */
    }
  }

  @override
  void dispose() {
    engine.removeListener(_onEngineChanged);
    end(notify: false);
    super.dispose();
  }
}

double maneuverRotation(String? modifier) => switch (modifier) {
  'slight right' => 30,
  'right' => 90,
  'sharp right' => 135,
  'uturn' => 180,
  'slight left' => -30,
  'left' => -90,
  'sharp left' => -135,
  _ => 0,
};

String navigationDistance(double meters) => meters >= 1000
    ? '${(meters / 1000).toStringAsFixed(1)} km'
    : '${math.max(0, (meters / 10).round() * 10)} m';
