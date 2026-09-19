import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../models/pandal.dart';
import '../utils/haversine.dart';
import 'location_service.dart';
import 'notification_progress_service.dart';
import 'pandal_user_state_service.dart';
import 'trail_optimizer.dart';

/// User's preferred vibe / hopping style
enum HoppingStyle {
  heritage(
    id: 'heritage',
    title: 'Art & Heritage',
    bengaliTitle: 'সাবেকি ও সাবেকিয়ানা',
    description: 'Bonedi Baris, clay artisan idols & traditional cultural decor',
    iconEmoji: '🏛️',
  ),
  blockbuster(
    id: 'blockbuster',
    title: 'Blockbuster & Mega Theme',
    bengaliTitle: 'মেগা পুজো ও আলো',
    description: 'Crowd-pullers, grand architecture, dazzling lights & big themes',
    iconEmoji: '🌟',
  ),
  serene(
    id: 'serene',
    title: 'Peaceful & Low Queue',
    bengaliTitle: 'শান্ত পরিবেশ ও স্বল্প ভিড়',
    description: 'Neighborhood gems with scenic ambiance and faster pandal entry',
    iconEmoji: '🌿',
  ),
  foodie(
    id: 'foodie',
    title: 'Foodie & Bhog Trail',
    bengaliTitle: 'খাবার ও ভোগের মেলা',
    description: 'Famous street food stalls, phuchka corners & bhog distribution',
    iconEmoji: '🍲',
  ),
  express(
    id: 'express',
    title: 'Express Hopper',
    bengaliTitle: 'দ্রুত পরিক্রমা',
    description: 'Tightly clustered pandals for maximum visits in minimum distance',
    iconEmoji: '⚡',
  );

  const HoppingStyle({
    required this.id,
    required this.title,
    required this.bengaliTitle,
    required this.description,
    required this.iconEmoji,
  });

  final String id;
  final String title;
  final String bengaliTitle;
  final String description;
  final String iconEmoji;
}

/// Preferred mode of travel
enum HoppingTransitMode {
  walking(
    label: 'Walking Only',
    avgSpeedKmh: 4.5,
    maxRadiusKm: 3.5,
  ),
  metroTransit(
    label: 'Metro & Walking',
    avgSpeedKmh: 16.0,
    maxRadiusKm: 8.0,
  ),
  cabAuto(
    label: 'Cab / Auto',
    avgSpeedKmh: 18.0,
    maxRadiusKm: 12.0,
  );

  const HoppingTransitMode({
    required this.label,
    required this.avgSpeedKmh,
    required this.maxRadiusKm,
  });

  final String label;
  final double avgSpeedKmh;
  final double maxRadiusKm;
}

/// A planned custom hopping itinerary
class ActiveCustomTrail {
  ActiveCustomTrail({
    required this.id,
    required this.style,
    required this.timeBudgetMinutes,
    required this.transitMode,
    required this.startingLocation,
    required this.startingAddress,
    required this.stops,
    required this.totalDistanceKm,
    required this.totalEstimatedMinutes,
    DateTime? startedAt,
  })  : startedAt = startedAt ?? DateTime.now(),
        visitedPandalIds = {};

  /// Factory constructor for custom trails created via the Custom Trail Builder
  factory ActiveCustomTrail.custom({
    required String id,
    required LatLng startingLocation,
    required String startingAddress,
    required List<Pandal> stops,
    required double totalDistanceKm,
    required int totalEstimatedMinutes,
    HoppingStyle style = HoppingStyle.express,
    HoppingTransitMode transitMode = HoppingTransitMode.walking,
    DateTime? startedAt,
  }) {
    return ActiveCustomTrail(
      id: id,
      style: style,
      timeBudgetMinutes: totalEstimatedMinutes,
      transitMode: transitMode,
      startingLocation: startingLocation,
      startingAddress: startingAddress,
      stops: stops,
      totalDistanceKm: totalDistanceKm,
      totalEstimatedMinutes: totalEstimatedMinutes,
      startedAt: startedAt,
    );
  }

  final String id;
  final HoppingStyle style;
  final int timeBudgetMinutes;
  final HoppingTransitMode transitMode;
  final LatLng startingLocation;
  final String startingAddress;
  final List<Pandal> stops;
  final double totalDistanceKm;
  final int totalEstimatedMinutes;
  final DateTime startedAt;

  /// Real road-routed distance in kilometers computed via GemKit native RoutingService.
  double? routedDistanceKm;

  /// Real road-routed duration in minutes (including dwelling time) computed via GemKit native RoutingService.
  int? routedEstimatedMinutes;

  /// Remaining routed distance in km for unvisited stops
  double? remainingRoutedDistanceKm;

  /// Remaining routed duration in minutes for unvisited stops
  int? remainingRoutedDurationMinutes;

  /// High-resolution road-following coordinates along actual streets from GemKit route calculation.
  List<LatLng>? routedPolyline;

  LatLng get startPoint => startingLocation;

  int currentStopIndex = 0;
  final Set<String> visitedPandalIds;
  bool isCompleted = false;

  int get totalStops => stops.length;
  int get visitedCount => visitedPandalIds.length;
  double get progressFraction => totalStops > 0 ? (visitedCount / totalStops).clamp(0.0, 1.0) : 0.0;

  Pandal? get currentTargetPandal =>
      (currentStopIndex >= 0 && currentStopIndex < stops.length) ? stops[currentStopIndex] : null;

  Pandal? get previousVisitedPandal {
    if (currentStopIndex > 0 && currentStopIndex <= stops.length) {
      return stops[currentStopIndex - 1];
    }
    return null;
  }

  Pandal? get nextPandalAfterCurrent {
    if (currentStopIndex + 1 < stops.length) {
      return stops[currentStopIndex + 1];
    }
    return null;
  }

  int get remainingEstimatedMinutes {
    if (remainingRoutedDurationMinutes != null) {
      return remainingRoutedDurationMinutes!;
    }
    final elapsed = DateTime.now().difference(startedAt).inMinutes;
    final left = (routedEstimatedMinutes ?? totalEstimatedMinutes) - elapsed;
    return left > 0 ? left : 5;
  }
}

/// Service managing custom trail generation, active navigation state,
/// auto-visit geofence proximity triggers, and notification bar sync.
class CustomHoppingTrailService extends ChangeNotifier {
  static final CustomHoppingTrailService instance = CustomHoppingTrailService._();
  CustomHoppingTrailService._();

  ActiveCustomTrail? _activeTrail;
  VoidCallback? _locationListener;
  PandalUserStateService? _userStateService;

  // Auto-visit trigger radius in meters
  static const double autoVisitThresholdMeters = 80.0;

  ActiveCustomTrail? get activeTrail => _activeTrail;
  bool get hasActiveTrail => _activeTrail != null && !_activeTrail!.isCompleted;
  Pandal? get currentTarget => _activeTrail?.currentTargetPandal;

  /// Updates the active trail with real road-following metrics calculated by GemKit RoutingService.
  void updateRoutedStats({
    required double distanceKm,
    required int durationMinutes,
    List<LatLng>? polyline,
    double? remainingDistanceKm,
    int? remainingDurationMinutes,
  }) {
    if (_activeTrail == null) return;
    _activeTrail!.routedDistanceKm = distanceKm;
    _activeTrail!.routedEstimatedMinutes = durationMinutes;
    if (polyline != null && polyline.isNotEmpty) {
      _activeTrail!.routedPolyline = polyline;
    }
    _activeTrail!.remainingRoutedDistanceKm = remainingDistanceKm ?? distanceKm;
    _activeTrail!.remainingRoutedDurationMinutes =
        remainingDurationMinutes ?? durationMinutes;
    _updateNotificationShade();
    notifyListeners();
  }

  void attachUserStateService(PandalUserStateService service) {
    _userStateService = service;
  }

  /// Generates a deterministic, on-device shortest Hamiltonian trail
  /// through user-selected pandals using Held-Karp / 2-opt optimization.
  ActiveCustomTrail generateOptimizedTrail({
    required LatLng startPos,
    required String startLabel,
    required List<Pandal> selectedPandals,
  }) {
    final result = TrailOptimizer.optimizePandalStops(
      start: startPos,
      stops: selectedPandals,
    );

    // Estimate dwell time (~15 mins per pandal) + walk duration
    final totalEstMinutes =
        (result.totalDurationMinutes + (result.orderedStops.length * 15)).round();

    return ActiveCustomTrail.custom(
      id: 'custom_trail_${DateTime.now().millisecondsSinceEpoch}',
      startingLocation: startPos,
      startingAddress: startLabel,
      stops: result.orderedStops,
      totalDistanceKm: result.totalDistanceKm,
      totalEstimatedMinutes: totalEstMinutes,
    );
  }

  /// Generates an optimized custom pandal itinerary tailored to
  /// the user's location, available time budget, and hopping vibe.
  ActiveCustomTrail generateTrail({
    required LatLng startPos,
    required String startLabel,
    required HoppingStyle style,
    required int timeBudgetMinutes,
    required HoppingTransitMode transitMode,
    required List<Pandal> allPandals,
  }) {
    // 1. Filter pandals by realistic travel radius from starting point
    final maxRadius = transitMode.maxRadiusKm;
    final candidates = allPandals.where((p) {
      final d = haversineMeters(startPos.latitude, startPos.longitude, p.lat, p.lng) / 1000.0;
      return d <= maxRadius;
    }).toList();

    // 2. Score candidate pandals based on user's hopping style
    double scorePandal(Pandal p) {
      double score = (p.rating ?? 4.0) * 10.0;
      final themeLower = p.theme.toLowerCase();
      final descLower = p.description.toLowerCase();
      final nameLower = p.name.toLowerCase();

      switch (style) {
        case HoppingStyle.heritage:
          if (themeLower.contains('traditional') ||
              themeLower.contains('heritage') ||
              themeLower.contains('sabeki') ||
              themeLower.contains('bonedi') ||
              themeLower.contains('clay') ||
              themeLower.contains('bari') ||
              descLower.contains('heritage') ||
              nameLower.contains('bari') ||
              nameLower.contains('rajbari')) {
            score += 40;
          }
          break;

        case HoppingStyle.blockbuster:
          if (p.crowdLevel == 'high' || p.crowdLevel == 'extreme') score += 25;
          if (score >= 43) score += 20;
          if (themeLower.contains('lighting') || themeLower.contains('extravaganza')) score += 20;
          break;

        case HoppingStyle.serene:
          if (p.crowdLevel == 'low') score += 35;
          if (p.crowdLevel == 'medium') score += 15;
          if (p.crowdLevel == 'high') score -= 20;
          break;

        case HoppingStyle.foodie:
          if (p.specialFeatures.any((f) => f.toLowerCase().contains('bhog') || f.toLowerCase().contains('food')) ||
              descLower.contains('food') ||
              descLower.contains('bhog')) {
            score += 35;
          }
          break;

        case HoppingStyle.express:
          // In express, priority is minimal distance
          score += 15;
          break;
      }
      return score;
    }

    candidates.sort((a, b) => scorePandal(b).compareTo(scorePandal(a)));

    // Take the top pool of qualified candidates (up to 40)
    final pool = candidates.take(40).toList();

    // 3. Time-Bounded Greedy Nearest-Neighbor Route Algorithm
    final List<Pandal> orderedStops = [];
    LatLng currentLoc = startPos;
    double accumulatedMinutes = 0.0;
    double accumulatedDistanceKm = 0.0;

    while (accumulatedMinutes < timeBudgetMinutes && pool.isNotEmpty) {
      // Find candidate with best balance of proximity and style score
      Pandal? bestNext;
      double bestScore = -999999;
      double bestDist = 0;

      for (final p in pool) {
        final dist = haversineMeters(currentLoc.latitude, currentLoc.longitude, p.lat, p.lng) / 1000.0;
        // Distance penalty to favor close next pandals
        final distPenalty = dist * (style == HoppingStyle.express ? 25.0 : 12.0);
        final totalCandidateScore = scorePandal(p) - distPenalty;

        if (totalCandidateScore > bestScore) {
          bestScore = totalCandidateScore;
          bestNext = p;
          bestDist = dist;
        }
      }

      if (bestNext == null) break;

      // Travel time to next pandal (minutes)
      final travelMins = (bestDist / transitMode.avgSpeedKmh) * 60.0;

      // Estimated dwell/queue time per pandal
      double dwellMins = 20.0;
      if (bestNext.crowdLevel == 'high' || bestNext.crowdLevel == 'extreme') {
        dwellMins = 30.0;
      } else if (bestNext.crowdLevel == 'low') {
        dwellMins = 14.0;
      }

      final legTotalMins = travelMins + dwellMins;

      // Check if adding this pandal still fits inside budget (allowing a 15m buffer)
      if (orderedStops.isNotEmpty && (accumulatedMinutes + legTotalMins) > (timeBudgetMinutes + 15)) {
        break;
      }

      orderedStops.add(bestNext);
      accumulatedMinutes += legTotalMins;
      accumulatedDistanceKm += bestDist;
      currentLoc = LatLng(bestNext.lat, bestNext.lng);
      pool.remove(bestNext);
    }

    // Ensure at least 1 or 2 stops if candidates existed
    if (orderedStops.isEmpty && candidates.isNotEmpty) {
      orderedStops.add(candidates.first);
      accumulatedMinutes = 25.0;
      accumulatedDistanceKm = haversineMeters(
        startPos.latitude,
        startPos.longitude,
        candidates.first.lat,
        candidates.first.lng,
      ) / 1000.0;
    }

    return ActiveCustomTrail(
      id: 'trail_${DateTime.now().millisecondsSinceEpoch}',
      style: style,
      timeBudgetMinutes: timeBudgetMinutes,
      transitMode: transitMode,
      startingLocation: startPos,
      startingAddress: startLabel,
      stops: orderedStops,
      totalDistanceKm: double.parse(accumulatedDistanceKm.toStringAsFixed(1)),
      totalEstimatedMinutes: accumulatedMinutes.round(),
    );
  }

  /// Starts the active trail session, enables continuous location listening,
  /// and displays the ongoing progress notification in the Android shade.
  Future<void> startTrail(ActiveCustomTrail trail) async {
    _activeTrail = trail;
    _activeTrail!.currentStopIndex = 0;
    _activeTrail!.isCompleted = false;

    // Start location tracking if not running
    await LocationService.instance.startLiveTracking();

    // Attach to live GPS stream for auto-visit proximity checks
    if (_locationListener != null) {
      LocationService.instance.removeListener(_locationListener!);
    }
    _locationListener = () {
      final pos = LocationService.instance.currentPositionSync;
      if (pos != null) {
        checkProximityAndAutoVisit(LatLng(pos.latitude, pos.longitude));
      }
    };
    LocationService.instance.addListener(_locationListener!);

    // Initial notification
    await _updateNotificationShade();
    notifyListeners();
  }

  /// Checks if the user is within the 80-meter auto-visit threshold of the target pandal.
  void checkProximityAndAutoVisit(LatLng userPos) {
    if (!hasActiveTrail) return;
    final target = currentTarget;
    if (target == null) return;

    final distanceMeters = haversineMeters(
      userPos.latitude,
      userPos.longitude,
      target.lat,
      target.lng,
    );

    if (distanceMeters <= autoVisitThresholdMeters) {
      // Auto-visit triggered!
      recordAutoVisit(target);
    } else {
      // Periodic notification update with live distance
      _updateNotificationShade(distanceToNextMeters: distanceMeters);
    }
  }

  /// Explicitly marks the current pandal as visited and advances the trail
  Future<void> recordAutoVisit(Pandal pandal) async {
    if (!hasActiveTrail) return;
    final trail = _activeTrail!;

    if (!trail.visitedPandalIds.contains(pandal.id)) {
      trail.visitedPandalIds.add(pandal.id);
      // Persist in user state visited store
      _userStateService?.toggleVisited(pandal.id);

      // Trigger celebratory haptic feedback
      HapticFeedback.heavyImpact();
    }

    // Advance to next pandal
    if (trail.currentStopIndex < trail.totalStops - 1) {
      trail.currentStopIndex++;
      trail.remainingRoutedDistanceKm = null;
      trail.remainingRoutedDurationMinutes = null;
      await _updateNotificationShade();
    } else {
      // All stops visited!
      trail.isCompleted = true;
      trail.remainingRoutedDistanceKm = 0.0;
      trail.remainingRoutedDurationMinutes = 0;
      await NotificationProgressService.instance.showTrailCompleted(
        totalVisited: trail.totalStops,
      );
    }

    notifyListeners();
  }

  /// Manual skip of current stop
  Future<void> skipCurrentStop() async {
    if (!hasActiveTrail) return;
    final trail = _activeTrail!;
    if (trail.currentStopIndex < trail.totalStops - 1) {
      trail.currentStopIndex++;
      trail.remainingRoutedDistanceKm = null;
      trail.remainingRoutedDurationMinutes = null;
      await _updateNotificationShade();
      notifyListeners();
    } else {
      endTrail();
    }
  }

  /// Ends and dismisses the active hopping trail
  Future<void> endTrail() async {
    if (_locationListener != null) {
      LocationService.instance.removeListener(_locationListener!);
      _locationListener = null;
    }
    _activeTrail = null;
    await NotificationProgressService.instance.cancelTrailProgress();
    notifyListeners();
  }

  Future<void> _updateNotificationShade({double? distanceToNextMeters}) async {
    if (_activeTrail == null) return;
    final trail = _activeTrail!;

    final currentName = trail.previousVisitedPandal?.name ?? trail.startingAddress;
    final nextName = trail.currentTargetPandal?.name ?? 'End of Trail';

    await NotificationProgressService.instance.showTrailProgress(
      currentStep: trail.visitedCount,
      totalSteps: trail.totalStops,
      currentPandalName: currentName,
      nextPandalName: nextName,
      distanceToNextMeters: distanceToNextMeters,
      remainingMinutes: trail.remainingEstimatedMinutes,
    );
  }
}
