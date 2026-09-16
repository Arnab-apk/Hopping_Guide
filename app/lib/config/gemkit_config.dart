/// GemKit (Magic Lane SDK) Configuration
///
/// This file contains configuration constants and helpers for Magic Lane's GemKit SDK.
///
/// SECURITY WARNING:
/// - Never hardcode your API token in this file
/// - Always use environment variables or secure storage
/// - Add this file pattern to .gitignore if you add sensitive data
library;

import 'package:flutter/foundation.dart';

class GemKitConfig {
  GemKitConfig._(); // Private constructor to prevent instantiation

  /// Active map engine notifier: true = Magic Lane 3D map, false = 2D OSM FlutterMap
  static final ValueNotifier<bool> isMagicLaneActive = ValueNotifier<bool>(true);

  /// Toggle active map engine
  static void toggleMapEngine() {
    isMagicLaneActive.value = !isMagicLaneActive.value;
  }

  /// Get the Magic Lane API token from environment variables
  ///
  /// Usage:
  /// ```bash
  /// flutter run --dart-define=MAGIC_LANE_API_KEY=your_token_here
  /// ```
  static const String apiToken = String.fromEnvironment(
    'MAGIC_LANE_API_KEY',
    defaultValue: 'mldl_pkRREpVdKjS0XOurTgzjY1G72PaNg37V0By0H2NCop1',
  );

  /// Check if API token is configured
  static bool get isConfigured => apiToken.isNotEmpty;

  /// Default map center (Kolkata)
  static const double defaultLatitude = 22.5726;
  static const double defaultLongitude = 88.3639;
  static const double defaultZoom = 12.0;

  /// Map styling preferences
  static const bool enableDarkMode = false;
  static const bool enable3DBuildings = true;
  static const bool enableTraffic = false;

  /// Performance settings
  static const int markerClusterRadius = 50; // pixels
  static const int maxMarkersBeforeClustering = 100;
  static const bool enableOfflineMaps = true;

  /// Navigation preferences
  static const double walkingSpeedKmH = 4.5; // Kolkata walking pace
  static const double circuityFactor = 1.25; // Urban street circuity
  static const bool avoidTolls = true;
  static const bool avoidHighways = false;

  /// Route display settings
  static const double routeLineWidth = 5.0;
  static const int routeLineColor = 0xFF800020; // Crimson Velvet
  static const double routeLineOpacity = 0.8;

  /// Error messages
  static const String errorNoApiToken =
      'Magic Lane API token not found. Please set MAGIC_LANE_API_KEY environment variable.';
  static const String errorSdkNotAvailable =
      'GemKit SDK not available. Please obtain the SDK from Magic Lane International B.V.';
  static const String errorInitializationFailed =
      'Failed to initialize GemKit. Please check your API token and network connection.';

  /// Feature flags
  static const bool useGemKitMap = true; // Set to true after SDK integration
  static const bool useFallbackFlutterMap =
      true; // Fallback to flutter_map if GemKit unavailable

  /// Validation helper
  static String? validate() {
    if (!isConfigured) {
      return errorNoApiToken;
    }
    // Add more validation as needed
    return null; // No errors
  }

  /// Debug information
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isConfigured': isConfigured,
      'hasApiToken': apiToken.isNotEmpty,
      'tokenLength': apiToken.length,
      'tokenPreview': apiToken.isEmpty
          ? 'Not set'
          : '${apiToken.substring(0, 4)}...${apiToken.substring(apiToken.length - 4)}',
      'defaultLocation': {
        'lat': defaultLatitude,
        'lng': defaultLongitude,
        'zoom': defaultZoom,
      },
      'features': {
        'useGemKitMap': useGemKitMap,
        'enable3DBuildings': enable3DBuildings,
        'enableOfflineMaps': enableOfflineMaps,
      },
    };
  }
}
