import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kolkata_puja/app.dart';
import 'package:kolkata_puja/screens/app_root_coordinator.dart';
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
  // Prevent google_fonts from making live network requests during tests.
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('App builds and shows welcome screen directly on first open without splash screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KolkataPujaApp());

    // Does NOT display the in-app splash screen before login
    expect(find.byType(SplashScreen), findsNothing);

    // Displays WelcomeScreen directly
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.textContaining('Uma'), findsOneWidget);
  });

  testWidgets('App remembers logged in user and directly opens AppRootCoordinator without login prompt', (tester) async {
    final savedGoogleUserJson = jsonEncode({
      'uid': 'google_123456789',
      'displayName': 'Arnab Test',
      'email': 'arnab@gmail.com',
      'photoUrl': 'https://lh3.googleusercontent.com/a/default-user=s288-c',
      'isGuest': false,
    });
    SharedPreferences.setMockInitialValues({
      'auth_saved_user': savedGoogleUserJson,
      'tutorial_seen': true,
    });

    final authService = await AuthService.create();
    final userStateService = await PandalUserStateService.create();
    final themeService = await ThemeService.create();
    final squadService = await SquadService.create();
    expect(authService.isAuthenticated, isTrue);
    expect(authService.isGoogleUser, isTrue);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: authService),
          ChangeNotifierProvider<PandalUserStateService>.value(value: userStateService),
          ChangeNotifierProvider<ThemeService>.value(value: themeService),
          ChangeNotifierProvider<LocationService>.value(value: LocationService()),
          ChangeNotifierProvider<SquadService>.value(value: squadService),
          ChangeNotifierProvider<CustomHoppingTrailService>.value(value: CustomHoppingTrailService.instance),
          ChangeNotifierProvider<EnhancedNavigationService>.value(value: EnhancedNavigationService.instance),
          ChangeNotifierProvider<OfflineMapService>.value(value: OfflineMapService.instance),
        ],
        child: const KolkataPujaApp(),
      ),
    );

    // Should NOT display WelcomeScreen or login prompt
    expect(find.byType(WelcomeScreen), findsNothing);

    // Displays AppRootCoordinator directly
    expect(find.byType(AppRootCoordinator), findsOneWidget);
  });
}

