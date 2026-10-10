import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kolkata_puja/services/location_service.dart';

class _DelayedGps extends GeolocatorPlatform {
  final cancelled = Completer<void>();
  final settings = <LocationSettings?>[];
  final controllers = <StreamController<Position>>[];

  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => fix();
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    settings.add(locationSettings);
    final controller = StreamController<Position>(
      onCancel: controllers.isEmpty ? () => cancelled.future : null,
    );
    controllers.add(controller);
    return controller.stream;
  }

  Position fix() => Position(
    latitude: 22.55,
    longitude: 88.35,
    timestamp: DateTime.now(),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'navigation waits for old GPS cancellation and receives replacement fixes',
    () async {
      final original = GeolocatorPlatform.instance;
      final gps = _DelayedGps();
      GeolocatorPlatform.instance = gps;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final location = LocationService();
      try {
        expect(await location.startLiveTracking(), isTrue);
        location.setNavigationMode(true);
        final ready = location.startLiveTracking();
        await Future<void>.delayed(Duration.zero);
        expect(
          gps.settings.length,
          1,
          reason: 'No new stream before native cancellation finishes',
        );
        gps.cancelled.complete();
        expect(await ready, isTrue);
        expect(gps.settings.length, 2);
        final navigation = gps.settings.last as AndroidSettings;
        expect(navigation.intervalDuration, const Duration(seconds: 1));
        expect(navigation.distanceFilter, 0);
        final fix = gps.fix();
        gps.controllers.last.add(fix);
        await Future<void>.delayed(Duration.zero);
        expect(location.currentPositionSync, same(fix));
      } finally {
        location.stopLiveTracking();
        location.stopLiveTracking();
        location.dispose();
        GeolocatorPlatform.instance = original;
        debugDefaultTargetPlatformOverride = null;
        for (final controller in gps.controllers) {
          await controller.close();
        }
      }
    },
  );
}
