import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/services/journey_planner.dart';
import 'package:kolkata_puja/services/multimodal_routing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'live car, train and metro comparison returns connected guidance',
    () async {
      final previous = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previous);
      final route = await JourneyPlanner.instance.plan(
        origin: const LatLng(22.899, 88.393),
        destination: const LatLng(22.505381, 88.314308),
        destinationName: 'Behala Club',
        allowDriving: true,
      );
      expect(route.isFallback, false);
      expect(route.legs, isNotEmpty);
      for (var i = 1; i < route.legs.length; i++) {
        expect(route.legs[i].startPoint, route.legs[i - 1].endPoint);
      }
      expect(
        route.legs.whereType<WalkLeg>().every(
          (leg) => leg.steps.isNotEmpty || leg.distanceMeters < 10,
        ),
        true,
      );
      debugPrint(
        'Live comparison: ${route.bestModeBadge}, ${route.formattedTotalDuration}; ${route.summary}',
      );
    },
    skip: !const bool.fromEnvironment('VERIFY_MAPBOX_LIVE'),
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
