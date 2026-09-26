import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Interpolates between two positions over time for smooth avatar animation.
///
/// Instead of jumping from GPS fix to GPS fix, this generates intermediate
/// frames at 30-60 FPS based on elapsed time and estimated velocity.
class PositionInterpolator extends ChangeNotifier {
  PositionInterpolator();

  LatLng? _lastKnownPosition;
  LatLng? _targetPosition;
  DateTime? _lastUpdateTime;
  DateTime? _animationStartTime;
  LatLng? _animationStartPosition;
  Timer? _animationTimer;
  static const int _animationFps = 30;
  static const Duration _animationFrameDuration = Duration(milliseconds: 1000 ~/ _animationFps);
  static const Duration _maxInterpolationDuration = Duration(milliseconds: 2000);

  /// Current interpolated position (or last known if no animation in progress)
  LatLng? get currentInterpolatedPosition {
    if (_animationStartTime == null || _animationStartPosition == null || _targetPosition == null) {
      return _lastKnownPosition;
    }

    final now = DateTime.now();
    final elapsed = now.difference(_animationStartTime!);

    if (elapsed >= _maxInterpolationDuration) {
      // Animation complete
      return _targetPosition;
    }

    // Linear interpolation
    final progress = elapsed.inMilliseconds / _maxInterpolationDuration.inMilliseconds;
    return _lerpLatLng(_animationStartPosition!, _targetPosition!, progress);
  }

  /// Called when a new GPS position arrives
  void updatePosition(LatLng newPosition) {
    final now = DateTime.now();

    if (_lastKnownPosition == null) {
      // First position - no interpolation needed
      _lastKnownPosition = newPosition;
      _targetPosition = newPosition;
      notifyListeners();
      return;
    }

    // If we're very close to the last update (< 500ms), just update target
    if (_lastUpdateTime != null && now.difference(_lastUpdateTime!) < const Duration(milliseconds: 500)) {
      _targetPosition = newPosition;
      return;
    }

    // Start interpolation from current displayed position to new position
    _animationStartPosition = currentInterpolatedPosition ?? _lastKnownPosition;
    _animationStartTime = now;
    _targetPosition = newPosition;
    _lastKnownPosition = newPosition;
    _lastUpdateTime = now;

    // Cancel any existing animation timer
    _animationTimer?.cancel();

    // Start frame-by-frame animation
    _animationTimer = Timer.periodic(_animationFrameDuration, (_) {
      final elapsed = DateTime.now().difference(_animationStartTime!);
      if (elapsed >= _maxInterpolationDuration) {
        _animationTimer?.cancel();
        _animationTimer = null;
      }
      notifyListeners();
    });

    notifyListeners();
  }

  /// Immediately snap to a position (e.g., when user manually moves map)
  void snapTo(LatLng position) {
    _animationTimer?.cancel();
    _animationTimer = null;
    _animationStartTime = null;
    _animationStartPosition = null;
    _lastKnownPosition = position;
    _targetPosition = position;
    notifyListeners();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _animationTimer = null;
    super.dispose();
  }

  /// Linear interpolation between two LatLng points
  LatLng _lerpLatLng(LatLng a, LatLng b, double t) {
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }
}