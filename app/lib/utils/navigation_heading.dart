/// Signed shortest turn, including crossing north (359 -> 1 degrees).
double shortestHeadingTurn(double from, double to) =>
    (to - from + 180) % 360 - 180;

/// Compass measures facing direction; GPS measures course only while moving.
double? navigationHeading({
  double? compass,
  required bool compassFresh,
  double? gps,
  required double speed,
}) {
  if (compassFresh && compass != null && compass.isFinite) return compass % 360;
  if (gps != null && gps.isFinite && gps >= 0 && speed > 1.5) return gps % 360;
  return null;
}
