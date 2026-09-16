import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/pandal.dart';
import '../utils/haversine.dart';
import 'routing_service.dart';

/// Enhanced navigation service with turn-by-turn capabilities
/// Provides Magic Lane-like features using open-source alternatives
class EnhancedNavigationService extends ChangeNotifier {
  EnhancedNavigationService._();
  static final EnhancedNavigationService instance = EnhancedNavigationService._();

  // Navigation state
  bool _isNavigating = false;
  Pandal? _destination;
  List<LatLng>? _routePoints;
  int _currentSegmentIndex = 0;
  double _distanceToNextTurn = 0;
  String _currentInstruction = '';
  double _totalDistanceRemaining = 0;
  int _estimatedTimeRemaining = 0; // seconds

  // Navigation thresholds
  static const double _arrivedThreshold = 15.0; // meters to destination
  static const double _offRouteThreshold = 30.0; // meters off route
  static const double _averageWalkingSpeed = 1.25; // m/s (4.5 km/h)

  double calculateDistance(double lat1, double lng1, double lat2, double lng2) =>
      haversineMeters(lat1, lng1, lat2, lng2);

  // Getters
  bool get isNavigating => _isNavigating;
  Pandal? get destination => _destination;
  List<LatLng>? get routePoints => _routePoints;
  String get currentInstruction => _currentInstruction;
  double get distanceToNextTurn => _distanceToNextTurn;
  double get totalDistanceRemaining => _totalDistanceRemaining;
  int get estimatedTimeRemaining => _estimatedTimeRemaining;
  double get progressPercentage {
    if (_routePoints == null || _routePoints!.isEmpty) return 0.0;
    return (_currentSegmentIndex / _routePoints!.length).clamp(0.0, 1.0);
  }

  StreamSubscription<Position>? _positionSubscription;

  /// Start navigation to a destination
  Future<void> startNavigation({
    required Pandal destination,
    required LatLng startPoint,
  }) async {
    debugPrint('[Navigation] Starting navigation to ${destination.name}');

    _destination = destination;
    _isNavigating = true;
    _currentSegmentIndex = 0;

    // Get route from routing service
    final walkingRoute = await RoutingService.instance.getWalkingRouteToPoint(
      start: startPoint,
      destination: LatLng(destination.lat, destination.lng),
      destinationName: destination.name,
      targetPandal: destination,
    );
    final route = walkingRoute.points;

    if (route.isNotEmpty) {
      _routePoints = route;
      _calculateTotalDistance();
      _updateNavigationState(startPoint);
      _startPositionTracking();
    } else {
      debugPrint('[Navigation] Failed to get route');
      stopNavigation();
    }

    notifyListeners();
  }

  /// Stop navigation
  void stopNavigation() {
    debugPrint('[Navigation] Stopping navigation');
    _isNavigating = false;
    _destination = null;
    _routePoints = null;
    _currentSegmentIndex = 0;
    _currentInstruction = '';
    _distanceToNextTurn = 0;
    _totalDistanceRemaining = 0;
    _estimatedTimeRemaining = 0;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    notifyListeners();
  }

  /// Start tracking user position during navigation
  void _startPositionTracking() {
    _positionSubscription?.cancel();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      if (_isNavigating && _routePoints != null) {
        final currentLocation = LatLng(position.latitude, position.longitude);
        _updateNavigationState(currentLocation);
        _checkIfArrived(currentLocation);
        _checkIfOffRoute(currentLocation);
        notifyListeners();
      }
    });
  }

  /// Update navigation state based on current position
  void _updateNavigationState(LatLng currentLocation) {
    if (_routePoints == null || _routePoints!.isEmpty) return;

    // Find closest point on route
    int closestIndex = _findClosestPointIndex(currentLocation);
    _currentSegmentIndex = closestIndex;

    // Calculate distance to next significant point
    _calculateDistanceToNextTurn(currentLocation, closestIndex);

    // Generate instruction
    _currentInstruction = _generateInstruction(currentLocation, closestIndex);

    // Calculate remaining distance and time
    _calculateRemainingDistance(closestIndex);
    _calculateEstimatedTime();
  }

  /// Find the closest point on the route to current location
  int _findClosestPointIndex(LatLng currentLocation) {
    if (_routePoints == null || _routePoints!.isEmpty) return 0;

    double minDistance = double.infinity;
    int closestIndex = _currentSegmentIndex;

    // Search forward from current segment
    for (int i = _currentSegmentIndex; i < _routePoints!.length; i++) {
      final distance = calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        _routePoints![i].latitude,
        _routePoints![i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  /// Calculate distance to next turn
  void _calculateDistanceToNextTurn(LatLng currentLocation, int fromIndex) {
    if (_routePoints == null || fromIndex >= _routePoints!.length - 1) {
      _distanceToNextTurn = 0;
      return;
    }

    // Look ahead for significant direction change
    int nextTurnIndex = _findNextTurn(fromIndex);

    if (nextTurnIndex == -1) {
      _distanceToNextTurn = calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        _routePoints!.last.latitude,
        _routePoints!.last.longitude,
      );
    } else {
      double distance = 0;
      for (int i = fromIndex; i < nextTurnIndex; i++) {
        distance += calculateDistance(
          _routePoints![i].latitude,
          _routePoints![i].longitude,
          _routePoints![i + 1].latitude,
          _routePoints![i + 1].longitude,
        );
      }
      _distanceToNextTurn = distance;
    }
  }

  /// Find next significant turn in route
  int _findNextTurn(int fromIndex) {
    if (_routePoints == null || fromIndex >= _routePoints!.length - 2) {
      return -1;
    }

    for (int i = fromIndex; i < _routePoints!.length - 2; i++) {
      final angle = _calculateBearingChange(i, i + 1, i + 2);
      if (angle.abs() > 30) {
        // Significant turn (> 30 degrees)
        return i + 1;
      }
    }

    return -1; // No significant turn found
  }

  /// Calculate bearing change between three points
  double _calculateBearingChange(int idx1, int idx2, int idx3) {
    if (_routePoints == null || idx3 >= _routePoints!.length) return 0;

    final bearing1 = _calculateBearing(
      _routePoints![idx1],
      _routePoints![idx2],
    );
    final bearing2 = _calculateBearing(
      _routePoints![idx2],
      _routePoints![idx3],
    );

    double change = bearing2 - bearing1;
    if (change > 180) change -= 360;
    if (change < -180) change += 360;

    return change;
  }

  /// Calculate bearing between two points
  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  /// Generate navigation instruction
  String _generateInstruction(LatLng currentLocation, int segmentIndex) {
    if (_routePoints == null || _destination == null) {
      return 'No route available';
    }

    if (segmentIndex >= _routePoints!.length - 1) {
      return 'Arriving at ${_destination!.name}';
    }

    // Find next turn
    int nextTurnIndex = _findNextTurn(segmentIndex);

    if (nextTurnIndex == -1) {
      // No more turns, go straight to destination
      final distance = _distanceToNextTurn;
      if (distance < 50) {
        return 'Destination ahead on your left';
      } else if (distance < 100) {
        return 'Continue straight for ${distance.round()}m';
      } else {
        return 'Continue for ${(distance / 1000).toStringAsFixed(1)} km';
      }
    }

    // Calculate turn direction
    final turnAngle = _calculateBearingChange(
      segmentIndex,
      nextTurnIndex,
      math.min(nextTurnIndex + 1, _routePoints!.length - 1),
    );

    final String turnDirection;
    if (turnAngle > 120) {
      turnDirection = 'Turn sharp right';
    } else if (turnAngle > 30) {
      turnDirection = 'Turn right';
    } else if (turnAngle < -120) {
      turnDirection = 'Turn sharp left';
    } else if (turnAngle < -30) {
      turnDirection = 'Turn left';
    } else {
      turnDirection = 'Continue straight';
    }

    final distance = _distanceToNextTurn;
    if (distance < 20) {
      return '$turnDirection now';
    } else if (distance < 50) {
      return '$turnDirection in ${distance.round()}m';
    } else if (distance < 100) {
      return 'In ${distance.round()}m, $turnDirection';
    } else {
      return 'In ${(distance / 1000).toStringAsFixed(1)} km, $turnDirection';
    }
  }

  /// Calculate total route distance
  void _calculateTotalDistance() {
    if (_routePoints == null || _routePoints!.isEmpty) {
      _totalDistanceRemaining = 0;
      return;
    }

    double total = 0;
    for (int i = 0; i < _routePoints!.length - 1; i++) {
      total += calculateDistance(
        _routePoints![i].latitude,
        _routePoints![i].longitude,
        _routePoints![i + 1].latitude,
        _routePoints![i + 1].longitude,
      );
    }
    _totalDistanceRemaining = total;
  }

  /// Calculate remaining distance from current segment
  void _calculateRemainingDistance(int fromIndex) {
    if (_routePoints == null || fromIndex >= _routePoints!.length - 1) {
      _totalDistanceRemaining = 0;
      return;
    }

    double remaining = 0;
    for (int i = fromIndex; i < _routePoints!.length - 1; i++) {
      remaining += calculateDistance(
        _routePoints![i].latitude,
        _routePoints![i].longitude,
        _routePoints![i + 1].latitude,
        _routePoints![i + 1].longitude,
      );
    }
    _totalDistanceRemaining = remaining;
  }

  /// Calculate estimated time remaining
  void _calculateEstimatedTime() {
    // Using average walking speed of 1.25 m/s (4.5 km/h)
    _estimatedTimeRemaining = (_totalDistanceRemaining / _averageWalkingSpeed).round();
  }

  /// Check if user has arrived at destination
  void _checkIfArrived(LatLng currentLocation) {
    if (_destination == null) return;

    final distanceToDestination = calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      _destination!.lat,
      _destination!.lng,
    );

    if (distanceToDestination < _arrivedThreshold) {
      debugPrint('[Navigation] Arrived at destination!');
      _currentInstruction = 'You have arrived at ${_destination!.name}';
      // Don't stop navigation yet, let user do it manually
    }
  }

  /// Check if user has gone off route
  void _checkIfOffRoute(LatLng currentLocation) {
    if (_routePoints == null || _routePoints!.isEmpty) return;

    // Find distance to closest point on route
    double minDistance = double.infinity;
    for (final point in _routePoints!) {
      final distance = calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    if (minDistance > _offRouteThreshold) {
      debugPrint('[Navigation] User off route by ${minDistance.round()}m');
      _currentInstruction = 'Recalculating route...';
      // TODO: Trigger route recalculation
      _recalculateRoute(currentLocation);
    }
  }

  /// Recalculate route from current position
  Future<void> _recalculateRoute(LatLng currentLocation) async {
    if (_destination == null) return;

    debugPrint('[Navigation] Recalculating route');

    final walkingRoute = await RoutingService.instance.getWalkingRouteToPoint(
      start: currentLocation,
      destination: LatLng(_destination!.lat, _destination!.lng),
      destinationName: _destination!.name,
      targetPandal: _destination,
    );
    final route = walkingRoute.points;

    if (route.isNotEmpty) {
      _routePoints = route;
      _currentSegmentIndex = 0;
      _calculateTotalDistance();
      debugPrint('[Navigation] Route recalculated successfully');
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
