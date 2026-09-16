import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/gemkit_config.dart';
import 'firebase_options.dart';
import 'screens/main_navigation_screen.dart';
import 'services/auth_service.dart';
import 'services/custom_hopping_trail_service.dart';
import 'services/enhanced_navigation_service.dart';
import 'services/location_service.dart';
import 'services/notification_progress_service.dart';
import 'services/offline_map_service.dart';
import 'services/pandal_user_state_service.dart';
import 'services/squad_service.dart';
import 'services/theme_service.dart';
import 'services/voice_navigation_service.dart';

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';

/// Global navigator key allowing deep links to navigate without context dependency
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Pending deep link received prior to navigator readiness (cold-starts)
Uri? _pendingDeepLink;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Magic Lane GemKit SDK (if available and configured)
  await _initializeGemKit();

  // Initialize enhanced navigation services
  await _initializeEnhancedServices();

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

  // Handle deep links for squad invites and pandal sharing
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
        ChangeNotifierProvider<EnhancedNavigationService>.value(
          value: EnhancedNavigationService.instance,
        ),
        ChangeNotifierProvider<OfflineMapService>.value(
          value: OfflineMapService.instance,
        ),
      ],
      child: KolkataPujaApp(navigatorKey: rootNavigatorKey),
    ),
  );

  // Flush any pending cold-start deep link once initial frame is rendered
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _processPendingDeepLink(squadService);
  });
}

/// Initialize deep link handling for squad invite links and pandal details.
/// Supports:
/// - pujoparikrama://join?code=PUJAXXXX
/// - pujoparikrama://join/PUJAXXXX
/// - https://sharodiya.com/join?code=PUJAXXXX
/// - https://sharodiya.com/join/PUJAXXXX
/// - pujoparikrama://pandal?id=X
/// - https://sharodiya.com/pandal/X
void _initDeepLinks(SquadService squadService) {
  final appLinks = AppLinks();

  // Handle initial link if app was opened via deep link (cold start)
  appLinks.getInitialLink().then((uri) {
    if (uri != null) {
      debugPrint('[DeepLink] Initial cold-start URI: $uri');
      _handleDeepLink(uri, squadService);
    }
  }).catchError((e) {
    debugPrint('[DeepLink] Initial link error: $e');
  });

  // Handle incoming links while app is running (hot start / foreground stream)
  appLinks.uriLinkStream.listen((uri) {
    debugPrint('[DeepLink] Foreground stream URI: $uri');
    _handleDeepLink(uri, squadService);
  }, onError: (e) {
    debugPrint('[DeepLink] Stream error: $e');
  });
}

/// Process incoming deep link URI and execute appropriate flow
Future<void> _handleDeepLink(Uri uri, SquadService squadService) async {
  debugPrint('[DeepLink] Processing URI: $uri (host: "${uri.host}", path: "${uri.path}")');

  // Check 1: Squad Invite Deep Link
  final squadCode = _extractSquadCode(uri);
  if (squadCode != null) {
    debugPrint('[DeepLink] Extracted squad code: $squadCode');

    // Ensure user session exists before joining
    if (AuthService.instance.currentUserModel == null) {
      await AuthService.instance.signInAsGuest();
    }

    final success = await squadService.joinSquadFromDeepLink(squadCode);

    void navigateToSquadTab() {
      final nav = rootNavigatorKey.currentState;
      if (nav != null) {
        // Switch tab smoothly on MainNavigationScreen
        MainNavigationScreen.switchToTab(3);

        // Ensure user lands on MainNavigationScreen even if opened from WelcomeScreen
        nav.pushNamedAndRemoveUntil(
          '/main',
          (route) => false,
          arguments: {'tab': 3},
        );

        final ctx = nav.context;
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.group, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    success ? 'Joined Squad $squadCode!' : 'Squad $squadCode ready!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        _pendingDeepLink = uri;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigateToSquadTab();
    });
    return;
  }

  // Check 2: Pandal Sharing Deep Link
  final pandalId = _extractPandalId(uri);
  if (pandalId != null) {
    debugPrint('[DeepLink] Extracted pandal ID: $pandalId');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = rootNavigatorKey.currentState;
      if (nav != null) {
        nav.pushNamed('/detail', arguments: pandalId);
      } else {
        _pendingDeepLink = uri;
      }
    });
    return;
  }
}

void _processPendingDeepLink(SquadService squadService) {
  if (_pendingDeepLink != null && rootNavigatorKey.currentState != null) {
    final link = _pendingDeepLink!;
    _pendingDeepLink = null;
    _handleDeepLink(link, squadService);
  }
}

/// Extract squad invite code from varied deep link formats:
/// - pujoparikrama://join?code=PUJAXXXX
/// - pujoparikrama://join/PUJAXXXX
/// - https://sharodiya.com/join?code=PUJAXXXX
/// - https://sharodiya.com/join/PUJAXXXX
String? _extractSquadCode(Uri uri) {
  // Query parameter: ?code=PUJAXXXX
  final codeParam = uri.queryParameters['code'];
  if (codeParam != null && codeParam.trim().isNotEmpty) {
    return codeParam.trim().toUpperCase();
  }

  final segments = uri.pathSegments;
  if (segments.isNotEmpty) {
    if (segments.first.toLowerCase() == 'join' && segments.length > 1) {
      return segments[1].trim().toUpperCase();
    }
    if (uri.host.toLowerCase() == 'join' && segments.length == 1) {
      return segments.first.trim().toUpperCase();
    }
  }

  return null;
}

/// Extract pandal ID from deep links:
/// - pujoparikrama://pandal?id=X
/// - pujoparikrama://pandal/X
/// - https://sharodiya.com/pandal?id=X
/// - https://sharodiya.com/pandal/X
String? _extractPandalId(Uri uri) {
  final idParam = uri.queryParameters['id'] ?? uri.queryParameters['pandalId'];
  if (idParam != null && idParam.trim().isNotEmpty) {
    return idParam.trim();
  }

  final segments = uri.pathSegments;
  if (segments.isNotEmpty) {
    if (segments.first.toLowerCase() == 'pandal' && segments.length > 1) {
      return segments[1].trim();
    }
    if (uri.host.toLowerCase() == 'pandal' && segments.length == 1) {
      return segments.first.trim();
    }
  }

  return null;
}

/// Firebase is now configured via flutterfire configure.
const bool kFirebaseConfigured = true;

/// Initialize Magic Lane GemKit SDK if available
/// 
/// This function safely initializes GemKit without breaking the app
/// if the SDK is not yet installed or configured.
Future<void> _initializeGemKit() async {
  try {
    // Check if API token is configured
    if (!GemKitConfig.isConfigured) {
      debugPrint('⚠ GemKit not configured: API token not found');
      debugPrint('   Set MAGIC_LANE_API_KEY environment variable to enable GemKit features');
      debugPrint('   Example: flutter run --dart-define=MAGIC_LANE_API_KEY=your_token');
      return;
    }

    await GemKit.initialize(appAuthorization: GemKitConfig.apiToken);
    debugPrint('✓ Magic Lane GemKit initialized successfully');
    debugPrint('  Map engine: Magic Lane Maps SDK');
    debugPrint('  Offline maps: ${GemKitConfig.enableOfflineMaps ? 'Enabled' : 'Disabled'}');
    debugPrint('  3D buildings: ${GemKitConfig.enable3DBuildings ? 'Enabled' : 'Disabled'}');
  } catch (e) {
    debugPrint('⚠ GemKit initialization note: $e');
  }
}

/// Initialize enhanced navigation services
/// 
/// Provides Magic Lane-like features using open-source alternatives:
/// - Turn-by-turn navigation
/// - Voice guidance
/// - Offline map caching
Future<void> _initializeEnhancedServices() async {
  try {
    // Initialize offline map service
    await OfflineMapService.instance.initialize();
    debugPrint('✓ Offline map service initialized');

    // Initialize voice navigation
    await VoiceNavigationService.instance.initialize();
    debugPrint('✓ Voice navigation initialized');

    debugPrint('✓ Enhanced navigation services ready');
    debugPrint('  Features: Turn-by-turn, Voice guidance, Offline maps');
  } catch (e) {
    debugPrint('⚠ Enhanced services initialization failed: $e');
  }
}
