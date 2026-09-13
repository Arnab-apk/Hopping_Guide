import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kolkata_puja/widgets/app_tutorial_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AppTutorialDialog renders, navigates with Next/Previous, and finishes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppTutorialDialog(),
        ),
      ),
    );

    // Initial page: Step 1 (Interactive Puja Map)
    expect(find.textContaining('Tutorial • 1 of 5'), findsOneWidget);
    expect(find.text('Interactive Puja Map'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    // Previous button should not be shown on step 1
    expect(find.text('Previous'), findsNothing);

    // Tap Next -> Step 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tutorial • 2 of 5'), findsOneWidget);
    expect(find.text('Pandals Directory & Tracker'), findsOneWidget);
    // Previous button should now be visible
    expect(find.text('Previous'), findsOneWidget);

    // Tap Previous -> Step 1
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tutorial • 1 of 5'), findsOneWidget);
    expect(find.text('Interactive Puja Map'), findsOneWidget);

    // Navigate all the way to Step 5
    await tester.tap(find.text('Next')); // to Step 2
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next')); // to Step 3
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next')); // to Step 4
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next')); // to Step 5
    await tester.pumpAndSettle();

    expect(find.textContaining('Tutorial • 5 of 5'), findsOneWidget);
    expect(find.text('24/7 Emergency & Helplines'), findsOneWidget);
    expect(find.text('Finish & Explore'), findsOneWidget);

    // Tap Finish & Explore
    await tester.tap(find.text('Finish & Explore'));
    await tester.pumpAndSettle();

    // Verify preference is set
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_seen_app_tutorial_v1'), true);
  });

  testWidgets('AppTutorialDialog Skip button marks tutorial as seen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppTutorialDialog(),
        ),
      ),
    );

    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_seen_app_tutorial_v1'), true);
  });
}
