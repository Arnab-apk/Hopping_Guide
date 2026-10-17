import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import 'pujo_map.dart';
import 'pujo_native_marker.dart';

/// Visible pins are geographic native symbols; Flutter retains their tap
/// targets and semantics, including buttons inside the geographic popups.
class PujoMarkerLayer extends StatefulWidget {
  const PujoMarkerLayer({super.key, required this.markers});
  final List<fm.Marker> markers;
  @override
  State<PujoMarkerLayer> createState() => _PujoMarkerLayerState();
}

class _PujoMarkerLayerState extends State<PujoMarkerLayer> {
  PujoMapBridge? _bridge;
  List<Offset> _points = [];
  List<fm.Marker> _projectedMarkers = [];
  bool _busy = false, _dirty = false, _scheduled = false;
  double _pixelRatio = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bridge = PujoMapScope.maybeOf(context);
    if (!identical(bridge, _bridge)) {
      _bridge?.cameraRevision.removeListener(_onMapChanged);
      _bridge = bridge;
      _bridge?.cameraRevision.addListener(_onMapChanged);
    }
    // Android's batch projection returns physical pixels; iOS/web return
    // logical screen coordinates. Do not divide those platforms by DPR.
    _pixelRatio = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? MediaQuery.devicePixelRatioOf(context)
        : 1;
    _requestProjection();
  }

  void _onMapChanged() => _requestProjection();

  @override
  void didUpdateWidget(PujoMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _requestProjection();
  }

  void _requestProjection() {
    _dirty = true;
    if (_scheduled || _busy || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) unawaited(_project());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _project() async {
    final bridge = _bridge;
    if (bridge?.controller == null || !bridge!.styleReady) return;
    _busy = true;
    _dirty = false;
    try {
      final markers = widget.markers;
      final points = markers.isEmpty
          ? <math.Point>[]
          : await bridge.controller!.toScreenLocationBatch(
              markers.map(
                (marker) =>
                    ml.LatLng(marker.point.latitude, marker.point.longitude),
              ),
            );
      if (!mounted || !identical(bridge, _bridge)) return;
      if (!identical(markers, widget.markers)) {
        _dirty = true;
        return;
      }
      final projected = [
        for (final p in points) Offset(p.x / _pixelRatio, p.y / _pixelRatio),
      ];
      if (identical(markers, _projectedMarkers) &&
          listEquals(projected, _points)) {
        return;
      }
      setState(() {
        _projectedMarkers = markers;
        _points = projected;
      });
    } catch (error) {
      debugPrint('Map marker projection failed: $error');
    } finally {
      _busy = false;
      if (mounted && _dirty) _requestProjection();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bridge == null) {
      return fm.MarkerLayer(markers: widget.markers);
    }
    final occurrences = <LatLng, int>{};
    return Stack(
      children: [
        for (var i = 0; i < _projectedMarkers.length && i < _points.length; i++)
          if (_points[i].dx.isFinite && _points[i].dy.isFinite)
            _positioned(
              _projectedMarkers[i],
              _points[i],
              _projectedMarkers[i].key ??
                  ValueKey((
                    _projectedMarkers[i].point,
                    occurrences.update(
                      _projectedMarkers[i].point,
                      (count) => count + 1,
                      ifAbsent: () => 0,
                    ),
                  )),
            ),
      ],
    );
  }

  Widget _positioned(fm.Marker marker, Offset point, Key key) {
    final alignment = marker.alignment ?? Alignment.center;
    final child = PujoNativeMarker(marker: marker, bridge: _bridge!);
    return Positioned(
      // Keep the native texture attached to its geographic marker when the
      // list is reordered. Do not dispose pins at asynchronous screen bounds:
      // the native renderer already clips them against its current camera.
      key: key,
      width: marker.width,
      height: marker.height,
      left: point.dx - marker.width * (1 - alignment.x) / 2,
      top: point.dy - marker.height * (1 - alignment.y) / 2,
      child: marker.rotate == true
          ? child
          : Transform.rotate(
              angle:
                  -(_bridge?.controller?.cameraPosition?.bearing ?? 0) *
                  math.pi /
                  180,
              alignment: alignment * -1,
              child: child,
            ),
    );
  }

  @override
  void dispose() {
    _bridge?.cameraRevision.removeListener(_onMapChanged);
    super.dispose();
  }
}

class PujoPolylineLayer extends StatelessWidget {
  const PujoPolylineLayer({super.key, required this.polylines});
  final List<fm.Polyline> polylines;
  @override
  Widget build(BuildContext context) {
    if (PujoMapScope.read(context) == null) {
      return fm.PolylineLayer(key: key, polylines: polylines);
    }
    return _NativeFeatures(features: pujoPolylineFeatures(polylines));
  }
}

class PujoCircleLayer extends StatelessWidget {
  const PujoCircleLayer({super.key, required this.circles});
  final List<fm.CircleMarker> circles;
  @override
  Widget build(BuildContext context) {
    if (PujoMapScope.read(context) == null) {
      return fm.CircleLayer(key: key, circles: circles);
    }
    final zoom = circles.every((circle) => circle.useRadiusInMeter)
        ? 0.0
        : fm.MapCamera.of(context).zoom;
    return _NativeFeatures(features: pujoCircleFeatures(circles, zoom));
  }
}

String _hex(Color color) =>
    '#${(color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';

Map<String, dynamic> _feature(
  String type,
  Object coordinates,
  Color color, {
  double width = 0,
  bool dashed = false,
}) => {
  'type': 'Feature',
  'geometry': {'type': type, 'coordinates': coordinates},
  'properties': {
    'color': _hex(color),
    'opacity': color.a,
    'width': width,
    'dashed': dashed,
  },
};

List<Map<String, dynamic>> pujoPolylineFeatures(List<fm.Polyline> lines) => [
  for (final line in lines)
    if (line.points.length > 1) ...[
      if (line.borderStrokeWidth > 0)
        _feature(
          'LineString',
          [
            for (final p in line.points) [p.longitude, p.latitude],
          ],
          line.borderColor,
          width: line.strokeWidth + 2 * line.borderStrokeWidth,
        ),
      _feature(
        'LineString',
        [
          for (final p in line.points) [p.longitude, p.latitude],
        ],
        line.color,
        width: line.strokeWidth,
        dashed:
            line.pattern.segments != null || line.pattern.spacingFactor != null,
      ),
    ],
];

List<Map<String, dynamic>> pujoCircleFeatures(
  List<fm.CircleMarker> circles,
  double zoom,
) => [for (final circle in circles) ..._circleFeatures(circle, zoom)];

List<Map<String, dynamic>> _circleFeatures(
  fm.CircleMarker circle,
  double zoom,
) {
  final radius = circle.useRadiusInMeter
      ? circle.radius
      : circle.radius *
            156543.03392 *
            math.cos(circle.point.latitude * math.pi / 180) /
            math.pow(2, zoom);
  const distance = Distance();
  final ring = [
    for (var i = 0; i < 64; i++)
      distance.offset(circle.point, radius, i * 360 / 64),
  ];
  final coordinates = [
    for (final p in [...ring, ring.first]) [p.longitude, p.latitude],
  ];
  return [
    _feature('Polygon', [coordinates], circle.color),
    if (circle.borderStrokeWidth > 0)
      _feature(
        'LineString',
        coordinates,
        circle.borderColor,
        width: circle.borderStrokeWidth,
      ),
  ];
}

class _NativeFeatures extends StatefulWidget {
  const _NativeFeatures({required this.features});
  final List<Map<String, dynamic>> features;
  @override
  State<_NativeFeatures> createState() => _NativeFeaturesState();
}

class _NativeFeaturesState extends State<_NativeFeatures> {
  PujoMapBridge? _bridge;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bridge = PujoMapScope.read(context);
    if (identical(bridge, _bridge)) return;
    _bridge?.removeFeatures(this);
    _bridge = bridge;
    _bridge?.setFeatures(this, widget.features);
  }

  @override
  void didUpdateWidget(_NativeFeatures oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bridge?.setFeatures(this, widget.features);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
  @override
  void dispose() {
    _bridge?.removeFeatures(this);
    super.dispose();
  }
}
