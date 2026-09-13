import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/location_service.dart';
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

  // Initialize persistent user preferences, theme, squad and device location service
  final userStateService = await PandalUserStateService.create();
  final themeService = await ThemeService.create();
  final squadService = await SquadService.create();
  final locationService = LocationService();

  // Proactively fetch device location if permitted
  locationService.updateLiveLocation();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PandalUserStateService>.value(value: userStateService),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
        ChangeNotifierProvider<LocationService>.value(value: locationService),
        ChangeNotifierProvider<SquadService>.value(value: squadService),
      ],
      child: const KolkataPujaApp(),
    ),
  );
}

/// Firebase is now configured via flutterfire configure.
const bool kFirebaseConfigured = true;
