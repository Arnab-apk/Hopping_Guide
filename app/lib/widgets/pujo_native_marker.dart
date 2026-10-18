import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';

import 'pujo_map.dart';

/// The native map draws the visible pin from its geographic point on every
/// renderer frame. This Flutter copy supplies its existing gestures/semantics
/// and provides updated artwork when an avatar, count or selection changes.
class PujoNativeMarker extends StatefulWidget {
  const PujoNativeMarker({
    super.key,
    required this.marker,
    required this.bridge,
    this.refreshArtwork = false,
  });

  final Marker marker;
  final PujoMapBridge bridge;

  /// Opt in for artwork animated inside nested repaint boundaries (live heads,
  /// avatars and selection pulses). Stable keys alone do not imply animation.
  final bool refreshArtwork;

  @override
  State<PujoNativeMarker> createState() => _PujoNativeMarkerState();
}

class _PujoNativeMarkerState extends State<PujoNativeMarker> {
  static const _artworkPadding = 12.0;
  String get _imageId => widget.bridge.markerImageId(
    this,
    size: Size(
      widget.marker.width + 2 * _artworkPadding,
      widget.marker.height + 2 * _artworkPadding,
    ),
  );
  final _boundaryKey = GlobalKey();
  Uint8List? _bytes;
  bool _capturePending = false, _capturing = false, _dirty = false;
  bool _nativeReady = false;
  bool _artworkEnabled = true;
  double _imageDensity = 1;
  Timer? _captureThrottle;

  @override
  void initState() {
    super.initState();
    widget.bridge.addListener(_mapChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wasEnabled = _artworkEnabled;
    _artworkEnabled = TickerMode.valuesOf(context).enabled;
    _imageDensity = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? MediaQuery.devicePixelRatioOf(context)
        : 1;
    _publishPoint();
    if (_artworkEnabled && !wasEnabled) _onPaint();
  }

  @override
  void didUpdateWidget(PujoNativeMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bridge, widget.bridge)) {
      oldWidget.bridge.removeListener(_mapChanged);
      oldWidget.bridge.removeFeatures(this);
      widget.bridge.addListener(_mapChanged);
      if (_bytes != null) widget.bridge.setMarkerImage(this, _imageId, _bytes!);
      _nativeReady = false;
    }
    if (oldWidget.marker.point != widget.marker.point ||
        oldWidget.marker.rotate != widget.marker.rotate ||
        oldWidget.marker.alignment != widget.marker.alignment ||
        oldWidget.marker.width != widget.marker.width ||
        oldWidget.marker.height != widget.marker.height ||
        !identical(oldWidget.bridge, widget.bridge)) {
      _publishPoint();
    }
    if (oldWidget.marker.width != widget.marker.width ||
        oldWidget.marker.height != widget.marker.height) {
      _nativeReady = false;
    }
    if (!identical(oldWidget.marker.child, widget.marker.child) ||
        oldWidget.marker.width != widget.marker.width ||
        oldWidget.marker.height != widget.marker.height) {
      _onPaint();
    }
  }

  void _mapChanged() {
    if (!mounted) return;
    final ready = _bytes != null && widget.bridge.markerImageReady(_imageId);
    if (ready != _nativeReady) setState(() => _nativeReady = ready);
  }

  void _publishPoint() {
    if (_bytes == null) return;
    final marker = widget.marker;
    final alignment = marker.alignment ?? Alignment.center;
    widget.bridge.setFeatures(this, [
      {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [marker.point.longitude, marker.point.latitude],
        },
        'properties': {
          'image': _imageId,
          'mapAligned': marker.rotate != true,
          // Android's bitmap registration inherits screen density. Compensate
          // for it as well as the fixed 2x capture resolution.
          'scale': _imageDensity / 2,
          'offset': [
            marker.width * alignment.x / _imageDensity,
            marker.height * alignment.y / _imageDensity,
          ],
        },
      },
    ]);
  }

  void _onPaint() {
    _dirty = true;
    if (!_artworkEnabled || _capturePending || _capturing || !mounted) return;
    _capturePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _capturePending = false;
      if (mounted) unawaited(_capture());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _capture() async {
    if (_capturing || !mounted || !_artworkEnabled || !_dirty) return;
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null || boundary.debugNeedsPaint || !boundary.hasSize) {
      return;
    }
    _capturing = true;
    _dirty = false;
    final captureId = _imageId;
    final captureBridge = widget.bridge;
    ui.Image? image;
    try {
      image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted || data == null) return;
      if (!identical(captureBridge, widget.bridge) || captureId != _imageId) {
        _dirty = true;
        return;
      }
      final bytes = data.buffer.asUint8List();
      if (listEquals(_bytes, bytes)) return;
      _bytes = bytes;
      widget.bridge.setMarkerImage(this, captureId, _bytes!);
      _publishPoint();
    } catch (error) {
      debugPrint('Native marker artwork failed: $error');
    } finally {
      image?.dispose();
      // Animated avatars and selection effects can repaint continuously. Limit
      // texture uploads independently from native camera rendering (no lag).
      if (mounted) {
        _captureThrottle = Timer(const Duration(milliseconds: 80), () {
          _capturing = false;
          // Live location/member markers contain their own repaint boundaries.
          // Refresh their artwork too, so nested compass/avatar updates are
          // reflected even when this outer boundary did not repaint.
          if (mounted && (_dirty || widget.refreshArtwork)) _onPaint();
        });
      } else {
        _capturing = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) => Opacity(
    // Keep the Flutter tree painted for new snapshots and hit testing; its
    // visible artwork is drawn by MapLibre once the texture is registered.
    opacity: _nativeReady ? 0.001 : 1,
    alwaysIncludeSemantics: true,
    child: OverflowBox(
      minWidth: widget.marker.width + 2 * _artworkPadding,
      maxWidth: widget.marker.width + 2 * _artworkPadding,
      minHeight: widget.marker.height + 2 * _artworkPadding,
      maxHeight: widget.marker.height + 2 * _artworkPadding,
      child: _MarkerArtworkBoundary(
        key: _boundaryKey,
        onPaint: _onPaint,
        child: Padding(
          padding: const EdgeInsets.all(_artworkPadding),
          child: SizedBox(
            width: widget.marker.width,
            height: widget.marker.height,
            child: widget.marker.child,
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _captureThrottle?.cancel();
    widget.bridge.removeListener(_mapChanged);
    widget.bridge.removeFeatures(this);
    super.dispose();
  }
}

class _MarkerArtworkBoundary extends SingleChildRenderObjectWidget {
  const _MarkerArtworkBoundary({
    super.key,
    required this.onPaint,
    required super.child,
  });
  final VoidCallback onPaint;

  @override
  RenderRepaintBoundary createRenderObject(BuildContext context) =>
      _ArtworkBoundary(onPaint);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _ArtworkBoundary renderObject,
  ) {
    renderObject.onPaint = onPaint;
  }
}

class _ArtworkBoundary extends RenderRepaintBoundary {
  _ArtworkBoundary(this.onPaint);
  VoidCallback onPaint;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    onPaint();
  }
}
