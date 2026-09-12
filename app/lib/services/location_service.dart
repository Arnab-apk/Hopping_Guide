import 'package:geolocator/geolocator.dart';

import '../utils/haversine.dart';

/// Device location + nearest-pandal sort (P0).
/// Distance is computed client-side via haversine over our own dataset — no
/// API calls needed.
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  /// Returns the current device position, requesting permissions as needed.
  Future<Position> currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission denied.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Stream of positions for live updates (used by the background service).
  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

  /// Sort a list of {lat,lng} items by distance to [from], returning indices
  /// in nearest-first order. (Inline implementation to keep deps light.)
  List<int> nearestFirst({
    required double fromLat,
    required double fromLng,
    required List<({double lat, double lng})> items,
  }) {
    final distances = [
      for (var i = 0; i < items.length; i++)
        (i: i, m: haversineMeters(fromLat, fromLng, items[i].lat, items[i].lng))
    ]..sort((a, b) => a.m.compareTo(b.m));
    return [for (final e in distances) e.i];
  }
}
