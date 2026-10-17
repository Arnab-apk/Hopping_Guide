import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/config/pujo_map_style.dart';
import 'package:kolkata_puja/widgets/pujo_map.dart';
import 'package:kolkata_puja/widgets/pujo_map_layers.dart';
import 'package:kolkata_puja/widgets/pujo_native_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

ml.MapLibrePlatform createNativeMapTestPlatform() => _NativeMap();

class _NativeMap extends ml.MapLibrePlatform {
  bool created = false;
  final moves = <dynamic>[];
  final writes = <Map<String, dynamic>>[];
  final images = <String, Uint8List>{};
  final symbolLayers = <String, Map<String, dynamic>>{};
  int sources = 0;
  double pixelRatio = 1;
  double projectedX = 120;
  int projectionCalls = 0;
  ml.LatLngBounds region = ml.LatLngBounds(
    southwest: const ml.LatLng(22.4, 88.2),
    northeast: const ml.LatLng(22.7, 88.5),
  );

  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    void Function(int) onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) {
    if (!created) {
      created = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => onPlatformViewCreated(1),
      );
    }
    return const ColoredBox(key: ValueKey('native-map'), color: Colors.white);
  }

  @override
  Future<void> initPlatform(int id) async {}
  @override
  Future<void> addImage(
    String name,
    Uint8List bytes, [
    bool sdf = false,
  ]) async {
    images[name] = bytes;
  }

  @override
  Future<void> addSymbolLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    bool enableInteraction = true,
  }) async {
    symbolLayers[layerId] = properties;
  }

  @override
  Future<ml.CameraPosition?> updateMapOptions(
    Map<String, dynamic> optionsUpdate,
  ) async => null;
  @override
  Future<bool?> moveCamera(ml.CameraUpdate cameraUpdate) async {
    moves.add(cameraUpdate.toJson());
    return true;
  }

  @override
  Future<List<math.Point>> toScreenLocationBatch(
    Iterable<ml.LatLng> points,
  ) async {
    projectionCalls++;
    return [
      for (final _ in points)
        math.Point(projectedX * pixelRatio, 160 * pixelRatio),
    ];
  }

  @override
  Future<ml.LatLngBounds> getVisibleRegion() async => region;
  @override
  Future<void> addGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson, {
    String? promoteId,
  }) async {
    sources++;
  }

  @override
  Future<void> setGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson,
  ) async {
    writes.add(geojson);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('both bundled styles retain vector sources, attribution, labels and 3D buildings', () async {
    for (final dark in [false, true]) {
      final style = jsonDecode(await PujoMapStyle.load(dark: dark)) as Map;
      expect(
        style['sources']['openmaptiles']['url'],
        'https://tiles.openfreemap.org/planet',
      );
      final layers = style['layers'] as List;
      expect(
        layers.where((layer) => layer['type'] == 'fill-extrusion'),
        isNotEmpty,
      );
      expect(layers.where((layer) => layer['type'] == 'symbol'), isNotEmpty);
    }
    final simple = jsonDecode(
      await PujoMapStyle.load(dark: false, moreNames: false),
    ) as Map;
    for (final layer in simple['layers'] as List) {
      if (layer['type'] == 'symbol' && layer['source-layer'] == 'poi') {
        expect(layer['layout']['visibility'], 'none');
      }
    }
  });

  test(
    'flat map hides buildings while retaining street labels in both themes',
    () async {
      for (final dark in [false, true]) {
        final style = jsonDecode(
          await PujoMapStyle.load(dark: dark, threeDimensional: false),
        ) as Map;
        final layers = style['layers'] as List;
        final buildings = layers.where(
          (layer) => layer['type'] == 'fill-extrusion',
        );
        expect(buildings, isNotEmpty);
        for (final layer in buildings) {
          expect(layer['layout']['visibility'], 'none');
        }
        expect(
          layers.where(
            (layer) =>
                layer['type'] == 'symbol' &&
                layer['layout']?['visibility'] != 'none',
          ),
          isNotEmpty,
        );
      }
    },
  );

  test(
    'routes preserve geographic order, width, opacity and dashed connectors',
    () {
      final features = pujoPolylineFeatures([
        Polyline(
          points: const [LatLng(22.5, 88.3), LatLng(22.6, 88.4)],
          color: const Color(0x802F6FE4),
          strokeWidth: 6,
          pattern: StrokePattern.dashed(segments: const [7, 4]),
        ),
      ]);
      expect(features.single['geometry']['coordinates'], [
        [88.3, 22.5],
        [88.4, 22.6],
      ]);
      expect(features.single['properties']['width'], 6);
      expect(features.single['properties']['dashed'], true);
      expect(features.single['properties']['opacity'], closeTo(0.5, 0.01));
    },
  );

  test('10 km boundary remains a geographic circle at every zoom', () {
    const center = LatLng(22.55, 88.35);
    final circles = [
      CircleMarker(
        point: center,
        radius: 10000,
        useRadiusInMeter: true,
        color: Colors.blue,
        borderStrokeWidth: 2,
      ),
    ];
    final low = pujoCircleFeatures(circles, 10);
    final high = pujoCircleFeatures(circles, 18);
    expect(high, low);
    final ring = low.first['geometry']['coordinates'][0] as List;
    expect(ring.first, ring.last);
    for (final point in ring) {
      expect(
        const Distance().as(
          LengthUnit.Meter,
          center,
          LatLng(point[1], point[0]),
        ),
        closeTo(10000, 1),
      );
    }
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      'native pins stay anchored, correctly sized and tappable on $platform',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        tester.view.devicePixelRatio = 3;
        addTearDown(() {
          debugDefaultTargetPlatformOverride = null;
          tester.view.resetDevicePixelRatio();
        });
        final native = _NativeMap();
        final controller = ml.MapLibreMapController(
          maplibrePlatform: native,
          initialCameraPosition: const ml.CameraPosition(
            target: ml.LatLng(22.55, 88.35),
          ),
          annotationOrder: const [],
          annotationConsumeTapEvents: const [],
        );
        final bridge = PujoMapBridge()..controller = controller;
        await bridge.styleLoaded();
        var taps = 0;
        final marker = Marker(
          point: const LatLng(22.55, 88.35),
          width: 40,
          height: 50,
          alignment: Alignment.topCenter,
          rotate: true,
          child: GestureDetector(
            onTap: () => taps++,
            child: const ColoredBox(color: Colors.red),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 40,
                height: 50,
                child: PujoNativeMarker(marker: marker, bridge: bridge),
              ),
            ),
          ),
        );
        for (var i = 0; i < 40 && !bridge.markerImageReady('uma-pin-0'); i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump(const Duration(milliseconds: 20));
        }
        await tester.pump();
        expect(native.images, isNotEmpty);
        final pin = (native.writes.last['features'] as List).single as Map;
        expect(pin['geometry'], {
          'type': 'Point',
          'coordinates': [88.35, 22.55],
        });
        expect(
          pin['properties']['scale'],
          platform == TargetPlatform.android ? 1.5 : 0.5,
        );
        expect(pin['properties']['offset'], [
          0.0,
          platform == TargetPlatform.android ? -50 / 3 : -50.0,
        ]);
        final symbol = native.symbolLayers['uma-pinned-markers']!;
        expect(symbol['icon-pitch-alignment'], 'viewport');
        expect(symbol['icon-allow-overlap'], true);
        expect(
          tester
              .widget<Opacity>(
                find.descendant(
                  of: find.byType(PujoNativeMarker),
                  matching: find.byType(Opacity),
                ),
              )
              .opacity,
          0.001,
        );
        await tester.tap(find.byType(PujoNativeMarker));
        expect(taps, 1);

        // Camera frames move the native point without changing its location or
        // waiting for a Flutter screen-projection response.
        final uploaded = native.images.values.single;
        bridge.cameraChanged();
        await tester.pump(const Duration(milliseconds: 100));
        expect(native.images.values.single, same(uploaded));
        final writesBeforeRefresh = native.writes.length;
        final markerState = tester.state(find.byType(PujoNativeMarker));
        bridge.setMarkerImage(
          markerState,
          'uma-pin-0',
          Uint8List.fromList(uploaded),
        );
        await tester.pump();
        await tester.pump();
        expect(
          native.writes.length,
          writesBeforeRefresh,
          reason: 'Artwork refresh must not reload unchanged symbol geometry',
        );
        expect(
          (native.writes.last['features'] as List).single['geometry'],
          pin['geometry'],
        );

        await bridge.styleLoaded();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          (native.writes.last['features'] as List).single['geometry'],
          pin['geometry'],
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        // Removed pins release their texture name for reuse by the next pin.
        expect(
          bridge.markerImageId(Object(), size: const Size(64, 74)),
          'uma-pin-0',
        );
        expect(
          bridge.markerImageId(Object(), size: const Size(84, 94)),
          isNot('uma-pin-0'),
          reason: 'Native atlas slots must never be reused with different image dimensions',
        );
        bridge.dispose();
        controller.dispose();
        debugDefaultTargetPlatformOverride = null;
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('reordering visible pins preserves each native marker state', (
    tester,
  ) async {
    final native = _NativeMap();
    final controller = ml.MapLibreMapController(
      maplibrePlatform: native,
      initialCameraPosition: const ml.CameraPosition(
        target: ml.LatLng(22.55, 88.35),
      ),
      annotationOrder: const [],
      annotationConsumeTapEvents: const [],
    );
    final bridge = PujoMapBridge()..controller = controller;
    await bridge.styleLoaded();
    final markers = [
      Marker(
        point: const LatLng(22.55, 88.35),
        child: const ColoredBox(color: Colors.red),
      ),
      Marker(
        point: const LatLng(22.56, 88.36),
        child: const ColoredBox(color: Colors.blue),
      ),
    ];
    Widget host(List<Marker> pins) => MaterialApp(
      home: PujoMapScope(
        notifier: bridge,
        child: PujoMarkerLayer(markers: pins),
      ),
    );
    await tester.pumpWidget(host(markers));
    await tester.pump();
    await tester.pump();
    final before = tester.stateList(find.byType(PujoNativeMarker)).toList();
    expect(before, hasLength(2));
    final projectionsBeforeUpload = native.projectionCalls;
    bridge.setFeatures(Object(), []);
    await tester.pump();
    await tester.pump();
    expect(
      native.projectionCalls,
      projectionsBeforeUpload,
      reason: 'Overlay writes must not reproject unchanged marker positions',
    );
    await tester.pumpWidget(host(markers.reversed.toList()));
    await tester.pump();
    await tester.pump();
    final after = tester.stateList(find.byType(PujoNativeMarker)).toList();
    expect(after[0], same(before[1]));
    expect(after[1], same(before[0]));
    await tester.pumpWidget(const SizedBox());
    bridge.dispose();
    controller.dispose();
  });

  testWidgets(
    'failed vector load falls back and retry keeps the current camera',
    (tester) async {
      final previousFactory = ml.MapLibrePlatform.createInstance;
      final native = _NativeMap();
      ml.MapLibrePlatform.createInstance = () => native;
      PujoMap.nativeMapsEnabled = true;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() {
        ml.MapLibrePlatform.createInstance = previousFactory;
        PujoMap.nativeMapsEnabled = false;
        debugDefaultTargetPlatformOverride = null;
      });
      final camera = MapController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PujoMap(
              mapController: camera,
              dark: false,
              options: const MapOptions(
                initialCenter: LatLng(22.55, 88.35),
                initialZoom: 15,
              ),
              children: const [],
            ),
          ),
        ),
      );
      for (
        var i = 0;
        i < 50 && find.byType(ml.MapLibreMap).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(ml.MapLibreMap), findsOneWidget);
      camera.moveAndRotate(const LatLng(22.61, 88.41), 16, 35);
      await tester.pump(const Duration(seconds: 26));
      await tester.pump();
      expect(find.text('Retry 3D map'), findsOneWidget);
      expect(find.byType(ml.MapLibreMap), findsNothing);
      expect(find.byType(TileLayer), findsOneWidget);
      native.created = false;
      await tester.runAsync(() => tester.tap(find.text('Retry 3D map')));
      await tester.pump();
      for (
        var i = 0;
        i < 50 && find.byType(ml.MapLibreMap).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final map = tester.widget<ml.MapLibreMap>(find.byType(ml.MapLibreMap));
      expect(map.initialCameraPosition!.target, const ml.LatLng(22.61, 88.41));
      expect(map.initialCameraPosition!.zoom, 15);
      expect(map.initialCameraPosition!.bearing, -35);
      await tester.pumpWidget(const SizedBox());
      camera.dispose();
      debugDefaultTargetPlatformOverride = null;
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'native map synchronizes gestures, projects pins and restores routes after style reload',
    (tester) async {
      final previousFactory = ml.MapLibrePlatform.createInstance;
      final native = _NativeMap()..pixelRatio = 2;
      ml.MapLibrePlatform.createInstance = () => native;
      PujoMap.nativeMapsEnabled = true;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.devicePixelRatio = 2;
      addTearDown(() {
        ml.MapLibrePlatform.createInstance = previousFactory;
        PujoMap.nativeMapsEnabled = false;
        debugDefaultTargetPlatformOverride = null;
        tester.view.resetDevicePixelRatio();
      });
      final camera = MapController();
      var gestureMoves = 0;
      var taps = 0;
      Widget host({bool dark = false, bool threeD = true}) => MaterialApp(
        home: Scaffold(
          body: PujoMap(
            mapController: camera,
            dark: dark,
            threeDimensional: threeD,
            options: MapOptions(
              initialCenter: const LatLng(22.55, 88.35),
              initialZoom: 15,
              onPositionChanged: (_, gesture) {
                if (gesture) gestureMoves++;
              },
            ),
            children: [
              IgnorePointer(
                child: Builder(
                  builder: (context) =>
                      Text('north: ${PujoMap.visibleBoundsOf(context).north}'),
                ),
              ),
              PujoPolylineLayer(
                polylines: [
                  Polyline(
                    points: const [LatLng(22.55, 88.35), LatLng(22.56, 88.36)],
                    color: Colors.red,
                  ),
                ],
              ),
              PujoMarkerLayer(
                markers: [
                  Marker(
                    point: const LatLng(22.55, 88.35),
                    width: 40,
                    height: 50,
                    alignment: Alignment.topCenter,
                    rotate: true,
                    child: GestureDetector(
                      onTap: () => taps++,
                      child: const ColoredBox(
                        key: ValueKey('pin'),
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.runAsync(() => tester.pumpWidget(host()));
      for (
        var i = 0;
        i < 50 && find.byType(ml.MapLibreMap).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(ml.MapLibreMap), findsOneWidget);
      native.onMapStyleLoadedPlatform.call(null);
      for (
        var i = 0;
        i < 20 && find.byKey(const ValueKey('pin')).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(native.sources, 1);
      expect(native.writes.last['features'], isNotEmpty);
      expect(
        tester.getBottomLeft(find.byKey(const ValueKey('pin'))),
        const Offset(100, 160),
      );
      await tester.tap(find.byKey(const ValueKey('pin')));
      expect(taps, 1);

      // Zoom/pan can project a buffered pin beyond the screen and back. Its
      // native artwork must survive rather than disappear and be recaptured.
      final pinState = tester.state(find.byType(PujoNativeMarker));
      native.projectedX = -1000;
      native.onCameraIdlePlatform.call(null);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(find.byType(PujoNativeMarker), findsOneWidget);
      expect(tester.state(find.byType(PujoNativeMarker)), same(pinState));
      native.projectedX = 120;
      native.onCameraIdlePlatform.call(null);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(tester.state(find.byType(PujoNativeMarker)), same(pinState));

      // A pitched viewport can change without a FlutterMap camera event.
      // Cluster culling must rebuild when the asynchronous native bounds arrive.
      native.region = ml.LatLngBounds(
        southwest: const ml.LatLng(22.3, 88.1),
        northeast: const ml.LatLng(22.9, 88.6),
      );
      native.onCameraIdlePlatform.call(null);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(find.text('north: 22.9'), findsOneWidget);

      camera.moveAndRotate(const LatLng(22.6, 88.4), 16, 30);
      await tester.pump(const Duration(milliseconds: 100));
      final command = native.moves.last[1] as Map;
      expect(command['zoom'], 15);
      expect(command['bearing'], -30);

      final gesture = await tester.startGesture(const Offset(250, 250));
      native.onCameraMovePlatform.call(
        const ml.CameraPosition(
          target: ml.LatLng(22.57, 88.37),
          zoom: 14.5,
          bearing: 70,
          tilt: 45,
        ),
      );
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(camera.camera.center, const LatLng(22.57, 88.37));
      expect(camera.camera.zoom, 15.5);
      expect(camera.camera.rotation, -70);
      expect(gestureMoves, greaterThan(0));

      await tester.pumpWidget(host(dark: true, threeD: false));
      await tester.pump(const Duration(milliseconds: 100));
      native.onMapStyleLoadedPlatform.call(null);
      for (var i = 0; i < 20 && native.writes.length < 2; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(native.sources, 2);
      expect(native.writes.last['features'], isNotEmpty);
      expect(camera.camera.center, const LatLng(22.57, 88.37));
      await tester.pumpWidget(const SizedBox());
      camera.dispose();
      debugDefaultTargetPlatformOverride = null;
      PujoMap.nativeMapsEnabled = false;
      tester.view.resetDevicePixelRatio();
      expect(tester.takeException(), isNull);
    },
  );
}
