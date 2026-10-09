import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../utils/navigation_heading.dart';

/// Power profile for adaptive GPS/battery management
enum PowerProfile { normal, pandalHopping, emergency }

/// Real device location and continuous distance tracking service
class LocationService extends ChangeNotifier {
  static final LocationService instance = LocationService();

  // Default fallback: Esplanade / Central Kolkata
  static const LatLng defaultKolkataCenter = LatLng(22.5697, 88.3533);

  // Current power profile - affects GPS polling rate, accuracy, wake locks
  PowerProfile _powerProfile = PowerProfile.normal;
  PowerProfile get powerProfile => _powerProfile;

  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionStreamSub;
  StreamSubscription<CompassEvent>? _compassStreamSub;
  bool _isPaused = false;
  bool _navigationMode = false;
  void setNavigationMode(bool active) {
    if (_navigationMode == active) return;
    _navigationMode = active;
    _lastBroadcastTime = null;
    _throttleInterval = active
        ? const Duration(seconds: 1)
        : const Duration(milliseconds: 1500);
    if (_positionStreamSub != null && !enableTestMode) _restartPositionStream();
  }

  DateTime? _lastBroadcastTime;
  Duration _throttleInterval = const Duration(milliseconds: 1500);
  static bool enableTestMode = false;
  bool _isTestLiveTracking = false;
  void Function(Position)? _testLocationCallback;

  // Wake lock for keeping screen on during navigation
  // ignore: unused_field
  Object? _wakeLock;

  // Heading fusion: GPS heading (when moving > 5 km/h) + compass (when slow/stationary)
  double? _lastCompassHeading;
  DateTime? _lastCompassUpdate;
  double? _fusedHeading;

  /// Set power profile - dynamically adjusts GPS polling, accuracy, and wake locks
  /// Call this when user toggles "Pandal Hopping Mode" in settings
  Future<void> setPowerProfile(PowerProfile profile) async {
    if (_powerProfile == profile) return;

    debugPrint(
      '[LocationService] 🔋 Power profile: ${_powerProfile.name} → ${profile.name}',
    );
    _powerProfile = profile;

    // Restart position stream with new settings
    if (_positionStreamSub != null && !enableTestMode) {
      _restartPositionStream();
    }

    // Manage wake lock
    await _manageWakeLock();

    notifyListeners();
  }

  Future<void> _manageWakeLock() async {
    // In a real implementation, use wakelock_plus or flutter_wakelock
    // For now, we track the intent; UI should show persistent notification when active
    switch (_powerProfile) {
      case PowerProfile.pandalHopping:
      case PowerProfile.emergency:
        // Acquire partial wake lock - keep CPU alive for GPS
        // await WakelockPlus.enable();
        debugPrint(
          '[LocationService] 🔒 Wake lock ACQUIRED for ${_powerProfile.name}',
        );
        break;
      case PowerProfile.normal:
        // Release wake lock
        // await WakelockPlus.disable();
        debugPrint('[LocationService] 🔓 Wake lock RELEASED');
        break;
    }
  }

  void _restartPositionStream() {
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
    if (enableTestMode || _trackingRefCount == 0) return;
    _listenToPositionStream();
  }

  void _listenToPositionStream() {
    _positionStreamSub = _createPositionStream().listen(
      (position) {
        if (_isPaused) return;
        final now = DateTime.now();
        if (_lastBroadcastTime != null &&
            now.difference(_lastBroadcastTime!) < _throttleInterval) {
          final last = _currentPosition;
          if (last != null &&
              Geolocator.distanceBetween(
                    last.latitude,
                    last.longitude,
                    position.latitude,
                    position.longitude,
                  ) <
                  12.0) {
            return;
          }
        }
        _lastBroadcastTime = now;
        _currentPosition = position;
        _error = null;
        _updateFusedHeading();
        notifyListeners();
        for (final cb in _locationListeners.values.toList()) {
          try {
            cb(position);
          } catch (_) {}
        }
      },
      onError: (err) {
        _error = err.toString();
        notifyListeners();
      },
    );
  }

  Stream<Position> _createPositionStream() {
    final settings = _getLocationSettingsForProfile();
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  LocationSettings _getLocationSettingsForProfile() {
    if (_navigationMode) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 1),
        );
      }
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }
    switch (_powerProfile) {
      case PowerProfile.normal:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2, // 2 meters
        );
      case PowerProfile.pandalHopping:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
      case PowerProfile.emergency:
        return const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 50,
        );
    }
  }

  void emitTestPosition(Position pos) {
    _currentPosition = pos;
    notifyListeners();
    _testLocationCallback?.call(pos);
  }

  Position? get currentPositionSync => _currentPosition;
  Position? get lastPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLiveTracking => _positionStreamSub != null || _isTestLiveTracking;
  bool get isPaused => _isPaused;
  double? get currentHeading => _fusedHeading ?? _currentPosition?.heading;
  double? get rawGpsHeading => _currentPosition?.heading;
  double? get compassHeading => _lastCompassHeading;
  double? get facingHeading => navigationHeading(
    compass: _lastCompassHeading,
    compassFresh:
        _lastCompassUpdate != null &&
        DateTime.now().difference(_lastCompassUpdate!).inSeconds < 5,
    gps: _currentPosition?.heading,
    speed: _currentPosition?.speed ?? 0,
  );

  @visibleForTesting
  void emitTestHeading(double heading) {
    if (!enableTestMode) return;
    _lastCompassHeading = heading;
    _lastCompassUpdate = DateTime.now();
    _updateFusedHeading();
    notifyListeners();
  }

  double? get currentAccuracy => _currentPosition?.accuracy;

  /// Async getter for location compatibility
  Future<Position?> currentPosition() async {
    if (_currentPosition != null) return _currentPosition;
    if (enableTestMode) return _currentPosition;
    return await updateLiveLocation();
  }

  LatLng get currentCoordinates => _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : defaultKolkataCenter;

  bool get hasRealLocation => _currentPosition != null;

  /// Resolves the current device location permission status without triggering a prompt
  static Future<LocationPermission> resolvePermissionStatus() async {
    try {
      return await Geolocator.checkPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  /// Pauses location updates dispatching (used when map is hidden/in background)
  void pauseLiveTracking() {
    _isPaused = true;
  }

  /// Resumes location updates dispatching
  void resumeLiveTracking() {
    _isPaused = false;
  }

  /// Starts real-time continuous GPS tracking stream with high accuracy and smart throttling
  /// Uses reference counting to support multiple simultaneous consumers.
  int _trackingRefCount = 0;
  final Map<Object, void Function(Position)> _locationListeners = {};

  void addLocationCallback(Object key, void Function(Position) callback) {
    _locationListeners[key] = callback;
    if (_currentPosition != null) {
      try {
        callback(_currentPosition!);
      } catch (_) {}
    }
  }

  void removeLocationCallback(Object key) {
    _locationListeners.remove(key);
  }

  Future<bool> startLiveTracking({
    Object? callbackKey,
    void Function(Position)? onLocationChanged,
    Duration throttleInterval = const Duration(milliseconds: 1500),
  }) async {
    _trackingRefCount++;
    _throttleInterval = _navigationMode ? const Duration(seconds: 1) : throttleInterval;
    if (callbackKey != null && onLocationChanged != null) {
      _locationListeners[callbackKey] = onLocationChanged;
    }
    if (enableTestMode) {
      _isTestLiveTracking = true;
      _testLocationCallback = onLocationChanged;
      notifyListeners();
      return true;
    }
    if (_positionStreamSub != null) {
      if (_currentPosition != null && onLocationChanged != null) {
        onLocationChanged(_currentPosition!);
      }
      return true;
    }
    _isPaused = false;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services disabled on device.';
        notifyListeners();
        return _trackingStartFailed(callbackKey);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied by user.';
          notifyListeners();
          return _trackingStartFailed(callbackKey);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions permanently denied.';
        notifyListeners();
        return _trackingStartFailed(callbackKey);
      }

      // Initial fast fix
      Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 6),
            ),
          )
          .then((pos) {
            _currentPosition = pos;
            notifyListeners();
            for (final cb in _locationListeners.values.toList()) {
              try {
                cb(pos);
              } catch (_) {}
            }
          })
          .catchError((_) {});

      _listenToPositionStream();

      // Start compass stream for heading fusion
      await _startCompassStream();

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return _trackingStartFailed(callbackKey);
    }
  }

  bool _trackingStartFailed(Object? callbackKey) {
    if (callbackKey != null) _locationListeners.remove(callbackKey);
    _trackingRefCount = (_trackingRefCount - 1).clamp(0, 100);
    return false;
  }

  /// Starts compass stream for heading fusion (when GPS heading is unreliable)
  Future<void> _startCompassStream() async {
    if (_compassStreamSub != null) return;
    try {
      _compassStreamSub = FlutterCompass.events?.listen((event) {
        if (event.heading != null && !event.heading!.isNaN) {
          _lastCompassHeading = event.heading;
          _lastCompassUpdate = DateTime.now();
          _updateFusedHeading();
        }
      });
    } catch (e) {
      debugPrint('[LocationService] Compass stream error: $e');
    }
  }

  void _updateFusedHeading() {
    final gpsHeading = _currentPosition?.heading;
    final compassHeading = _lastCompassHeading;
    final now = DateTime.now();

    // Use GPS heading when:
    // 1. GPS heading is available AND
    // 2. Speed > 1.5 m/s (~5.4 km/h) OR GPS accuracy < 20m
    // Otherwise use compass heading
    double? fused;
    if (gpsHeading != null && !gpsHeading.isNaN) {
      final speed = _currentPosition?.speed ?? 0;
      final accuracy = _currentPosition?.accuracy ?? 999;
      if (speed > 1.5 || accuracy < 20) {
        fused = gpsHeading;
      }
    }

    // Fall back to compass if GPS not reliable
    if (fused == null && compassHeading != null && !compassHeading.isNaN) {
      final compassAge = now.difference(_lastCompassUpdate ?? now).inSeconds;
      if (compassAge < 5) {
        // Compass reading is fresh
        fused = compassHeading;
      }
    }

    if (fused != null && fused != _fusedHeading) {
      _fusedHeading = fused;
      notifyListeners();
    }
  }

  /// Stops continuous live GPS stream
  /// Uses reference counting - only actually stops when all consumers have called stop.
  void stopLiveTracking({Object? callbackKey}) {
    if (callbackKey != null) {
      _locationListeners.remove(callbackKey);
    }
    _trackingRefCount = (_trackingRefCount - 1).clamp(0, 100);

    // Only actually stop the GPS stream when no more consumers
    if (_trackingRefCount == 0) {
      if (enableTestMode) {
        _isTestLiveTracking = false;
        _testLocationCallback = null;
      }
      _positionStreamSub?.cancel();
      _positionStreamSub = null;
      _compassStreamSub?.cancel();
      _compassStreamSub = null;
      // Note: We don't clear _locationListeners here to preserve callbacks
      // for components that may still need the last known position

      // Release wake lock when tracking fully stops
      _manageWakeLock();
    }
    notifyListeners();
  }

  /// Request permission and fetch live device GPS
  Future<Position?> updateLiveLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services disabled on device.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied by user.';
          _isLoading = false;
          notifyListeners();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions permanently denied.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _currentPosition = pos;
      _isLoading = false;
      notifyListeners();
      return pos;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Calculates real distance in meters between user position and a target coordinate
  double distanceToMeters(double targetLat, double targetLng) {
    final startLat =
        _currentPosition?.latitude ?? defaultKolkataCenter.latitude;
    final startLng =
        _currentPosition?.longitude ?? defaultKolkataCenter.longitude;

    return Geolocator.distanceBetween(startLat, startLng, targetLat, targetLng);
  }

  /// Formatted human-readable distance (e.g. "350 m", "2.4 km")
  String formatDistance(double targetLat, double targetLng) {
    final meters = distanceToMeters(targetLat, targetLng);
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
}
