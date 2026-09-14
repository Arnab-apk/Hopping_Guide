import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/custom_hopping_trail_service.dart';
import 'services/location_service.dart';
import 'services/notification_progress_service.dart';
import 'services/pandal_user_state_service.dart';
import 'services/squad_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with generated options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  // Initialize persistent user preferences, auth, theme, squad, notifications, and device location service
  final authService = await AuthService.create();
  final userStateService = await PandalUserStateService.create();
  final themeService = await ThemeService.create();
  final squadService = await SquadService.create();
  final locationService = LocationService();
  final trailService = CustomHoppingTrailService.instance..attachUserStateService(userStateService);

  // Initialize notifications
  NotificationProgressService.instance.initialize();

  // Proactively fetch device location if permitted
  locationService.updateLiveLocation();

  // Handle deep links for squad invites
  _initDeepLinks(squadService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<PandalUserStateService>.value(value: userStateService),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
        ChangeNotifierProvider<LocationService>.value(value: locationService),
        ChangeNotifierProvider<SquadService>.value(value: squadService),
        ChangeNotifierProvider<CustomHoppingTrailService>.value(value: trailService),
      ],
      child: const KolkataPujaApp(),
    ),
  );
}

/// Initialize deep link handling for squad invite links.
/// Supports both https://sharodiya.com/join?code=PUJAXXXX and pujoparikrama://join?code=PUJAXXXX
void _initDeepLinks(SquadService squadService) {
  final appLinks = AppLinks();

  // Handle initial link if app was opened via deep link (cold start)
  appLinks.getInitialLink().then((uri) {
    if (uri != null) {
      _handleDeepLink(uri, squadService);
    }
  }).catchError((e) {
    debugPrint('Deep link initial error: $e');
  });

  // Handle incoming links while app is running (hot start)
  appLinks.uriLinkStream.listen((uri) {
    _handleDeepLink(uri, squadService);
  }, onError: (e) {
    debugPrint('Deep link stream error: $e');
  });
}

/// Process incoming deep link URI and auto-join squad if code is present.
void _handleDeepLink(Uri uri, SquadService squadService) {
  debugPrint('Deep link received: $uri');
  
  // Check for /join path and code parameter
  if (uri.path == '/join' || uri.path == 'join') {
    final code = uri.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      final cleanCode = code.toUpperCase().trim();
      debugPrint('Auto-joining squad with code: $cleanCode');
      
      // Only join if not already in a squad
      if (!squadService.hasActiveSquad) {
        squadService.joinSquad(cleanCode);
        debugPrint('Successfully joined squad: $cleanCode');
      } else {
        debugPrint('User already in a squad, skipping auto-join');
      }
    }
  }
}

/// Firebase is now configured via flutterfire configure.
const bool kFirebaseConfigured = true;
