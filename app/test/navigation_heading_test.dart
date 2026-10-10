import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/utils/navigation_heading.dart';

void main() {
  test('compass facing overrides GPS course, including when stationary', () {
    expect(
      navigationHeading(compass: 90, compassFresh: true, gps: 0, speed: 0),
      90,
    );
    expect(
      navigationHeading(compass: -90, compassFresh: true, gps: 0, speed: 2),
      270,
    );
    expect(
      navigationHeading(compass: 90, compassFresh: false, gps: 20, speed: 0),
      isNull,
    );
    expect(
      navigationHeading(
        compass: double.nan,
        compassFresh: true,
        gps: 20,
        speed: 2,
      ),
      20,
    );
    expect(navigationHeading(compassFresh: false, gps: -1, speed: 2), isNull);
  });
  test('north crossing takes the shortest rotation', () {
    expect(shortestHeadingTurn(359, 1), 2);
    expect(shortestHeadingTurn(1, 359), -2);
    expect(shortestHeadingTurn(0, -90), -90);
  });
}
