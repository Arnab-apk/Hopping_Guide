import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../config/app_config.dart';
import '../config/pujo_map_style.dart';

/// Keeps the application's geographic camera API while MapLibre owns rendering
/// and gestures. FlutterMap supplies camera context only on the native path;
/// markers and paths are native geographic layers. Projected Flutter copies
/// retain the markers' existing gestures and accessibility semantics.
class PujoMap extends StatefulWidget {
  const PujoMap({
    super.key,
    this.mapController,
    required this.options,
    required this.children,
    required this.dark,
    this.moreNames = true,
    this.threeDimensional = true,
  });

  final MapController? mapController;
  final MapOptions options;
  final List<Widget> children;
  final bool dark, moreNames, threeDimensional;

  /// Platform-view hosts can disable native maps, e.g. headless widget tests.
  static bool nativeMapsEnabled = true;
  static bool get supported =>
      nativeMapsEnabled &&
      (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static LatLngBounds visibleBoundsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_PujoBoundsScope>()
          ?.notifier
          ?.value ??
      MapCamera.of(context).visibleBounds;

  @override
  State<PujoMap> createState() => _PujoMapState();
}

class _PujoMapState extends State<PujoMap> {
  late final MapController _camera = widget.mapController ?? MapController();
  final _bridge = PujoMapBridge();
  StreamSubscription<MapEvent>? _events;
  Timer? _loadTimeout;
  String? _style;
  int _styleGeneration = 0;
  bool _fallback = false, _gesture = false, _cameraBusy = false;
  ml.CameraPosition? _pendingCamera;
  late double _cameraTilt = widget.threeDimensional ? 45 : 0;
  List<Map<String, dynamic>> _styleLayers = [];
  bool _visibilityBusy = false, _visibilityDirty = false;
  bool _syncingNativeCamera = false;
  static const _nativeEvent = 'pujo-native-camera';

  bool get _native => PujoMap.supported && !_fallback;

  @override
  void initState() {
    super.initState();
    if (_native) _loadStyle();
    _events = _camera.mapEventStream.listen((event) {
      if (!_native || _bridge.controller == null) return;
      if (event is MapEventMove && event.id == _nativeEvent ||
          event is MapEventRotate && event.id == _nativeEvent) {
        return;
      }
      if (event is MapEventMove ||
          event is MapEventRotate ||
          event is MapEventNonRotatedSizeChange) {
        _gesture = false;
        _queueCamera();
      }
    });
  }

  @override
  void didUpdateWidget(PujoMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_native && oldWidget.dark != widget.dark) {
      _loadStyle();
    } else if (_native &&
        (oldWidget.moreNames != widget.moreNames ||
            oldWidget.threeDimensional != widget.threeDimensional)) {
      unawaited(_updateVisibility());
    }
    if (_native && oldWidget.threeDimensional != widget.threeDimensional) {
      _gesture = false;
      _queueCamera(tilt: widget.threeDimensional ? 45 : 0);
    }
  }

  Future<void> _loadStyle() async {
    final generation = ++_styleGeneration;
    _bridge.beginStyleLoad();
    try {
      final style = await PujoMapStyle.load(
        dark: widget.dark,
        moreNames: widget.moreNames,
        threeDimensional: widget.threeDimensional,
      );
      if (!mounted || generation != _styleGeneration) return;
      _styleLayers = ((jsonDecode(style) as Map)['layers'] as List)
          .cast<Map<String, dynamic>>();
      setState(() => _style = style);
      _loadTimeout?.cancel();
      _loadTimeout = Timer(const Duration(seconds: 25), _useFallback);
    } catch (error) {
      if (!mounted || generation != _styleGeneration) return;
      debugPrint('Vector map style could not load: $error');
      _useFallback();
    }
  }

  // Toggling buildings or POIs must not replace the basemap and discard all
  // native textures, routes and tile state. Serialize rapid settings changes.
  Future<void> _updateVisibility() async {
    _visibilityDirty = true;
    if (_visibilityBusy || !_bridge.styleReady) return;
    _visibilityBusy = true;
    try {
      while (mounted && _native && _bridge.styleReady && _visibilityDirty) {
        _visibilityDirty = false;
        final generation = _styleGeneration;
        final native = _bridge.controller!;
        final threeD = widget.threeDimensional;
        final names = widget.moreNames;
        for (final layer in _styleLayers) {
          final bool visible;
          if (layer['type'] == 'fill-extrusion') {
            visible = threeD;
          } else if (layer['type'] == 'symbol' &&
              layer['source-layer'] == 'poi') {
            visible = names;
          } else {
            continue;
          }
          if (!mounted ||
              generation != _styleGeneration ||
              !identical(native, _bridge.controller)) {
            return;
          }
          await native.setLayerVisibility(layer['id'] as String, visible);
        }
      }
    } catch (error) {
      debugPrint('Map visibility update failed: $error');
    } finally {
      _visibilityBusy = false;
    }
  }

  void _useFallback() {
    if (!mounted || _fallback) return;
    _loadTimeout?.cancel();
    _bridge.styleReady = false;
    _bridge.controller = null;
    setState(() => _fallback = true);
  }

  void _queueCamera({double? tilt}) {
    if (tilt != null) _cameraTilt = tilt;
    final camera = _camera.camera;
    _pendingCamera = ml.CameraPosition(
      target: ml.LatLng(camera.center.latitude, camera.center.longitude),
      // MapLibre uses a 512px world tile; FlutterMap's camera uses 256px.
      zoom: camera.zoom - 1,
      bearing: -camera.rotation,
      tilt: _cameraTilt,
    );
    unawaited(_flushCamera());
  }

  Future<void> _flushCamera() async {
    if (_cameraBusy || _bridge.controller == null) return;
    _cameraBusy = true;
    try {
      while (mounted && _native && _pendingCamera != null) {
        final next = _pendingCamera!;
        _pendingCamera = null;
        await _bridge.controller?.moveCamera(
          ml.CameraUpdate.newCameraPosition(next),
        );
      }
    } catch (error) {
      debugPrint('Map camera update failed: $error');
    } finally {
      _cameraBusy = false;
    }
  }

  void _onCameraMove(ml.CameraPosition position) {
    if (!mounted || !_native) return;
    if (_gesture) {
      _cameraTilt = widget.threeDimensional ? position.tilt : 0;
      _syncingNativeCamera = true;
      try {
        _camera.moveAndRotate(
          LatLng(position.target.latitude, position.target.longitude),
          position.zoom + 1,
          -position.bearing,
          id: _nativeEvent,
        );
      } finally {
        _syncingNativeCamera = false;
      }
      widget.options.onPositionChanged?.call(_camera.camera, true);
    }
    _bridge.cameraChanged();
  }

  ml.CameraTargetBounds get _targetBounds {
    final constraint = widget.options.cameraConstraint;
    if (constraint is! ContainCameraCenter) {
      return ml.CameraTargetBounds.unbounded;
    }
    final b = constraint.bounds;
    return ml.CameraTargetBounds(
      ml.LatLngBounds(
        southwest: ml.LatLng(b.south, b.west),
        northeast: ml.LatLng(b.north, b.east),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final original = widget.options;
    final options = !_native
        ? original
        : MapOptions(
            initialCenter: original.initialCenter,
            initialZoom: original.initialZoom,
            initialRotation: original.initialRotation,
            initialCameraFit: original.initialCameraFit,
            minZoom: original.minZoom,
            maxZoom: original.maxZoom,
            cameraConstraint: original.cameraConstraint,
            backgroundColor: widget.dark
                ? const Color(0xFF101318)
                : const Color(0xFFF3F0E8),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
            onPositionChanged: (camera, hasGesture) {
              if (!_syncingNativeCamera) {
                original.onPositionChanged?.call(camera, hasGesture);
              }
            },
            onMapEvent: original.onMapEvent,
            onMapReady: original.onMapReady,
            keepAlive: original.keepAlive,
          );
    return FlutterMap(
      mapController: _camera,
      options: options,
      children: [
        if (_native)
          PujoMapScope(
            notifier: _bridge,
            child: _PujoBoundsScope(
              notifier: _bridge.bounds,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_style != null)
                    Builder(
                      builder: (context) => Listener(
                        onPointerDown: (_) {
                          _gesture = true;
                          _pendingCamera = null;
                        },
                        onPointerMove: (_) {
                          _gesture = true;
                          _pendingCamera = null;
                        },
                        child: ml.MapLibreMap(
                          styleString: _style!,
                          initialCameraPosition: ml.CameraPosition(
                            target: ml.LatLng(
                              _camera.camera.center.latitude,
                              _camera.camera.center.longitude,
                            ),
                            zoom: _camera.camera.zoom - 1,
                            bearing: -_camera.camera.rotation,
                            tilt: _cameraTilt,
                          ),
                          trackCameraPosition: true,
                          annotationOrder: const [],
                          compassEnabled: false,
                          cameraTargetBounds: _targetBounds,
                          minMaxZoomPreference: ml.MinMaxZoomPreference(
                            original.minZoom == null
                                ? null
                                : original.minZoom! - 1,
                            original.maxZoom == null
                                ? null
                                : original.maxZoom! - 1,
                          ),
                          tiltGesturesEnabled: widget.threeDimensional,
                          gestureRecognizers: {
                            Factory<OneSequenceGestureRecognizer>(
                              () => EagerGestureRecognizer(),
                            ),
                          },
                          attributionButtonPosition:
                              ml.AttributionButtonPosition.bottomLeft,
                          attributionButtonMargins: const math.Point(8, 8),
                          onMapCreated: (controller) {
                            _bridge.controller = controller;
                            _queueCamera();
                          },
                          onStyleLoadedCallback: () {
                            _loadTimeout?.cancel();
                            unawaited(
                              _bridge.styleLoaded().then((_) async {
                                if (mounted) {
                                  await _updateVisibility();
                                  if (!mounted || !_native) return;
                                  _queueCamera(tilt: _cameraTilt);
                                }
                              }),
                            );
                          },
                          onCameraMove: _onCameraMove,
                          onCameraIdle: () {
                            _bridge.cameraChanged();
                          },
                          onMapClick: (point, coordinate) {
                            final local = Offset(
                              point.x.toDouble(),
                              point.y.toDouble(),
                            );
                            original.onTap?.call(
                              TapPosition(local, local),
                              LatLng(coordinate.latitude, coordinate.longitude),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                  ...widget.children,
                ],
              ),
            ),
          )
        else ...[
          TileLayer(
            key: ValueKey('osm_names_${widget.moreNames}'),
            urlTemplate: AppConfig.tileUrlTemplate,
            retinaMode: widget.moreNames,
            maxNativeZoom: 19,
            subdomains: AppConfig.osmSubdomains,
            userAgentPackageName: 'com.kolkatapuja.kolkata_puja',
            keepBuffer: widget.moreNames ? 2 : 3,
            panBuffer: widget.moreNames ? 1 : 2,
            tileDisplay: const TileDisplay.fadeIn(
              duration: Duration(milliseconds: 140),
            ),
            tileBuilder: (context, tile, _) => widget.dark
                ? ColorFiltered(colorFilter: _darkTiles, child: tile)
                : tile,
          ),
          ...widget.children,
          const RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
          if (_fallback)
            Positioned(
              left: 8,
              bottom: 28,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry 3D map'),
                onPressed: () {
                  setState(() => _fallback = false);
                  _loadStyle();
                },
              ),
            ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    _events?.cancel();
    _bridge.dispose();
    if (widget.mapController == null) _camera.dispose();
    super.dispose();
  }
}

const _darkTiles = ColorFilter.matrix([
  -0.85,
  0,
  0,
  0,
  255,
  0,
  -0.85,
  0,
  0,
  255,
  0,
  0,
  -0.85,
  0,
  255,
  0,
  0,
  0,
  1,
  0,
]);

class PujoMapScope extends InheritedWidget {
  const PujoMapScope({super.key, required this.notifier, required super.child});

  final PujoMapBridge notifier;

  static PujoMapBridge? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PujoMapScope>()?.notifier;

  static PujoMapBridge? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PujoMapScope>()?.notifier;

  @override
  bool updateShouldNotify(PujoMapScope oldWidget) =>
      !identical(notifier, oldWidget.notifier);
}

/// Only viewport consumers rebuild when native bounds arrive. Marker projection
/// listens to the camera separately, without rebuilding the whole map per frame.
class _PujoBoundsScope extends InheritedNotifier<ValueNotifier<LatLngBounds?>> {
  const _PujoBoundsScope({required super.notifier, required super.child});
}

/// Shared native projection and a serialized overlay writer. Style reloads
/// recreate the source and layers, including any route already on screen.
class PujoMapBridge extends ChangeNotifier {
  ml.MapLibreMapController? controller;
  final bounds = ValueNotifier<LatLngBounds?>(null);
  // Camera motion and artwork uploads have different consumers. Uploading an
  // avatar must not reproject every marker through the platform channel.
  final cameraRevision = ValueNotifier<int>(0);
  LatLngBounds? get visibleBounds => bounds.value;
  bool styleReady = false, _disposed = false, _boundsBusy = false;
  bool _writing = false, _dirty = false, _scheduled = false;
  bool _boundsScheduled = false;
  bool _boundsDirty = false;
  bool _cameraScheduled = false;
  Timer? _boundsThrottle;
  int _styleEpoch = 0;
  final _features = <Object, List<Map<String, dynamic>>>{};
  final _markerImages = <String, Uint8List>{};
  final _markerImageOwners = <Object, String>{};
  final _uploadedImages = <String, Uint8List>{};
  final _freeImageIds = <Size, List<String>>{};
  final _imageSizes = <String, Size>{};
  int _nextImageId = 0;
  String? _writtenFeatures;

  bool markerImageReady(String id) =>
      styleReady && _uploadedImages.containsKey(id);

  // Reuse texture slots as clusters/pins leave the viewport. The SDK does not
  // expose image removal. Reuse only matching dimensions, since changing an
  // existing atlas slot's size can clip the replacement icon on Android.
  String markerImageId(Object owner, {required Size size}) {
    final previous = _markerImageOwners[owner];
    if (previous != null && _imageSizes[previous] == size) return previous;
    if (previous != null) removeFeatures(owner);
    final free = _freeImageIds.putIfAbsent(size, () => []);
    final id = free.isNotEmpty
        ? free.removeLast()
        : 'uma-pin-${_nextImageId++}';
    _markerImageOwners[owner] = id;
    _imageSizes[id] = size;
    return id;
  }

  void setMarkerImage(Object owner, String id, Uint8List bytes) {
    if (_disposed) return;
    _markerImageOwners[owner] = id;
    _markerImages[id] = bytes;
    _scheduleWrite();
  }

  void cameraChanged() {
    if (_disposed) return;
    // Native events can arrive more often than Flutter can draw. Only hit
    // targets need projection; visible pins already move in the native renderer.
    if (!_cameraScheduled) {
      _cameraScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cameraScheduled = false;
        if (!_disposed) cameraRevision.value++;
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }
    if (_boundsScheduled) return;
    _boundsScheduled = true;
    _boundsThrottle?.cancel();
    _boundsThrottle = Timer(const Duration(milliseconds: 100), () {
      _boundsScheduled = false;
      unawaited(_updateBounds());
    });
  }

  void beginStyleLoad() {
    if (_disposed) return;
    ++_styleEpoch;
    styleReady = false;
  }

  Future<void> _updateBounds() async {
    if (controller == null || _disposed) return;
    _boundsDirty = true;
    if (_boundsBusy) return;
    _boundsBusy = true;
    try {
      while (_boundsDirty && controller != null && !_disposed) {
        _boundsDirty = false;
        final native = controller!;
        final region = await native.getVisibleRegion();
        if (_disposed || !identical(native, controller)) return;
        if (_boundsDirty) continue;
        final next = LatLngBounds(
          LatLng(region.southwest.latitude, region.southwest.longitude),
          LatLng(region.northeast.latitude, region.northeast.longitude),
        );
        final previous = bounds.value;
        if (previous == null ||
            previous.southWest != next.southWest ||
            previous.northEast != next.northEast) {
          bounds.value = next;
        }
      }
    } catch (_) {
      /* A camera can disappear while a platform request is pending. */
    } finally {
      _boundsBusy = false;
    }
  }

  Future<void> styleLoaded() async {
    final native = controller;
    if (native == null || _disposed) return;
    final epoch = ++_styleEpoch;
    styleReady = false;
    _uploadedImages.clear();
    _writtenFeatures = null;
    try {
      await native.addGeoJsonSource('uma-overlays', {
        'type': 'FeatureCollection',
        'features': [],
      });
      await native.addFillLayer(
        'uma-overlays',
        'uma-area-fill',
        const ml.FillLayerProperties(
          fillColor: ['get', 'color'],
          fillOpacity: ['get', 'opacity'],
        ),
        filter: [
          '==',
          ['geometry-type'],
          'Polygon',
        ],
        enableInteraction: false,
      );
      await native.addLineLayer(
        'uma-overlays',
        'uma-solid-lines',
        const ml.LineLayerProperties(
          lineColor: ['get', 'color'],
          lineOpacity: ['get', 'opacity'],
          lineWidth: ['get', 'width'],
          lineJoin: 'round',
          lineCap: 'round',
        ),
        filter: [
          'all',
          [
            '==',
            ['geometry-type'],
            'LineString',
          ],
          [
            '==',
            ['get', 'dashed'],
            false,
          ],
        ],
        enableInteraction: false,
      );
      await native.addSymbolLayer(
        'uma-overlays',
        'uma-pinned-markers',
        const ml.SymbolLayerProperties(
          iconImage: ['get', 'image'],
          iconSize: ['get', 'scale'],
          iconOffset: ['get', 'offset'],
          iconAnchor: 'center',
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          iconRotationAlignment: 'viewport',
          iconPitchAlignment: 'viewport',
        ),
        filter: [
          'all',
          [
            '==',
            ['geometry-type'],
            'Point',
          ],
          [
            '!=',
            ['get', 'mapAligned'],
            true,
          ],
        ],
        enableInteraction: false,
      );
      // Match FlutterMap's rotate contract for the invisible tap target too.
      // Let native rendering rotate map-aligned pins without a texture upload.
      await native.addSymbolLayer(
        'uma-overlays',
        'uma-map-aligned-markers',
        const ml.SymbolLayerProperties(
          iconImage: ['get', 'image'],
          iconSize: ['get', 'scale'],
          iconOffset: ['get', 'offset'],
          iconAnchor: 'center',
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          iconRotationAlignment: 'map',
          iconPitchAlignment: 'viewport',
        ),
        filter: [
          'all',
          [
            '==',
            ['geometry-type'],
            'Point',
          ],
          [
            '==',
            ['get', 'mapAligned'],
            true,
          ],
        ],
        enableInteraction: false,
      );
      await native.addLineLayer(
        'uma-overlays',
        'uma-dashed-lines',
        const ml.LineLayerProperties(
          lineColor: ['get', 'color'],
          lineOpacity: ['get', 'opacity'],
          lineWidth: ['get', 'width'],
          lineDasharray: [1.7, 1],
          lineJoin: 'round',
          lineCap: 'round',
        ),
        belowLayerId: 'uma-pinned-markers',
        filter: [
          'all',
          [
            '==',
            ['geometry-type'],
            'LineString',
          ],
          [
            '==',
            ['get', 'dashed'],
            true,
          ],
        ],
        enableInteraction: false,
      );
      if (_disposed || epoch != _styleEpoch || !identical(native, controller)) {
        return;
      }
      styleReady = true;
      cameraChanged();
      _scheduleWrite();
    } catch (error) {
      debugPrint('Map overlay initialization failed: $error');
    }
  }

  void setFeatures(Object owner, List<Map<String, dynamic>> features) {
    if (_disposed) return;
    _features[owner] = features;
    _scheduleWrite();
  }

  void removeFeatures(Object owner) {
    if (_disposed) return;
    _features.remove(owner);
    final image = _markerImageOwners.remove(owner);
    if (image != null) {
      _markerImages.remove(image);
      _uploadedImages.remove(image);
      _freeImageIds.putIfAbsent(_imageSizes[image]!, () => []).add(image);
    }
    _scheduleWrite();
  }

  void _scheduleWrite() {
    _dirty = true;
    if (_scheduled || _disposed || !styleReady) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      unawaited(_write());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _write() async {
    if (_writing || !styleReady || _disposed) return;
    _writing = true;
    try {
      while (_dirty && styleReady && !_disposed) {
        _dirty = false;
        final native = controller!;
        final epoch = _styleEpoch;
        // Capture geometry together with its image set. Features added while
        // an upload is pending belong to the next pass, once their images exist.
        final features = _features.values
            .expand((features) => features)
            .toList();
        final signature = jsonEncode(features);
        for (final entry in _markerImages.entries.toList()) {
          if (identical(_uploadedImages[entry.key], entry.value)) continue;
          await native.addImage(entry.key, entry.value);
          if (_disposed ||
              epoch != _styleEpoch ||
              !identical(native, controller)) {
            return;
          }
          _uploadedImages[entry.key] = entry.value;
        }
        if (signature != _writtenFeatures) {
          await native.setGeoJsonSource('uma-overlays', {
            'type': 'FeatureCollection',
            'features': features,
          });
        }
        if (_disposed ||
            epoch != _styleEpoch ||
            !identical(native, controller)) {
          return;
        }
        _writtenFeatures = signature;
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Map overlay update failed: $error');
    } finally {
      _writing = false;
      if (_dirty && styleReady && !_disposed) _scheduleWrite();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_styleEpoch;
    _boundsThrottle?.cancel();
    bounds.dispose();
    cameraRevision.dispose();
    super.dispose();
  }
}
