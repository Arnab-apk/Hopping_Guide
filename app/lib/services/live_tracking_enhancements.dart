import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/pandal.dart';
import '../services/location_service.dart';
import '../services/routing_service.dart';
import '../services/squad_service.dart';
import '../utils/haversine.dart';

/// Real-time walking metrics computed from live GPS stream
class LiveWalkingMetrics {
  const LiveWalkingMetrics({
    required this.currentSpeedMps,
    required this.averageSpeedMps,
    required this.paceMinPerKm,
    required this.distanceTraveledMeters,
    required this.etaToDestination,
    required this.isMoving,
    required this.bearingToDestination,
    required this.deviationMeters,
    required this.isOnRoute,
  });

  final double currentSpeedMps;        // Current instantaneous speed (m/s)
  final double averageSpeedMps;        // Average speed since route start (m/s)
  final double paceMinPerKm;           // Current pace (min/km)
  final double distanceTraveledMeters; // Total distance walked along route
  final Duration? etaToDestination;    // Estimated time to destination
  final bool isMoving;                 // Speed > 0.5 m/s
  final double? bearingToDestination;  // Bearing to next waypoint (degrees)
  final double deviationMeters;        // Perpendicular distance from route polyline
  final bool isOnRoute;                // Within 25m of route

  String get formattedPace {
    if (paceMinPerKm <= 0 || paceMinPerKm.isInfinite) return '--:--';
    final mins = paceMinPerKm.floor();
    final secs = ((paceMinPerKm - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')} min/km';
  }

  String get formattedSpeed {
    final kmh = currentSpeedMps * 3.6;
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  String get formattedEta {
    if (etaToDestination == null) return '--';
    final mins = etaToDestination!.inMinutes;
    if (mins < 1) return '< 1 min';
    if (mins < 60) return '$mins min';
    final hrs = mins ~/ 60;
    final rem = mins % 60;
    return rem == 0 ? '${hrs}h' : '${hrs}h ${rem}m';
  }

  String get formattedDistance {
    if (distanceTraveledMeters < 1000) {
      return '${distanceTraveledMeters.round()} m';
    } else {
      return '${(distanceTraveledMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  static LiveWalkingMetrics stationary() => LiveWalkingMetrics(
        currentSpeedMps: 0,
        averageSpeedMps: 0,
        paceMinPerKm: 0,
        distanceTraveledMeters: 0,
        etaToDestination: null,
        isMoving: false,
        bearingToDestination: null,
        deviationMeters: 0,
        isOnRoute: true,
      );
}

/// Enhanced live tracking engine with real-time metrics, deviation detection,
/// and crowd-sourced density sharing.
class LiveTrackingEngine extends ChangeNotifier {
  static final LiveTrackingEngine instance = LiveTrackingEngine._();

  LiveTrackingEngine._();

  // Dependencies
  final LocationService _location = LocationService.instance;
  final RoutingService _routing = RoutingService.instance;
  final SquadService _squad = SquadService.instance;

  // State
  WalkingRoute? _activeRoute;
  LatLng? _destination;
  String? _destinationName;
  Pandal? _targetPandal;

  // Live metrics computation
  final List<Position> _recentPositions = [];
  static const int _maxPositionHistory = 30; // ~45 seconds at 1.5s interval
  Timer? _metricsTimer;
  LiveWalkingMetrics _currentMetrics = LiveWalkingMetrics.stationary();
  LiveWalkingMetrics get currentMetrics => _currentMetrics;

  // Route deviation
  static const double _deviationThresholdMeters = 25.0;
  Timer? _deviationCheckTimer;
  int _consecutiveDeviations = 0;
  static const int _maxDeviationsBeforeRecalc = 3;

  // Arrival detection
  static const double _arrivalThresholdMeters = 30.0;
  bool _arrivalAnnounced = false;

  // Crowd density sharing (peer-to-peer via squad)
  final Map<String, CrowdDensityReport> _crowdReports = {};
  static const Duration _crowdReportTtl = Duration(minutes: 10);

  // Pace smoothing
  static const double _alpha = 0.3; // EMA smoothing factor
  double _emaSpeed = 0;

  // Callbacks
  void Function(LiveWalkingMetrics)? onMetricsUpdate;
  void Function(LiveWalkingMetrics)? onEtaUpdate;
  void Function(RouteDeviationAlert)? onDeviationAlert;
  void Function(ArrivalAlert)? onArrivalAlert;
  void Function(CrowdDensityReport)? onCrowdDensityUpdate;

  /// Start live tracking for a destination
  Future<void> startTracking({
    required LatLng destination,
    required String destinationName,
    Pandal? targetPandal,
    WalkingRoute? precomputedRoute,
  }) async {
    _destination = destination;
    _destinationName = destinationName;
    _targetPandal = targetPandal;
    _arrivalAnnounced = false;
    _consecutiveDeviations = 0;
    _recentPositions.clear();
    _emaSpeed = 0;

    if (precomputedRoute != null) {
      _activeRoute = precomputedRoute;
    } else {
      final pos = _location.currentPositionSync;
      if (pos != null) {
        _activeRoute = await _routing.getWalkingRouteToPoint(
          start: LatLng(pos.latitude, pos.longitude),
          destination: destination,
          destinationName: destinationName,
          targetPandal: targetPandal,
        );
      }
    }

    _startMetricsComputation();
    _startDeviationMonitoring();
    _startCrowdDensitySharing();

    // Listen to location updates
    _location.addListener(_onLocationUpdate);
  }

  void _onLocationUpdate() {
    final pos = _location.currentPositionSync;
    if (pos != null) {
      _addPosition(pos);
      _checkArrival(pos);
    }
  }

  void _addPosition(Position pos) {
    _recentPositions.add(pos);
    if (_recentPositions.length > _maxPositionHistory) {
      _recentPositions.removeAt(0);
    }
  }

  void _startMetricsComputation() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _recomputeMetrics();
    });
  }

  void _recomputeMetrics() {
    if (_recentPositions.length < 2 || _activeRoute == null || _destination == null) {
      _updateMetrics(LiveWalkingMetrics.stationary());
      return;
    }

    final pos = _recentPositions.last;
    final prevPos = _recentPositions[_recentPositions.length - 2];

    // Current speed from last two positions
    final dt = pos.timestamp.difference(prevPos.timestamp).inMilliseconds / 1000.0;
    final dist = Geolocator.distanceBetween(
      prevPos.latitude, prevPos.longitude,
      pos.latitude, pos.longitude,
    );
    final currentSpeed = dt > 0 ? dist / dt : 0.0;

    // EMA smoothing for stable pace display
    _emaSpeed = _alpha * currentSpeed + (1 - _alpha) * _emaSpeed;

    // Average speed since route start (distance along route / elapsed time)
    final routeStartTime = _recentPositions.first.timestamp;
    final elapsedSeconds = pos.timestamp.difference(routeStartTime).inSeconds;
    final distanceAlongRoute = _computeDistanceAlongRoute(pos);
    final avgSpeed = elapsedSeconds > 0 ? distanceAlongRoute / elapsedSeconds : 0.0;

    // Pace (min/km)
    final pace = _emaSpeed > 0.1 ? (1000.0 / _emaSpeed) / 60.0 : 0.0;

    // ETA to destination
    final remainingMeters = _computeRemainingDistance(pos);
    Duration? eta;
    if (_emaSpeed > 0.1 && remainingMeters > 0) {
      final etaSeconds = (remainingMeters / _emaSpeed).round();
      eta = Duration(seconds: etaSeconds);
    }

    // Bearing to next waypoint
    double? bearing;
    final nextWaypoint = _findNextWaypoint(pos);
    if (nextWaypoint != null) {
      bearing = Geolocator.bearingBetween(
        pos.latitude, pos.longitude,
        nextWaypoint.latitude, nextWaypoint.longitude,
      );
    }

    // Deviation from route
    final deviation = _computeDeviationFromRoute(pos);
    final isOnRoute = deviation <= _deviationThresholdMeters;

    _updateMetrics(LiveWalkingMetrics(
      currentSpeedMps: currentSpeed,
      averageSpeedMps: avgSpeed,
      paceMinPerKm: pace,
      distanceTraveledMeters: distanceAlongRoute,
      etaToDestination: eta,
      isMoving: currentSpeed > 0.5,
      bearingToDestination: bearing,
      deviationMeters: deviation,
      isOnRoute: isOnRoute,
    ));
  }

  double _computeDistanceAlongRoute(Position pos) {
    if (_activeRoute == null || _activeRoute!.points.length < 2) return 0;

    // Find closest point on route polyline
    double minDist = double.infinity;
    int closestSegment = 0;

    for (int i = 0; i < _activeRoute!.points.length - 1; i++) {
      final d = _distancePointToSegment(
        LatLng(pos.latitude, pos.longitude),
        _activeRoute!.points[i],
        _activeRoute!.points[i + 1],
      );
      if (d < minDist) {
        minDist = d;
        closestSegment = i;
      }
    }

    // Sum segment lengths up to closest segment + projection
    double total = 0;
    for (int i = 0; i < closestSegment; i++) {
      total += haversineMeters(
        _activeRoute!.points[i].latitude, _activeRoute!.points[i].longitude,
        _activeRoute!.points[i + 1].latitude, _activeRoute!.points[i + 1].longitude,
      );
    }
    // Add projection on closest segment
    final proj = _projectPointOnSegment(
      LatLng(pos.latitude, pos.longitude),
      _activeRoute!.points[closestSegment],
      _activeRoute!.points[closestSegment + 1],
    );
    total += haversineMeters(
      _activeRoute!.points[closestSegment].latitude, _activeRoute!.points[closestSegment].longitude,
      proj.latitude, proj.longitude,
    );
    return total;
  }

  double _computeRemainingDistance(Position pos) {
    if (_activeRoute == null) return 0;
    final traveled = _computeDistanceAlongRoute(pos);
    return math.max(0, _activeRoute!.distanceMeters - traveled);
  }

  LatLng? _findNextWaypoint(Position pos) {
    if (_activeRoute == null || _activeRoute!.points.isEmpty) return null;
    double minDist = double.infinity;
    LatLng? closest;
    for (final pt in _activeRoute!.points) {
      final d = haversineMeters(pos.latitude, pos.longitude, pt.latitude, pt.longitude);
      if (d < minDist) {
        minDist = d;
        closest = pt;
      }
    }
    // Return the next point after closest
    if (closest != null) {
      final idx = _activeRoute!.points.indexOf(closest);
      if (idx + 1 < _activeRoute!.points.length) {
        return _activeRoute!.points[idx + 1];
      }
    }
    return _destination;
  }

  double _computeDeviationFromRoute(Position pos) {
    if (_activeRoute == null || _activeRoute!.points.length < 2) return 0;
    final userPos = LatLng(pos.latitude, pos.longitude);
    double minDist = double.infinity;
    for (int i = 0; i < _activeRoute!.points.length - 1; i++) {
      final d = _distancePointToSegment(userPos, _activeRoute!.points[i], _activeRoute!.points[i + 1]);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  // Geometry helpers
  double _distancePointToSegment(LatLng p, LatLng a, LatLng b) {
    final apLat = p.latitude - a.latitude;
    final apLng = p.longitude - a.longitude;
    final abLat = b.latitude - a.latitude;
    final abLng = b.longitude - a.longitude;
    final ab2 = abLat * abLat + abLng * abLng;
    if (ab2 == 0) return haversineMeters(p.latitude, p.longitude, a.latitude, a.longitude);
    final t = math.max(0, math.min(1, (apLat * abLat + apLng * abLng) / ab2));
    final projLat = a.latitude + t * abLat;
    final projLng = a.longitude + t * abLng;
    return haversineMeters(p.latitude, p.longitude, projLat, projLng);
  }

  LatLng _projectPointOnSegment(LatLng p, LatLng a, LatLng b) {
    final apLat = p.latitude - a.latitude;
    final apLng = p.longitude - a.longitude;
    final abLat = b.latitude - a.latitude;
    final abLng = b.longitude - a.longitude;
    final ab2 = abLat * abLat + abLng * abLng;
    if (ab2 == 0) return a;
    final t = math.max(0, math.min(1, (apLat * abLat + apLng * abLng) / ab2));
    return LatLng(a.latitude + t * abLat, a.longitude + t * abLng);
  }

  void _updateMetrics(LiveWalkingMetrics metrics) {
    if (_currentMetrics != metrics) {
      _currentMetrics = metrics;
      notifyListeners();
      onMetricsUpdate?.call(metrics);
      onEtaUpdate?.call(metrics);
    }
  }

  // --- Deviation Monitoring ---
  void _startDeviationMonitoring() {
    _deviationCheckTimer?.cancel();
    _deviationCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkDeviation();
    });
  }

  void _checkDeviation() {
    if (!_currentMetrics.isMoving || _activeRoute == null) return;

    if (!_currentMetrics.isOnRoute) {
      _consecutiveDeviations++;
      if (_consecutiveDeviations >= _maxDeviationsBeforeRecalc) {
        _triggerRecalculation();
      } else {
        onDeviationAlert?.call(RouteDeviationAlert(
          deviationMeters: _currentMetrics.deviationMeters,
          consecutiveCount: _consecutiveDeviations,
          thresholdMeters: _deviationThresholdMeters,
        ));
      }
    } else {
      _consecutiveDeviations = 0;
    }
  }

  Future<void> _triggerRecalculation() async {
    final pos = _location.currentPositionSync;
    if (pos == null || _destination == null) return;

    debugPrint('[LiveTrackingEngine] 🔄 Route deviation detected, recalculating...');
    _consecutiveDeviations = 0;

    final newRoute = await _routing.getWalkingRouteToPoint(
      start: LatLng(pos.latitude, pos.longitude),
      destination: _destination!,
      destinationName: _destinationName ?? 'Destination',
      targetPandal: _targetPandal,
    );

    _activeRoute = newRoute;
    _recentPositions.clear(); // Reset history for fresh metrics
    notifyListeners();
  }

  // --- Arrival Detection ---
  void _checkArrival(Position pos) {
    if (_arrivalAnnounced || _destination == null) return;

    final dist = Geolocator.distanceBetween(
      pos.latitude, pos.longitude,
      _destination!.latitude, _destination!.longitude,
    );

    if (dist <= _arrivalThresholdMeters) {
      _arrivalAnnounced = true;
      onArrivalAlert?.call(ArrivalAlert(
        destinationName: _destinationName ?? 'Destination',
        distanceMeters: dist.round(),
        arrivalTime: DateTime.now(),
      ));
    }
  }

  // --- Crowd Density Sharing (via Squad) ---
  void _startCrowdDensitySharing() {
    // Periodically broadcast local crowd density if in squad
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (_squad.hasActiveSquad && _squad.isSharingLocation) {
        _broadcastCrowdDensity();
      }
      _cleanupStaleReports();
    });
  }

  void _broadcastCrowdDensity() {
    final pos = _location.currentPositionSync;
    if (pos == null) return;

    // Estimate crowd density from nearby squad members
    int nearbyCount = 0;
    for (final member in _squad.companionMembers) {
      if (!member.shareLocation || !member.isOnline) continue;
      final dist = haversineMeters(
        pos.latitude, pos.longitude,
        member.latitude, member.longitude,
      );
      if (dist <= 100) nearbyCount++; // Within 100m
    }

    final level = _estimateCrowdLevel(nearbyCount);
    final report = CrowdDensityReport(
      location: LatLng(pos.latitude, pos.longitude),
      level: level,
      nearbyCount: nearbyCount,
      timestamp: DateTime.now(),
      reporterId: _squad.members.firstWhere((m) => m.isUser).id,
    );

    debugPrint('Crowd report logged: ${report.level.name} ($nearbyCount nearby)');
    // Share via Firestore (squad repository handles this)
    // _squad.repository.updateCrowdDensity(_squad.squadId!, report).catchError((e) {
    //   debugPrint('[LiveTrackingEngine] Crowd density share error: $e');
    // });
  }

  void _cleanupStaleReports() {
    final now = DateTime.now();
    _crowdReports.removeWhere((_, report) =>
        now.difference(report.timestamp) > _crowdReportTtl);
    notifyListeners();
  }

  CrowdDensityLevel _estimateCrowdLevel(int nearbyCount) {
    if (nearbyCount >= 8) return CrowdDensityLevel.veryHigh;
    if (nearbyCount >= 5) return CrowdDensityLevel.high;
    if (nearbyCount >= 3) return CrowdDensityLevel.medium;
    if (nearbyCount >= 1) return CrowdDensityLevel.low;
    return CrowdDensityLevel.none;
  }

  /// Receive crowd density report from squad member
  void receiveCrowdReport(CrowdDensityReport report) {
    _crowdReports[report.reporterId] = report;
    onCrowdDensityUpdate?.call(report);
    notifyListeners();
  }

  /// Get aggregated crowd density for map rendering
  List<CrowdDensityReport> getActiveCrowdReports() {
    _cleanupStaleReports();
    return _crowdReports.values.toList();
  }

  /// Stop all tracking
  void stopTracking() {
    _metricsTimer?.cancel();
    _deviationCheckTimer?.cancel();
    _location.removeListener(_onLocationUpdate);
    _activeRoute = null;
    _destination = null;
    _destinationName = null;
    _targetPandal = null;
    _arrivalAnnounced = false;
    _consecutiveDeviations = 0;
    _recentPositions.clear();
    _emaSpeed = 0;
    _updateMetrics(LiveWalkingMetrics.stationary());
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

/// Alert when user deviates from planned route
class RouteDeviationAlert {
  const RouteDeviationAlert({
    required this.deviationMeters,
    required this.consecutiveCount,
    required this.thresholdMeters,
  });

  final double deviationMeters;
  final int consecutiveCount;
  final double thresholdMeters;

  String get message =>
      'You\'ve deviated ${deviationMeters.round()}m from route (${consecutiveCount}x). Recalculating...';
}

/// Alert when user arrives at destination
class ArrivalAlert {
  const ArrivalAlert({
    required this.destinationName,
    required this.distanceMeters,
    required this.arrivalTime,
  });

  final String destinationName;
  final int distanceMeters;
  final DateTime arrivalTime;

  String get message => '🎉 Arrived at $_destinationName! (${_distanceMeters}m away)';
  String get _destinationName => destinationName;
  int get _distanceMeters => distanceMeters;
}

/// Crowd density levels for map visualization
enum CrowdDensityLevel {
  none,
  low,
  medium,
  high,
  veryHigh,
}

extension CrowdDensityLevelX on CrowdDensityLevel {
  Color get color {
    switch (this) {
      case CrowdDensityLevel.none: return const Color(0x00000000);
      case CrowdDensityLevel.low: return const Color(0xFF4CAF50); // Green
      case CrowdDensityLevel.medium: return const Color(0xFFFFC107); // Amber
      case CrowdDensityLevel.high: return const Color(0xFFFF9800); // Orange
      case CrowdDensityLevel.veryHigh: return const Color(0xFFF44336); // Red
    }
  }

  String get label {
    switch (this) {
      case CrowdDensityLevel.none: return 'Clear';
      case CrowdDensityLevel.low: return 'Light';
      case CrowdDensityLevel.medium: return 'Moderate';
      case CrowdDensityLevel.high: return 'Busy';
      case CrowdDensityLevel.veryHigh: return 'Very Busy';
    }
  }
}

/// Crowd density report from squad member
class CrowdDensityReport {
  const CrowdDensityReport({
    required this.location,
    required this.level,
    required this.nearbyCount,
    required this.timestamp,
    required this.reporterId,
  });

  final LatLng location;
  final CrowdDensityLevel level;
  final int nearbyCount;
  final DateTime timestamp;
  final String reporterId;

  bool get isStale => DateTime.now().difference(timestamp) > const Duration(minutes: 10);
}
