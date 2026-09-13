import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/config/theme.dart';
import 'package:kolkata_puja/models/app_user.dart';
import 'package:kolkata_puja/services/auth_service.dart';
import 'package:kolkata_puja/widgets/animated_fade_slide.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnimatedFadeSlide Widget Tests', () {
    testWidgets('renders child widget and animates fade and slide', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedFadeSlide(
              child: Text('Animated Pandal Card'),
            ),
          ),
        ),
      );

      // Verify child is rendered
      expect(find.text('Animated Pandal Card'), findsOneWidget);

      // Advance animation timer
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Animated Pandal Card'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Animated Pandal Card'), findsOneWidget);
    });

    testWidgets('respects custom delay before animating', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedFadeSlide(
              delay: Duration(milliseconds: 100),
              child: Text('Delayed Card'),
            ),
          ),
        ),
      );

      // At t=0, opacity is 0.0
      expect(find.text('Delayed Card'), findsOneWidget);

      // Advance past delay
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('Delayed Card'), findsOneWidget);
    });
  });

  group('AuthService and AuthResult Tests', () {
    test('guest sign in sets active user model correctly', () async {
      final user = await AuthService.instance.signInAsGuest();
      expect(user.isGuest, true);
      expect(user.displayName, 'Guest Pujo Hopper');
      expect(AuthService.instance.isAuthenticated, true);
      expect(AuthService.instance.currentUserModel?.isGuest, true);
    });

    test('AuthResult types instantiate correctly', () {
      final guest = AppUser.guest();
      final success = AuthResult.success(guest);
      expect(success.success, true);
      expect(success.isCancelled, false);
      expect(success.user, guest);

      const cancelled = AuthResult.cancelled();
      expect(cancelled.success, false);
      expect(cancelled.isCancelled, true);
      expect(cancelled.user, null);

      const failure = AuthResult.failure('Network timeout');
      expect(failure.success, false);
      expect(failure.isCancelled, false);
      expect(failure.errorMessage, 'Network timeout');
    });
  });

  group('Theme Page Transitions Tests', () {
    test('theme includes modern PredictiveBackPageTransitionsBuilder for Android', () {
      final darkBuilders = appDarkTheme.pageTransitionsTheme.builders;
      expect(darkBuilders[TargetPlatform.android], isA<PredictiveBackPageTransitionsBuilder>());
      expect(darkBuilders[TargetPlatform.iOS], isA<CupertinoPageTransitionsBuilder>());

      final lightBuilders = appTheme.pageTransitionsTheme.builders;
      expect(lightBuilders[TargetPlatform.android], isA<PredictiveBackPageTransitionsBuilder>());
    });
  });
}
