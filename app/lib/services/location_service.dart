import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Real device location and continuous distance tracking service
class LocationService extends ChangeNotifier {
  static final LocationService instance = LocationService();

  // Default fallback: Esplanade / Central Kolkata
  static const LatLng defaultKolkataCenter = LatLng(22.5697, 88.3533);

  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionStreamSub;
  bool _isPaused = false;
  DateTime? _lastBroadcastTime;

  Position? get currentPositionSync => _currentPosition;
  Position? get lastPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLiveTracking => _positionStreamSub != null;
  bool get isPaused => _isPaused;
  double? get currentHeading => _currentPosition?.heading;
  double? get currentAccuracy => _currentPosition?.accuracy;

  /// Async getter for location compatibility
  Future<Position?> currentPosition() async {
    if (_currentPosition != null) return _currentPosition;
    return await updateLiveLocation();
  }

  LatLng get currentCoordinates => _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : defaultKolkataCenter;

  bool get hasRealLocation => _currentPosition != null;

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
          notifyListeners();
          onLocationChanged?.call(position);
        },
        onError: (err) {
          _error = err.toString();
          notifyListeners();
        },
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Stops continuous live GPS stream
  void stopLiveTracking() {
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
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
