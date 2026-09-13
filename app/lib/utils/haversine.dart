import 'dart:math' as math;

/// Haversine distance in meters between two lat/lng points.
/// Used for the "nearest pandals to me" sort (P0) — no external API needed
/// since the pandal list is our own curated dataset.
double haversineMeters(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const r = 6371000.0; // Earth radius (m)
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

/// Calculates forward bearing in degrees (0..360) from point 1 to point 2.
double calculateBearing(double lat1, double lng1, double lat2, double lng2) {
  final phi1 = _toRad(lat1);
  final phi2 = _toRad(lat2);
  final deltaLambda = _toRad(lng2 - lng1);

  final y = math.sin(deltaLambda) * math.cos(phi2);
  final x = math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

  final theta = math.atan2(y, x);
  return (theta * 180.0 / math.pi + 360.0) % 360.0;
}

double _toRad(double deg) => deg * math.pi / 180.0;

/// Human-readable distance for the UI (e.g. "850 m" or "1.2 km").
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}
