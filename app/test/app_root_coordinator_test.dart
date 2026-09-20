import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/preload_state.dart';
import 'package:kolkata_puja/screens/app_root_coordinator.dart';
import 'package:kolkata_puja/screens/greeting_splash_screen.dart';
import 'package:kolkata_puja/screens/main_navigation_screen.dart';
import 'package:kolkata_puja/services/auth_service.dart';
import 'package:kolkata_puja/services/custom_hopping_trail_service.dart';
import 'package:kolkata_puja/services/enhanced_navigation_service.dart';
import 'package:kolkata_puja/services/location_service.dart';
import 'package:kolkata_puja/services/offline_map_service.dart';
import 'package:kolkata_puja/services/pandal_user_state_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestApp({
  required Widget home,
  required AuthService authService,
  required PandalUserStateService userStateService,
  required ThemeService themeService,
  required SquadService squadService,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>.value(value: authService),
      ChangeNotifierProvider<PandalUserStateService>.value(value: userStateService),
      ChangeNotifierProvider<ThemeService>.value(value: themeService),
      ChangeNotifierProvider<LocationService>.value(value: LocationService()),
      ChangeNotifierProvider<SquadService>.value(value: squadService),
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
    child: MaterialApp(home: home),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService authService;
  late PandalUserStateService userStateService;
  late ThemeService themeService;
  late SquadService squadService;

  group('AppRootCoordinator Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'tutorial_seen': true});
      authService = await AuthService.create();
      userStateService = await PandalUserStateService.create();
      themeService = await ThemeService.create();
      squadService = await SquadService.create();
    });

    testWidgets('mounts MainNavigationScreen and GreetingSplashScreen simultaneously',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          home: const AppRootCoordinator(
            minDuration: Duration(milliseconds: 300),
          ),
          authService: authService,
          userStateService: userStateService,
          themeService: themeService,
          squadService: squadService,
        ),
      );

      // Both splash and navigation screen are mounted in widget tree from frame zero
      expect(find.byType(GreetingSplashScreen), findsOneWidget);
      expect(find.byType(MainNavigationScreen), findsOneWidget);

      // Advance through preload duration and crossfade
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump(const Duration(milliseconds: 700));
    });

    testWidgets('testSkipPreload immediately reveals MainNavigationScreen without pop-in',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          home: const AppRootCoordinator(
            testSkipPreload: true,
          ),
          authService: authService,
          userStateService: userStateService,
          themeService: themeService,
          squadService: squadService,
        ),
      );

      await tester.pump();

      // Directly reveals MainNavigationScreen
      expect(find.byType(MainNavigationScreen), findsOneWidget);

      // Settle background timers
      await tester.pump(const Duration(milliseconds: 700));
    });

    test('PreloadState models progress and status correctly', () {
      const state1 = PreloadState(progress: 0.15, statusMessage: 'Loading pandals near you...');
      expect(state1.progress, 0.15);
      expect(state1.statusMessage, 'Loading pandals near you...');

      final state2 = state1.copyWith(progress: 0.45, statusMessage: 'Preparing the map...');
      expect(state2.progress, 0.45);
      expect(state2.statusMessage, 'Preparing the map...');
    });
  });
}
