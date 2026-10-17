import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/position_interpolator.dart';
import 'pujo_map_layers.dart';

/// Rebuilds only markers per frame. Keys preserve member motion across reorder.
class LiveTrackingMarkerLayer extends StatefulWidget {
  const LiveTrackingMarkerLayer({
    super.key,
    required this.markers,
    this.onPositionFrame,
    this.snapKeys = const {},
  });

  final List<Marker> markers;
  final Set<Key> snapKeys;
  final void Function(Key key, LatLng point)? onPositionFrame;

  @override
  State<LiveTrackingMarkerLayer> createState() =>
      _LiveTrackingMarkerLayerState();
}

class _LiveTrackingMarkerLayerState extends State<LiveTrackingMarkerLayer>
    with TickerProviderStateMixin {
  final Map<Key, PositionInterpolator> _positions = {};
  bool _syncing = false;

  @override
  void didUpdateWidget(LiveTrackingMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    _syncing = true;
    final keys = widget.markers.map((marker) => marker.key!).toSet();
    for (final key
        in _positions.keys.where((key) => !keys.contains(key)).toList()) {
      _positions.remove(key)!.dispose();
    }
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    for (final marker in widget.markers) {
      final key = marker.key!;
      final position = _positions.putIfAbsent(key, () {
        final value = PositionInterpolator(vsync: this);
        value.addListener(() {
          if (!mounted || _syncing) return;
          setState(() {});
          widget.onPositionFrame?.call(key, value.currentInterpolatedPosition!);
        });
        return value;
      });
      if (reduceMotion || widget.snapKeys.contains(key)) {
        position.snapTo(marker.point);
      } else {
        position.updatePosition(marker.point);
      }
    }
    _syncing = false;
    if (widget.onPositionFrame != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final entry in _positions.entries) {
          widget.onPositionFrame?.call(
            entry.key,
            entry.value.currentInterpolatedPosition!,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => PujoMarkerLayer(
    markers: [
      for (final marker in widget.markers)
        Marker(
          key: marker.key,
          point:
              _positions[marker.key]!.currentInterpolatedPosition ??
              marker.point,
          width: marker.width,
          height: marker.height,
          alignment: marker.alignment,
          rotate: marker.rotate,
          child: marker.child,
        ),
    ],
  );

  @override
  void dispose() {
    for (final position in _positions.values) {
      position.dispose();
    }
    super.dispose();
  }
}
