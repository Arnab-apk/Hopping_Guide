import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/repositories/station_repository.dart';
import 'package:kolkata_puja/screens/return_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final dark in [false, true]) {
    for (final size in [const Size(375, 812), const Size(812, 375)]) {
      testWidgets('return planner fits $size dark=$dark at large text', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(() => StationRepository.instance.load());
        await tester.runAsync(() async {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: const ReturnHomeScreen(),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 150));
        });
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Home station'), 150);
        expect(find.text('Home station'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(find.text('Save and plan return'), 200);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        await tester.scrollUntilVisible(
          find.textContaining('Schedule unverified'),
          150,
        );
        expect(find.textContaining('Schedule unverified'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
