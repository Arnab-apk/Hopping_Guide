import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/config/app_config.dart';
import 'package:kolkata_puja/services/routing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'configured Mapbox integration returns live Kolkata walking maneuvers',
    () async {
      final previous = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previous);
      expect(AppConfig.mapboxAccessToken, isNotEmpty);
      final route = await RoutingService.instance.getLiveWalkingRouteToPoint(
        start: const LatLng(22.5536, 88.3517),
        destination: const LatLng(22.5582, 88.3555),
        destinationName: 'Kolkata walking smoke check',
      );
      expect(route.isFallback, isFalse);
      expect(route.points.length, greaterThan(2));
      expect(route.steps.length, greaterThan(2));
      expect(route.steps.last.type, 'arrive');
      expect(route.distanceMeters, greaterThan(0));
      expect(route.durationSeconds, greaterThan(0));
    },
    skip: !const bool.fromEnvironment('VERIFY_MAPBOX_LIVE'),
  );
}
