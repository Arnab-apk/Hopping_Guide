import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';

/// Display-only smoothing. Never extrapolates past a received location or feeds
/// animated coordinates back into navigation, visit detection, or cloud writes.
class PositionInterpolator extends ChangeNotifier {
  PositionInterpolator({DateTime Function()? now, TickerProvider? vsync})
    : _now = now ?? DateTime.now {
    _ticker = vsync?.createTicker(_advance);
  }

  final DateTime Function() _now;
  LatLng? _start, _target;
  DateTime? _lastUpdate;
  Timer? _timer;
  Ticker? _ticker;
  Duration _duration = const Duration(milliseconds: 700);
  Duration _elapsed = Duration.zero;
  static const _frame = Duration(milliseconds: 33);

  LatLng? get currentInterpolatedPosition {
    final target = _target;
    final start = _start;
    if (target == null || start == null) return target;
    final t = (_elapsed.inMicroseconds / _duration.inMicroseconds).clamp(
      0.0,
      1.0,
    );
    final longitudeDelta =
        (target.longitude - start.longitude + 180) % 360 - 180;
    if (t >= 1) return target;
    return LatLng(
      start.latitude + (target.latitude - start.latitude) * t,
      (start.longitude + longitudeDelta * t + 180) % 360 - 180,
    );
  }

  void updatePosition(LatLng position) {
    if (!_valid(position) || _target == position) return;
    final now = _now();
    final current = currentInterpolatedPosition;
    final gap = _lastUpdate == null ? null : now.difference(_lastUpdate!);
    _lastUpdate = now;
    // Reconnection and large corrections must not animate a fictional journey.
    if (current == null ||
        (gap != null && gap > const Duration(seconds: 20)) ||
        const Distance().as(LengthUnit.Meter, current, position) > 150) {
      snapTo(position);
      return;
    }
    _start = current;
    _target = position;
    _elapsed = Duration.zero;
    _duration = Duration(
      milliseconds: (gap?.inMilliseconds ?? 700).clamp(250, 1000),
    );
    _timer?.cancel();
    _ticker?.stop();
    if (_ticker != null) {
      _ticker!.start();
    } else {
      // Non-visual consumers retain virtual-time-compatible interpolation.
      _timer = Timer.periodic(_frame, (timer) => _advance(_frame * timer.tick));
    }
    notifyListeners();
  }

  void _advance(Duration elapsed) {
    _elapsed = elapsed;
    if (_elapsed >= _duration) {
      _elapsed = _duration;
      _timer?.cancel();
      _timer = null;
      _ticker?.stop();
      _start = _target;
    }
    notifyListeners();
  }

  void snapTo(LatLng position) {
    if (!_valid(position)) return;
    _timer?.cancel();
    _timer = null;
    _ticker?.stop();
    _start = _target = position;
    _elapsed = _duration;
    _lastUpdate = _now();
    notifyListeners();
  }

  bool _valid(LatLng point) =>
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude.abs() <= 90 &&
      point.longitude.abs() <= 180;

  @override
  void dispose() {
    _timer?.cancel();
    _ticker?.dispose();
    super.dispose();
  }
}
