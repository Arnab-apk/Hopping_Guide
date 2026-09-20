import 'package:latlong2/latlong.dart';

import '../models/pandal.dart';
import '../models/trail_leg.dart';
import '../utils/haversine.dart';
import 'metro_transit_estimator.dart';

export '../models/trail_leg.dart';

/// Result of a trail optimization run.
class TrailOptimizationResult {
  const TrailOptimizationResult({
    required this.orderedStops,
    required this.totalDurationMinutes,
    required this.totalDistanceKm,
    required this.visitOrderIndices,
    this.legs = const [],
  });

  /// The pandals in the optimal visit order.
  final List<Pandal> orderedStops;

  /// Total duration in minutes from start through all stops (walking + metro rides).
  final double totalDurationMinutes;

  /// Total walking/transit distance in kilometers from start through all stops.
  final double totalDistanceKm;

  /// 0-indexed indices into the original stops list representing the visit order.
  final List<int> visitOrderIndices;

  /// Ordered transit legs between successive stops (walk vs metro).
  final List<TrailLeg> legs;
}

/// On-device deterministic shortest Hamiltonian path optimizer.
///
/// Starts fixed at node 0 (start point), visits all N other nodes exactly once,
/// with no requirement to return to start.
///
/// Uses exact Held-Karp dynamic programming for N <= 12 stops (O(N^2 * 2^N)),
/// and falls back to nearest-neighbor with 2-opt local search heuristic for N > 12.
class TrailOptimizer {
  TrailOptimizer._();

  /// Default walking speed in km/h (Kolkata pedestrian pace).
  static const double defaultWalkingSpeedKmH = 4.5;

  /// Urban street circuity factor (accounting for alleyways and turnings).
  static const double defaultCircuityFactor = 1.25;

  /// Threshold for exact vs. heuristic solving.
  static const int exactThreshold = 12;

  /// High-level method: takes a starting point and a list of candidate pandals,
  /// builds the on-device duration matrix, and returns the optimally ordered pandals.
  static TrailOptimizationResult optimizePandalStops({
    required LatLng start,
    required List<Pandal> stops,
    double walkingSpeedKmH = defaultWalkingSpeedKmH,
    double circuityFactor = defaultCircuityFactor,
    bool allowMetro = false,
  }) {
    if (stops.isEmpty) {
      return const TrailOptimizationResult(
        orderedStops: [],
        totalDurationMinutes: 0.0,
        totalDistanceKm: 0.0,
        visitOrderIndices: [],
        legs: [],
      );
    }

    if (stops.length == 1) {
      final p1 = stops.first;
      final target = LatLng(p1.lat, p1.lng);
      final legs = buildLegBreakdown(
        [start, target],
        allowMetro: allowMetro,
        walkingSpeedKmH: walkingSpeedKmH,
        circuityFactor: circuityFactor,
      );
      final distM = haversineMeters(
            start.latitude,
            start.longitude,
            p1.lat,
            p1.lng,
          ) *
          circuityFactor;
      final speedMPerMin = (walkingSpeedKmH * 1000.0) / 60.0;
      final walkDurationMin = distM / speedMPerMin;
      final durationMin = (legs.isNotEmpty && legs.first.isMetro)
          ? legs.first.metroDetail!.totalMinutes
          : walkDurationMin;

      return TrailOptimizationResult(
        orderedStops: List.from(stops),
        totalDurationMinutes: durationMin,
        totalDistanceKm: double.parse((distM / 1000.0).toStringAsFixed(2)),
        visitOrderIndices: const [0],
        legs: legs,
      );
    }

    final durationMatrix = buildDurationMatrix(
      start: start,
      stops: stops,
      walkingSpeedKmH: walkingSpeedKmH,
      circuityFactor: circuityFactor,
      allowMetro: allowMetro,
    );

    final result = optimize(durationMatrix);

    // result.order contains node indices (1..N).
    // Map node index -> 0-indexed stop index: (node - 1)
    final stopIndices = result.order.map((node) => node - 1).toList();
    final ordered = stopIndices.map((i) => stops[i]).toList();

    final orderedPoints = [
      start,
      ...ordered.map((p) => LatLng(p.lat, p.lng)),
    ];

    final legs = buildLegBreakdown(
      orderedPoints,
      allowMetro: allowMetro,
      walkingSpeedKmH: walkingSpeedKmH,
      circuityFactor: circuityFactor,
    );

    // Compute total distance along the optimized path
    double totalDistM = 0.0;
    LatLng prev = start;
    for (final p in ordered) {
      totalDistM += haversineMeters(
            prev.latitude,
            prev.longitude,
            p.lat,
            p.lng,
          ) *
          circuityFactor;
      prev = LatLng(p.lat, p.lng);
    }

    return TrailOptimizationResult(
      orderedStops: ordered,
      totalDurationMinutes: result.totalDuration,
      totalDistanceKm: double.parse((totalDistM / 1000.0).toStringAsFixed(2)),
      visitOrderIndices: stopIndices,
      legs: legs,
    );
  }

  /// Builds an (N+1) x (N+1) duration matrix where index 0 is start.
  static List<List<double>> buildDurationMatrix({
    required LatLng start,
    required List<Pandal> stops,
    double walkingSpeedKmH = defaultWalkingSpeedKmH,
    double circuityFactor = defaultCircuityFactor,
    bool allowMetro = false,
  }) {
    final n = stops.length + 1;
    final points = [
      start,
      ...stops.map((p) => LatLng(p.lat, p.lng)),
    ];
    final matrix = List.generate(n, (_) => List.filled(n, 0.0));
    final speedMPerMin = (walkingSpeedKmH * 1000.0) / 60.0;

    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (i == j) continue;
        final walkDistM = haversineMeters(
              points[i].latitude,
              points[i].longitude,
              points[j].latitude,
              points[j].longitude,
            ) *
            circuityFactor;
        final walkMinutes = walkDistM / speedMPerMin;

        if (!allowMetro) {
          matrix[i][j] = walkMinutes;
          continue;
        }

        final metro = MetroTransitEstimator.estimate(
          points[i],
          points[j],
          walkingSpeedKmH: walkingSpeedKmH,
        );
        matrix[i][j] = metro != null
            ? (metro.totalMinutes < walkMinutes ? metro.totalMinutes : walkMinutes)
            : walkMinutes;
      }
    }

    return matrix;
  }

  /// Unified solver entry point: delegates to exact Held-Karp or 2-opt heuristic.
  static ({List<int> order, double totalDuration}) optimize(
    List<List<double>> duration,
  ) {
    final numStops = duration.length - 1;
    if (numStops <= 0) return (order: [], totalDuration: 0.0);
    if (numStops <= exactThreshold) {
      return solveExact(duration);
    } else {
      return solveHeuristic(duration);
    }
  }

  /// Exact Held–Karp dynamic programming shortest Hamiltonian path from fixed node 0.
  ///
  /// Returns the optimal visit order (node indices into points, 1..N) and total duration.
  static ({List<int> order, double totalDuration}) solveExact(
    List<List<double>> duration,
  ) {
    final n = duration.length; // includes start at index 0
    final numStops = n - 1;
    if (numStops == 0) return (order: [], totalDuration: 0.0);
    if (numStops == 1) return (order: [1], totalDuration: duration[0][1]);

    final fullMask = 1 << numStops; // stops are bits 0..numStops-1, mapped to node index + 1
    final dp = List.generate(fullMask, (_) => List.filled(n, double.infinity));
    final parent = List.generate(fullMask, (_) => List.filled(n, -1));

    // Base case: mask with only stop i visited, coming directly from start (node 0)
    for (int i = 0; i < numStops; i++) {
      final mask = 1 << i;
      dp[mask][i + 1] = duration[0][i + 1];
    }

    for (int mask = 1; mask < fullMask; mask++) {
      for (int j = 0; j < numStops; j++) {
        if ((mask & (1 << j)) == 0) continue;
        final curCost = dp[mask][j + 1];
        if (curCost == double.infinity) continue;
        for (int k = 0; k < numStops; k++) {
          if ((mask & (1 << k)) != 0) continue;
          final nextMask = mask | (1 << k);
          final candidate = curCost + duration[j + 1][k + 1];
          if (candidate < dp[nextMask][k + 1]) {
            dp[nextMask][k + 1] = candidate;
            parent[nextMask][k + 1] = j + 1;
          }
        }
      }
    }

    // Find best end node for the full mask
    int bestEnd = -1;
    double bestCost = double.infinity;
    for (int j = 0; j < numStops; j++) {
      if (dp[fullMask - 1][j + 1] < bestCost) {
        bestCost = dp[fullMask - 1][j + 1];
        bestEnd = j + 1;
      }
    }

    // Backtrack to recover order
    final order = <int>[];
    int mask = fullMask - 1;
    int node = bestEnd;
    while (node != -1 && node != 0) {
      order.add(node);
      final p = parent[mask][node];
      mask &= ~(1 << (node - 1));
      node = p;
    }

    return (order: order.reversed.toList(), totalDuration: bestCost);
  }

  /// Heuristic Nearest-Neighbor construction followed by 2-opt swaps for N > 12.
  static ({List<int> order, double totalDuration}) solveHeuristic(
    List<List<double>> duration,
  ) {
    final n = duration.length;
    final numStops = n - 1;
    if (numStops == 0) return (order: [], totalDuration: 0.0);
    if (numStops == 1) return (order: [1], totalDuration: duration[0][1]);

    // 1. Nearest Neighbor construction from start (node 0)
    final unvisited = List.generate(numStops, (i) => i + 1).toSet();
    final tour = <int>[];
    int current = 0;

    while (unvisited.isNotEmpty) {
      int bestNext = unvisited.first;
      double minD = duration[current][bestNext];
      for (final candidate in unvisited) {
        final d = duration[current][candidate];
        if (d < minD) {
          minD = d;
          bestNext = candidate;
        }
      }
      tour.add(bestNext);
      unvisited.remove(bestNext);
      current = bestNext;
    }

    // 2. 2-opt iterative improvement
    double calculateCost(List<int> t) {
      double c = duration[0][t.first];
      for (int i = 0; i < t.length - 1; i++) {
        c += duration[t[i]][t[i + 1]];
      }
      return c;
    }

    double bestCost = calculateCost(tour);
    bool improved = true;
    int iterations = 0;
    const maxIterations = 80;

    while (improved && iterations < maxIterations) {
      improved = false;
      iterations++;
      for (int i = 0; i < tour.length - 1; i++) {
        for (int j = i + 1; j < tour.length; j++) {
          // Reverse subsegment tour[i..j]
          final reversedTour = List<int>.from(tour);
          int left = i;
          int right = j;
          while (left < right) {
            final tmp = reversedTour[left];
            reversedTour[left] = reversedTour[right];
            reversedTour[right] = tmp;
            left++;
            right--;
          }

          final newCost = calculateCost(reversedTour);
          if (newCost < bestCost - 1e-6) {
            tour.clear();
            tour.addAll(reversedTour);
            bestCost = newCost;
            improved = true;
            break;
          }
        }
        if (improved) break;
      }
    }

    return (order: tour, totalDuration: bestCost);
  }
}
