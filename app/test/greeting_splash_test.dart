import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/screens/greeting_splash_screen.dart';
import 'package:kolkata_puja/utils/puja_schedule.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Puja day detection', () {
    final testCases = <(DateTime, String?)>[
      (DateTime(2026, 10, 9), null), // day before Mahalaya
      (DateTime(2026, 10, 10), 'Mahalaya'),
      (DateTime(2026, 10, 11), 'Pratipada'),
      (DateTime(2026, 10, 12), 'Dwitiya'),
      (DateTime(2026, 10, 13), 'Tritiya'),
      (DateTime(2026, 10, 14), 'Maha Chaturthi'),
      (DateTime(2026, 10, 15), 'Maha Panchami'),
      (DateTime(2026, 10, 16), 'Maha Shashthi'),
      (DateTime(2026, 10, 17), 'Maha Saptami'),
      (DateTime(2026, 10, 18), 'Maha Saptami'), // second day of Saptami, per the schedule image
      (DateTime(2026, 10, 19), 'Maha Ashtami'), // includes Sandhi Puja, folded into this single day
      (DateTime(2026, 10, 20), 'Maha Navami'),
      (DateTime(2026, 10, 21), 'Vijaya Dashami'),
      (DateTime(2026, 10, 22), null), // day after Dashami
    ];

    for (final (date, expectedName) in testCases) {
      test('${date.toIso8601String().split("T").first} → $expectedName', () {
        AppClock.debugSetOverride(date);
        expect(getTodaysPujaDay()?.name, expectedName);
      });
    }

    tearDown(() => AppClock.debugSetOverride(null));
  });

  group('Greeting string generation', () {
    tearDown(() => AppClock.debugSetOverride(null));

    test('builds pre-Mahalaya countdown greeting on Oct 9', () {
      AppClock.debugSetOverride(DateTime(2026, 10, 9));
      final day = getTodaysPujaDay();
      expect(day, isNull);
      final greeting = buildGreeting(day, 'Arnab');
      expect(greeting, 'Welcome back, Arnab — 1 days to Mahalaya');
    });

    test('builds Mahalaya greeting on Oct 10', () {
      AppClock.debugSetOverride(DateTime(2026, 10, 10));
      final day = getTodaysPujaDay();
      expect(day?.name, 'Mahalaya');
      final greeting = buildGreeting(day, 'Arnab');
      expect(greeting, 'Shubho Mahalaya, Arnab');
    });

    test('builds Maha Shashthi greeting with Bodhon subtitle on Oct 16', () {
      AppClock.debugSetOverride(DateTime(2026, 10, 16));
      final day = getTodaysPujaDay();
      expect(day?.name, 'Maha Shashthi');
      expect(day?.subtitle, 'Bodhon');
      final greeting = buildGreeting(day, 'Arnab');
      expect(greeting, 'Shubho Maha Shashthi (Bodhon), Arnab');
    });

    test('builds Maha Saptami greeting on Oct 17 and Oct 18', () {
      AppClock.debugSetOverride(DateTime(2026, 10, 17));
      expect(buildGreeting(getTodaysPujaDay(), 'Arnab'), 'Shubho Maha Saptami, Arnab');

      AppClock.debugSetOverride(DateTime(2026, 10, 18));
      expect(buildGreeting(getTodaysPujaDay(), 'Arnab'), 'Shubho Maha Saptami, Arnab');
    });

    test('builds Maha Ashtami greeting on Oct 19', () {
      AppClock.debugSetOverride(DateTime(2026, 10, 19));
      final day = getTodaysPujaDay();
      expect(day?.name, 'Maha Ashtami');
      expect(buildGreeting(day, 'Arnab'), 'Shubho Maha Ashtami, Arnab');
    });

    test('builds Vijaya Dashami greeting on Oct 21', () {
      AppClock.debugSetOverride(DateTime(2026, 10, 21));
      final day = getTodaysPujaDay();
      expect(day?.name, 'Vijaya Dashami');
      expect(buildGreeting(day, 'Arnab'), 'Shubho Vijaya Dashami, Arnab');
    });

    test('builds post-festival farewell greeting on Oct 22', () {
      AppClock.debugSetOverride(DateTime(2026, 10, 22));
      final day = getTodaysPujaDay();
      expect(day, isNull);
      final greeting = buildGreeting(day, 'Arnab');
      expect(greeting, 'Welcome back, Arnab — see you next Durga Puja!');
    });

    test('falls back to "Pujo Hopper" when user name is blank', () {
      AppClock.debugSetOverride(DateTime(2026, 10, 10));
      final greeting = buildGreeting(getTodaysPujaDay(), '');
      expect(greeting, 'Shubho Mahalaya, Pujo Hopper');
    });
  });

  group('GreetingSplashScreen Widget', () {
    tearDown(() => AppClock.debugSetOverride(null));

    testWidgets('renders daily greeting and cultural description', (tester) async {
      AppClock.debugSetOverride(DateTime(2026, 10, 16)); // Maha Shashthi (Bodhon)

      await tester.pumpWidget(
        const MaterialApp(
          home: GreetingSplashScreen(
            minDisplayDuration: Duration(milliseconds: 5000),
          ),
        ),
      );

      // Verify entrance animation forward
      await tester.pump(const Duration(milliseconds: 400));

      // Check Bengali banner
      expect(find.text('শারদীয়া দুর্গোৎসব ২০২৬'), findsOneWidget);

      // Check greeting text for Maha Shashthi
      expect(find.textContaining('Shubho Maha Shashthi (Bodhon)'), findsOneWidget);

      // Check description
      expect(
        find.textContaining("The formal festival kickoff — Bodhon unveils the idol's face."),
        findsOneWidget,
      );

      // Finish remaining time
      await tester.pump(const Duration(milliseconds: 1000));
    });

    testWidgets('calls onNavigate after minDisplayDuration expires', (tester) async {
      AppClock.debugSetOverride(DateTime(2026, 10, 19)); // Maha Ashtami
      bool navigated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: GreetingSplashScreen(
            minDisplayDuration: const Duration(milliseconds: 500),
            onNavigate: () => navigated = true,
          ),
        ),
      );

      expect(navigated, isFalse);

      // Advance past minDisplayDuration
      await tester.pump(const Duration(milliseconds: 600));

      expect(navigated, isTrue);
    });

    testWidgets('navigates immediately when screen is tapped', (tester) async {
      AppClock.debugSetOverride(DateTime(2026, 10, 10));
      bool navigated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: GreetingSplashScreen(
            minDisplayDuration: const Duration(milliseconds: 3000),
            onNavigate: () => navigated = true,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(navigated, isFalse);

      // Tap screen to skip
      await tester.tap(find.byType(GreetingSplashScreen));
      await tester.pump();

      expect(navigated, isTrue);
    });
  });
}
