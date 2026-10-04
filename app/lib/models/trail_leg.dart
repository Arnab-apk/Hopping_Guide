import 'package:latlong2/latlong.dart';
import '../repositories/railway_repository.dart';
import '../services/metro_transit_estimator.dart';
import '../utils/haversine.dart';

/// Transport mode used for a particular leg of a hopping trail.
enum LegMode { walk, metro, train }

/// Detailed breakdown of an estimated suburban train-assisted transit leg.
class TrainLegEstimate {
  const TrainLegEstimate({
    required this.totalMinutes,
    required this.boardingStation,
    required this.alightingStation,
    required this.corridorName,
    required this.stationCount,
    required this.trackPoints,
  });

  final double totalMinutes;
  final RailwayStationInfo boardingStation;
  final RailwayStationInfo alightingStation;
  final String corridorName;
  final int stationCount;
  final List<LatLng> trackPoints;
}

/// Represents an individual leg between two consecutive stops or waypoints on a trail.
class TrailLeg {
  const TrailLeg({
    required this.from,
    required this.to,
    required this.mode,
    this.metroDetail,
    this.trainDetail,
    this.roadPolyline,
  });

  final LatLng from;
  final LatLng to;
  final LegMode mode;
  final MetroLegEstimate? metroDetail;
  final TrainLegEstimate? trainDetail;
  final List<LatLng>? roadPolyline;

  bool get isMetro => mode == LegMode.metro;
  bool get isWalk => mode == LegMode.walk;
  bool get isTrain => mode == LegMode.train;

  double get distanceKm {
    if (isMetro && metroDetail != null) {
      final detail = metroDetail!;
      final walkAccessKm = (haversineMeters(
                from.latitude,
                from.longitude,
                detail.boardingStation.latitude,
                detail.boardingStation.longitude,
              ) +
              haversineMeters(
                to.latitude,
                to.longitude,
                detail.alightingStation.latitude,
                detail.alightingStation.longitude,
              )) /
          1000.0;
      final metroTrackKm = haversineMeters(
            detail.boardingStation.latitude,
            detail.boardingStation.longitude,
            detail.alightingStation.latitude,
            detail.alightingStation.longitude,
          ) /
          1000.0;
      return double.parse((walkAccessKm + metroTrackKm).toStringAsFixed(2));
    }
    if (isTrain && trainDetail != null) {
      final detail = trainDetail!;
      final walkToKm = haversineMeters(
            from.latitude,
            from.longitude,
            detail.boardingStation.latitude,
            detail.boardingStation.longitude,
          ) /
          1000.0;
      final walkFromKm = haversineMeters(
            to.latitude,
            to.longitude,
            detail.alightingStation.latitude,
            detail.alightingStation.longitude,
          ) /
          1000.0;
      final railTrackKm = haversineMeters(
            detail.boardingStation.latitude,
            detail.boardingStation.longitude,
            detail.alightingStation.latitude,
            detail.alightingStation.longitude,
          ) /
          1000.0;
      return double.parse((walkToKm + railTrackKm + walkFromKm).toStringAsFixed(2));
    }
    return double.parse(
      ((haversineMeters(from.latitude, from.longitude, to.latitude, to.longitude) * 1.25) / 1000.0)
          .toStringAsFixed(2),
    );
  }

  TrailLeg copyWith({
    LatLng? from,
    LatLng? to,
    LegMode? mode,
    MetroLegEstimate? metroDetail,
    TrainLegEstimate? trainDetail,
    List<LatLng>? roadPolyline,
  }) {
    return TrailLeg(
      from: from ?? this.from,
      to: to ?? this.to,
      mode: mode ?? this.mode,
      metroDetail: metroDetail ?? this.metroDetail,
      trainDetail: trainDetail ?? this.trainDetail,
      roadPolyline: roadPolyline ?? this.roadPolyline,
    );
  }
}

/// Helper estimator for suburban train transit between coordinates.
class TrainTransitEstimator {
  static TrainLegEstimate? estimate(
    LatLng from,
    LatLng to, {
    double walkingSpeedKmH = 4.5,
  }) {
    final directKm = haversineMeters(from.latitude, from.longitude, to.latitude, to.longitude) / 1000.0;
    if (directKm < 1.5) return null;

    final boardingRail = RailwayRepository.instance.findNearestStation(from, maxDistanceKm: 2.0);
    final alightingRail = RailwayRepository.instance.findNearestStation(to, maxDistanceKm: 2.0);

    if (boardingRail != null && alightingRail != null && boardingRail.code != alightingRail.code) {
      final path = RailwayRepository.instance.computeTrainPath(boardingRail, alightingRail);
      if (path != null) {
        final walkToKm = haversineMeters(
              from.latitude,
              from.longitude,
              boardingRail.latitude,
              boardingRail.longitude,
            ) /
            1000.0;
        final walkFromKm = haversineMeters(
              to.latitude,
              to.longitude,
              alightingRail.latitude,
              alightingRail.longitude,
            ) /
            1000.0;
        final walkAccessMinutes = ((walkToKm + walkFromKm) / walkingSpeedKmH) * 60.0;
        final trainMinutes = (path.totalDurationSeconds / 60.0) + walkAccessMinutes;

        return TrainLegEstimate(
          totalMinutes: trainMinutes,
          boardingStation: boardingRail,
          alightingStation: alightingRail,
          corridorName: path.corridorName,
          stationCount: path.stationCount,
          trackPoints: path.trackPoints,
        );
      }
    }
    return null;
  }
}

/// Reconstructs the leg breakdown (comparing road walk vs metro vs suburban train)
/// for an ordered sequence of points, picking the shortest and most optimal mode.
List<TrailLeg> buildLegBreakdown(
  List<LatLng> orderedPoints, {
  required bool allowMetro,
  bool allowTrain = true,
  required double walkingSpeedKmH,
  double circuityFactor = 1.25,
}) {
  final legs = <TrailLeg>[];
  if (orderedPoints.length < 2) return legs;

  final speedMPerMin = (walkingSpeedKmH * 1000.0) / 60.0;

  for (int i = 0; i < orderedPoints.length - 1; i++) {
    final a = orderedPoints[i];
    final b = orderedPoints[i + 1];

    // 1. Walk estimate
    final walkDistM = haversineMeters(
          a.latitude,
          a.longitude,
          b.latitude,
          b.longitude,
        ) *
        circuityFactor;
    final walkMinutes = walkDistM / speedMPerMin;

    // 2. Metro estimate
    final metro = allowMetro
        ? MetroTransitEstimator.estimate(a, b, walkingSpeedKmH: walkingSpeedKmH)
        : null;

    // 3. Train estimate (Eastern / South Eastern / Circular Railway)
    final train = (allowTrain || allowMetro)
        ? TrainTransitEstimator.estimate(a, b, walkingSpeedKmH: walkingSpeedKmH)
        : null;

    // 4. Compare and select the best shortest/fastest mode
    if (train != null &&
        train.totalMinutes < walkMinutes &&
        (metro == null || train.totalMinutes <= metro.totalMinutes)) {
      legs.add(
        TrailLeg(
          from: a,
          to: b,
          mode: LegMode.train,
          trainDetail: train,
        ),
      );
    } else if (metro != null && metro.totalMinutes < walkMinutes) {
      legs.add(
        TrailLeg(
          from: a,
          to: b,
          mode: LegMode.metro,
          metroDetail: metro,
        ),
      );
    } else {
      legs.add(
        TrailLeg(
          from: a,
          to: b,
          mode: LegMode.walk,
        ),
      );
    }
  }
  return legs;
}
