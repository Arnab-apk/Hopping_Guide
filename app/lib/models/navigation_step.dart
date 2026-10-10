/// A provider maneuver anchored to the full route geometry.
class NavigationStep {
  const NavigationStep({
    required this.instruction,
    required this.pointIndex,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.type,
    this.modifier,
    this.roadName = '',
    this.legIndex = 0,
    this.exit,
  });
  final String instruction;
  final int pointIndex;
  final double distanceMeters;
  final double durationSeconds;
  final String type;
  final String? modifier;
  final String roadName;
  final int legIndex;
  final int? exit;

  NavigationStep withPointIndex(int index, {int legOffset = 0}) =>
      NavigationStep(
        instruction: instruction,
        pointIndex: index,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        type: type,
        modifier: modifier,
        roadName: roadName,
        legIndex: legIndex + legOffset,
        exit: exit,
      );
}
