import 'package:latlong2/latlong.dart';

import '../models/metro_station.dart';
import '../repositories/metro_repository.dart';
import '../utils/haversine.dart';

/// Detailed breakdown of an estimated metro-assisted transit leg.
class MetroLegEstimate {
  const MetroLegEstimate({
    required this.totalMinutes,
    required this.boardingStation,
    required this.alightingStation,
    required this.requiresInterchange,
    this.interchangeStation,
  });

  final double totalMinutes;
  final MetroStation boardingStation;
  final MetroStation alightingStation;
  final bool requiresInterchange;
  final MetroStation? interchangeStation;
}

/// Estimates travel time and logistics for metro-assisted pandal hopping hops.
class MetroTransitEstimator {
  MetroTransitEstimator._();

  /// Average dwell + travel time between adjacent stations on the same line.
  static const double minutesPerStationHop = 2.5;

  /// Average wait time added for boarding (roughly half of typical headway).
  static const double boardingWaitMinutes = 4.0;

  /// Extra walking/transfer time when a line change is required.
  static const double interchangePenaltyMinutes = 9.0;

  /// Don't bother considering metro for walkable distances — the station
  /// walk + wait overhead usually erases any benefit for short hops.
  static const double minDirectDistanceKmToConsider = 1.5;

  /// Beyond this walk radius from a point, a metro station isn't
  /// practically usable as an access point.
  static const double maxStationWalkRadiusKm = 1.2;

  /// Finds the nearest metro station to a given coordinate within an optional radius in km.
  static MetroStation? _nearestStation(LatLng point, {double? withinKm}) {
    MetroStation? best;
    double bestDist = double.infinity;
    for (final s in MetroRepository.allStations) {
      final d = haversineMeters(point.latitude, point.longitude, s.latitude, s.longitude) / 1000.0;
      if (d < bestDist && (withinKm == null || d <= withinKm)) {
        bestDist = d;
        best = s;
      }
    }
    return best;
  }

  /// Returns null if metro isn't a sensible option for this pair (too close,
  /// or no usable station near one/both points).
  static MetroLegEstimate? estimate(
    LatLng a,
    LatLng b, {
    required double walkingSpeedKmH,
  }) {
    final directKm = haversineMeters(a.latitude, a.longitude, b.latitude, b.longitude) / 1000.0;
    if (directKm < minDirectDistanceKmToConsider) return null;

    final boarding = _nearestStation(a, withinKm: maxStationWalkRadiusKm);
    final alighting = _nearestStation(b, withinKm: maxStationWalkRadiusKm);
    if (boarding == null || alighting == null || boarding.id == alighting.id) return null;

    final walkToBoardingKm = haversineMeters(
          a.latitude,
          a.longitude,
          boarding.latitude,
          boarding.longitude,
        ) /
        1000.0;
    final walkFromAlightingKm = haversineMeters(
          b.latitude,
          b.longitude,
          alighting.latitude,
          alighting.longitude,
        ) /
        1000.0;
    final walkMinutes = ((walkToBoardingKm + walkFromAlightingKm) / walkingSpeedKmH) * 60.0;

    if (boarding.line == alighting.line) {
      final hops = sameLineHopCount(boarding, alighting);
      if (hops == null) return null; // fail-safe
      final rideMinutes = hops * minutesPerStationHop + boardingWaitMinutes;
      return MetroLegEstimate(
        totalMinutes: walkMinutes + rideMinutes,
        boardingStation: boarding,
        alightingStation: alighting,
        requiresInterchange: false,
      );
    }

    // Single-interchange case: find a station common to both lines.
    final interchange = findInterchange(boarding.line, alighting.line);
    if (interchange == null) return null; // no supported single-transfer path

    final firstLegHops = sameLineHopCount(boarding, interchange);
    final secondLegHops = sameLineHopCount(interchange, alighting);
    if (firstLegHops == null || secondLegHops == null) return null;

    final rideMinutes = (firstLegHops + secondLegHops) * minutesPerStationHop +
        boardingWaitMinutes +
        interchangePenaltyMinutes;

    return MetroLegEstimate(
      totalMinutes: walkMinutes + rideMinutes,
      boardingStation: boarding,
      alightingStation: alighting,
      requiresInterchange: true,
      interchangeStation: interchange,
    );
  }

  /// Ordered station list for a specific line in geographic travel order,
  /// including interchange nodes serving that line.
  static List<MetroStation> _stationsForLine(KolkataMetroLine line) {
    return MetroRepository.getStationsForLine(line);
  }

  /// Calculates number of station hops between two stations that share a line or interchange corridor.
  static int? sameLineHopCount(MetroStation a, MetroStation b) {
    KolkataMetroLine? commonLine;
    if (a.line == b.line) {
      commonLine = a.line;
    } else if (a.connectingLines.contains(b.line)) {
      commonLine = b.line;
    } else if (b.connectingLines.contains(a.line)) {
      commonLine = a.line;
    }
    if (commonLine == null) return null;

    final lineStations = _stationsForLine(commonLine);
    final ia = lineStations.indexWhere((s) => s.id == a.id);
    final ib = lineStations.indexWhere((s) => s.id == b.id);
    if (ia == -1 || ib == -1) return null;
    return (ia - ib).abs();
  }

  /// Finds a single interchange station linking lineA and lineB.
  static MetroStation? findInterchange(KolkataMetroLine lineA, KolkataMetroLine lineB) {
    for (final s in MetroRepository.allStations) {
      final servesA = s.line == lineA || s.connectingLines.contains(lineA);
      final servesB = s.line == lineB || s.connectingLines.contains(lineB);
      if (s.isInterchange && servesA && servesB) return s;
    }
    return null; // single interchange scope
  }
}
