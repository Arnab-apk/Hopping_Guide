import 'package:flutter/foundation.dart';

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/services/journey_planner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Chuchura to south Kolkata has connected streets, train and metro',
    () async {
      final previous = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previous);
      final route = await JourneyPlanner.instance.plan(
        origin: const LatLng(22.899, 88.393),
        destination: const LatLng(22.5237, 88.3456),
        destinationName: 'Suruchi Sangha',
      );
      expect(route.trainLegs, isNotEmpty);
      expect(route.metroLegs, isNotEmpty);
      expect(
        route.walkLegs.every(
          (leg) =>
              !leg.isFallback &&
              (leg.distanceMeters < 10 || leg.steps.isNotEmpty),
        ),
        isTrue,
      );
      for (var i = 1; i < route.legs.length; i++) {
        expect(route.legs[i].startPoint, route.legs[i - 1].endPoint);
      }
      expect(route.legs.first.startPoint, const LatLng(22.899, 88.393));
      expect(route.legs.last.endPoint, const LatLng(22.5237, 88.3456));
      expect(route.trainLegs.first.geometryEstimated, isFalse);
      debugPrint(
        'Live itinerary: ${route.legs.map((leg) => leg.instructions).join(' -> ')}; ${route.formattedTotalDuration}',
      );
    },
    skip: !const bool.fromEnvironment('VERIFY_MAPBOX_LIVE'),
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
