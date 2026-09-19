import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kolkata_puja/screens/main_navigation_screen.dart';
import 'package:kolkata_puja/screens/splash_screen.dart';
import 'package:kolkata_puja/screens/welcome_screen.dart';
import 'package:kolkata_puja/services/auth_service.dart';
import 'package:kolkata_puja/services/custom_hopping_trail_service.dart';
import 'package:kolkata_puja/services/enhanced_navigation_service.dart';
import 'package:kolkata_puja/services/location_service.dart';
import 'package:kolkata_puja/services/offline_map_service.dart';
import 'package:kolkata_puja/services/pandal_user_state_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PandalUserStateService userStateService;
  late ThemeService themeService;

  Widget createTestApp({
    required Widget home,
    required AuthService authService,
    SquadService? squadService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<PandalUserStateService>.value(
          value: userStateService,
        ),
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
        ),
        ChangeNotifierProvider<LocationService>.value(
          value: LocationService(),
        ),
        ChangeNotifierProvider<SquadService>.value(
          value: squadService ?? SquadService.instance,
        ),
        ChangeNotifierProvider<CustomHoppingTrailService>.value(
          value: CustomHoppingTrailService.instance,
        ),
        ChangeNotifierProvider<EnhancedNavigationService>.value(
          value: EnhancedNavigationService.instance,
        ),
        ChangeNotifierProvider<OfflineMapService>.value(
          value: OfflineMapService.instance,
        ),
      ],
      child: MaterialApp(
        home: home,
        routes: {
          '/main': (context) => const MainNavigationScreen(),
          '/welcome': (context) => const WelcomeScreen(),
        },
      ),
    );
  }

  group('SplashScreen Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userStateService = await PandalUserStateService.create();
      themeService = await ThemeService.create();
      await AuthService.create();
      await AuthService.instance.signOut();
    });

    testWidgets('renders full-bleed splash illustration asset', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authService = AuthService.instance;

      await tester.pumpWidget(
        createTestApp(
          home: const SplashScreen(minDuration: Duration(milliseconds: 100)),
          authService: authService,
        ),
      );

      // Verify Image.asset with splash_illustration.webp exists
      final imageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/splash_illustration.webp',
      );
      expect(imageFinder, findsOneWidget);

      // Verify BoxFit.cover is used for full-bleed
      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.fit, BoxFit.cover);

      // Drain timer before test completion
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
    });

    testWidgets('unauthenticated user navigates to WelcomeScreen after minDuration',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authService = AuthService.instance;
      expect(authService.isAuthenticated, isFalse);

      await tester.pumpWidget(
        createTestApp(
          home: const SplashScreen(minDuration: Duration(milliseconds: 100)),
          authService: authService,
        ),
      );

      // Initially on SplashScreen
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);

      // Advance clock past minimum duration
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Navigates to WelcomeScreen
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('authenticated user bypasses login and navigates to MainNavigationScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({'tutorial_seen': true});
      final authService = await AuthService.create();
      await authService.signInAsGuest();
      expect(authService.isAuthenticated, isTrue);

      await tester.pumpWidget(
        createTestApp(
          home: const SplashScreen(minDuration: Duration(milliseconds: 100)),
          authService: authService,
        ),
      );

      // Initially on SplashScreen
      expect(find.byType(SplashScreen), findsOneWidget);

      // Advance clock past minimum duration and tutorial delay
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 700));

      // Directly navigates to MainNavigationScreen (skips WelcomeScreen!)
      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    });
  });

  group('WelcomeScreen / LoginScreen Background Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userStateService = await PandalUserStateService.create();
      themeService = await ThemeService.create();
      await AuthService.create();
    });

    testWidgets('renders login_bg_eyes.webp with defensive scrim and safe zones',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authService = AuthService.instance;

      await tester.pumpWidget(
        createTestApp(
          home: const WelcomeScreen(),
          authService: authService,
        ),
      );

      // Advance animations
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1500));

      // 1. Verify Image.asset with login_bg_eyes.webp
      final bgFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/login_bg_eyes.webp',
      );
      expect(bgFinder, findsOneWidget);

      final bgWidget = tester.widget<Image>(bgFinder);
      expect(bgWidget.fit, BoxFit.cover);

      // 2. Verify Title and Countdown in upper zone
      expect(find.text('Durga Puja'), findsOneWidget);
      expect(find.text('Uma'), findsOneWidget);
      expect(find.text('DAYS'), findsOneWidget);
      expect(find.text('HOURS'), findsOneWidget);

      // 3. Verify Login Card in lower dark band
      expect(find.text('Begin Your Parikrama'), findsOneWidget);
      expect(find.text('Enter as Guest'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Offline First • Zero Friction • Instant Access'), findsOneWidget);
    });

    testWidgets('LoginScreen alias points to WelcomeScreen', (tester) async {
      const LoginScreen screen = WelcomeScreen();
      expect(screen, isA<WelcomeScreen>());
    });
  });
}
