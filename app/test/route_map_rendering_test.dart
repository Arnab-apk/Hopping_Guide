import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/models/route_polyline_segment.dart';
import 'package:kolkata_puja/services/routing_service.dart';
import 'package:kolkata_puja/widgets/route_polylines.dart';

void main() {
  const points = [LatLng(22.57, 88.35), LatLng(22.571, 88.351)];
  for (final mode in RouteSegmentType.values) {
    for (final dark in [false, true]) {
      testWidgets('$mode directions keep the map visible (dark=$dark)', (
        tester,
      ) async {
        final route = WalkingRoute(
          points: points,
          distanceMeters: 150,
          durationSeconds: 120,
          segments: [
            RoutePolylineSegment(
              points: points,
              type: mode,
              color: Colors.blue,
            ),
          ],
        );
        final polylines = buildHighlightedRoutePolylines(route, dark);
        expect(polylines, hasLength(2));
        expect(polylines.last.points, points);
        if (mode != RouteSegmentType.walk) {
          expect(polylines.last.color, Colors.blue);
        }
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlutterMap(
                options: const MapOptions(initialCenter: LatLng(22.57, 88.35)),
                children: [PolylineLayer(polylines: polylines)],
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(FlutterMap), findsOneWidget);
        expect(find.byType(PolylineLayer), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
