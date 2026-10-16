import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/widgets/live_tracking_marker_layer.dart';
import 'package:kolkata_puja/services/position_interpolator.dart';
import 'package:latlong2/latlong.dart';

const _a = LatLng(22.57, 88.35);
const _b = LatLng(22.5705, 88.35);

void main() {
  testWidgets('retargeting preserves continuity and stale reconnects snap', (
    tester,
  ) async {
    var now = DateTime(2026);
    final position = PositionInterpolator(now: () => now);
    position.updatePosition(_a);
    now = now.add(const Duration(seconds: 1));
    position.updatePosition(_b);
    await tester.pump(const Duration(milliseconds: 330));
    final displayed = position.currentInterpolatedPosition!;
    expect(displayed.latitude, greaterThan(_a.latitude));
    expect(displayed.latitude, lessThan(_b.latitude));
    now = now.add(const Duration(milliseconds: 330));
    const next = LatLng(22.5706, 88.35);
    position.updatePosition(next);
    expect(position.currentInterpolatedPosition, displayed);
    await tester.pump(const Duration(seconds: 1));
    expect(position.currentInterpolatedPosition, next);
    now = now.add(const Duration(seconds: 30));
    position.updatePosition(_a);
    expect(position.currentInterpolatedPosition, _a);
    position.dispose();
  });

  testWidgets('identical updates cannot keep an animation running forever', (
    tester,
  ) async {
    final position = PositionInterpolator();
    position.updatePosition(_a);
    position.updatePosition(_b);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      position.updatePosition(_b);
    }
    expect(position.currentInterpolatedPosition, _b);
    position.dispose();
  });

  Widget map(
    List<Marker> markers, {
    bool reduced = false,
    Set<Key> snap = const {},
    bool ticking = true,
    void Function(Key, LatLng)? onFrame,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: TickerMode(
        enabled: ticking,
        child: FlutterMap(
          options: const MapOptions(initialCenter: _a, initialZoom: 16),
          children: [
            LiveTrackingMarkerLayer(
              markers: markers,
              snapKeys: snap,
              onPositionFrame: onFrame,
            ),
          ],
        ),
      ),
    ),
  );
  Marker marker(String id, LatLng point) =>
      Marker(key: ValueKey(id), point: point, child: Text(id));
  LatLng point(WidgetTester tester, String id) => tester
      .widget<MarkerLayer>(find.byType(MarkerLayer))
      .markers
      .firstWhere((marker) => marker.key == ValueKey(id))
      .point;

  testWidgets(
    'markers advance each display frame and stop work on hidden tabs',
    (tester) async {
      var frames = 0;
      void onFrame(Key key, LatLng position) => frames++;
      await tester.pumpWidget(map([marker('self', _a)], onFrame: onFrame));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(map([marker('self', _b)], onFrame: onFrame));
      await tester.pump(const Duration(milliseconds: 16));
      expect(point(tester, 'self').latitude, greaterThan(_a.latitude));
      await tester.pumpWidget(
        map([marker('self', _b)], ticking: false, onFrame: onFrame),
      );
      final hiddenFrames = frames;
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        frames,
        hiddenFrames,
        reason: 'Hidden map tabs must not animate markers or move the camera',
      );
      await tester.pumpWidget(map([marker('self', _b)], onFrame: onFrame));
      await tester.pump(const Duration(seconds: 2));
      expect(point(tester, 'self'), _b);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('self and squad move smoothly and stop at received positions', (
    tester,
  ) async {
    await tester.pumpWidget(map([marker('self', _a), marker('friend', _a)]));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpWidget(map([marker('friend', _b), marker('self', _b)]));
    await tester.pump(const Duration(milliseconds: 99));
    for (final id in ['self', 'friend']) {
      expect(point(tester, id).latitude, greaterThan(_a.latitude));
      expect(point(tester, id).latitude, lessThan(_b.latitude));
    }
    await tester.pump(const Duration(milliseconds: 1100));
    expect(point(tester, 'self'), _b);
    expect(point(tester, 'friend'), _b);
    await tester.pump(const Duration(seconds: 10));
    expect(point(tester, 'friend'), _b);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'large GPS correction and stale member updates snap immediately',
    (tester) async {
      await tester.pumpWidget(map([marker('self', _a), marker('friend', _a)]));
      const far = LatLng(22.59, 88.37);
      await tester.pumpWidget(
        map(
          [marker('self', far), marker('friend', _b)],
          snap: {const ValueKey('friend')},
        ),
      );
      expect(point(tester, 'self'), far);
      expect(point(tester, 'friend'), _b);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('reduced motion snaps and member removal cancels animation', (
    tester,
  ) async {
    await tester.pumpWidget(map([marker('friend', _a)]));
    await tester.pumpWidget(map([marker('friend', _b)], reduced: true));
    expect(point(tester, 'friend'), _b);
    await tester.pumpWidget(map([]));
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
