import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kolkata_puja/services/location_service.dart';

class _PermissionGps extends GeolocatorPlatform {
  int requests = 0;
  final answer = Completer<LocationPermission>();
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;
  @override
  Future<LocationPermission> requestPermission() {
    requests++;
    return answer.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('map and joining group share one native permission request', () async {
    final previous = GeolocatorPlatform.instance;
    final gps = _PermissionGps();
    GeolocatorPlatform.instance = gps;
    try {
      final map = LocationService.requestLocationPermission();
      final group = LocationService.requestLocationPermission();
      await Future<void>.delayed(Duration.zero);
      expect(gps.requests, 1);
      gps.answer.complete(LocationPermission.whileInUse);
      expect(await map, LocationPermission.whileInUse);
      expect(await group, LocationPermission.whileInUse);
    } finally {
      GeolocatorPlatform.instance = previous;
    }
  });
}
