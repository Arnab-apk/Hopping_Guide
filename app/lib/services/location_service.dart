import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// Real device location and continuous distance tracking service
class LocationService extends ChangeNotifier {
  static final LocationService instance = LocationService();

  // Default fallback: Esplanade / Central Kolkata
  static const LatLng defaultKolkataCenter = LatLng(22.5697, 88.3533);

  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionStreamSub;
  StreamSubscription<CompassEvent>? _compassStreamSub;
  bool _isPaused = false;
  DateTime? _lastBroadcastTime;
  static bool enableTestMode = false;
  bool _isTestLiveTracking = false;
  void Function(Position)? _testLocationCallback;

  // Heading fusion: GPS heading (when moving > 5 km/h) + compass (when slow/stationary)
  double? _lastCompassHeading;
  DateTime? _lastCompassUpdate;
  double? _fusedHeading;

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
  Future<bool> startLiveTracking({
    void Function(Position)? onLocationChanged,
    Duration throttleInterval = const Duration(milliseconds: 1500),
  }) async {
    if (enableTestMode) {
      _isTestLiveTracking = true;
      _testLocationCallback = onLocationChanged;
      notifyListeners();
      return true;
    }
    if (_positionStreamSub != null) return true;
    _isPaused = false;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services disabled on device.';
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied by user.';
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions permanently denied.';
        notifyListeners();
        return false;
      }

      // Initial fast fix
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      ).then((pos) {
        _currentPosition = pos;
        notifyListeners();
        onLocationChanged?.call(pos);
      }).catchError((_) {});

      _positionStreamSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
        ),
      ).listen(
        (position) {
          if (_isPaused) return;

          final now = DateTime.now();
          if (_lastBroadcastTime != null &&
              now.difference(_lastBroadcastTime!) < throttleInterval) {
            // Check if movement is significant (> 12m) to bypass throttle interval
            final last = _currentPosition;
            if (last != null &&
                Geolocator.distanceBetween(
                  last.latitude,
                  last.longitude,
                  position.latitude,
                  position.longitude,
                ) < 12.0) {
              return;
            }
          }

          _lastBroadcastTime = now;
          _currentPosition = position;
          _error = null;
          _updateFusedHeading(); // Update fused heading with new GPS data
          notifyListeners();
          onLocationChanged?.call(position);
        },
        onError: (err) {
          _error = err.toString();
          notifyListeners();
        },
      );

      // Start compass stream for heading fusion
      await _startCompassStream();

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
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
      if (compassAge < 5) { // Compass reading is fresh
        fused = compassHeading;
      }
    }

    if (fused != null && fused != _fusedHeading) {
      _fusedHeading = fused;
      notifyListeners();
    }
  }

  /// Stops continuous live GPS stream
  void stopLiveTracking() {
    if (enableTestMode) {
      _isTestLiveTracking = false;
      _testLocationCallback = null;
    }
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
    _compassStreamSub?.cancel();
    _compassStreamSub = null;
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
    final startLat = _currentPosition?.latitude ?? defaultKolkataCenter.latitude;
    final startLng = _currentPosition?.longitude ?? defaultKolkataCenter.longitude;

    return Geolocator.distanceBetween(
      startLat,
      startLng,
      targetLat,
      targetLng,
    );
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
