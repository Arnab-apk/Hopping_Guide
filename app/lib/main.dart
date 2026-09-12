import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/location_service.dart';
import 'services/pandal_user_state_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent user preferences & device location service
  final userStateService = await PandalUserStateService.create();
  final locationService = LocationService();

  // Proactively fetch device location if permitted
  locationService.updateLiveLocation();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PandalUserStateService>.value(value: userStateService),
        ChangeNotifierProvider<LocationService>.value(value: locationService),
      ],
      child: const KolkataPujaApp(),
    ),
  );
}

/// Toggle this to true once Firebase is configured.
const bool kFirebaseConfigured = false;
