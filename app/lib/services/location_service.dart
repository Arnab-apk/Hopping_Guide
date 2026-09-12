import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Real device location and distance service
class LocationService extends ChangeNotifier {
  static final LocationService instance = LocationService();

  // Default fallback: Esplanade / Central Kolkata
  static const LatLng defaultKolkataCenter = LatLng(22.5697, 88.3533);

  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;

  Position? get currentPositionSync => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Async getter for location compatibility
  Future<Position?> currentPosition() async {
    if (_currentPosition != null) return _currentPosition;
    return await updateLiveLocation();
  }

  LatLng get currentCoordinates => _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : defaultKolkataCenter;

  bool get hasRealLocation => _currentPosition != null;

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
