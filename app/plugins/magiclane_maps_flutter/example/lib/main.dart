// Example for the Magic Lane Maps SDK for Flutter.
// Showcases basic map usage, adding markers and performing a search.
//
// Over 60 examples are available on the Magic Lane developer website.
//
// Please see the Get Started with examples guide at
// https://developer.magiclane.com/docs/flutter/examples/get-started-with-sample-apps/

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart' hide Route;
import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';

/// Paste your API token between the quotes.
/// Example: const projectApiToken = 'eyJhbGciOi...';
/// The API token can also be passed at build time using --dart-define.
const projectApiToken = String.fromEnvironment('PASTE_YOUR_API_TOKEN_HERE');

void main() {
  runApp(const GemMapExampleApp());
}

class GemMapExampleApp extends StatelessWidget {
  const GemMapExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GemMap Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const GemMapExampleScreen(),
    );
  }
}

class GemMapExampleScreen extends StatefulWidget {
  const GemMapExampleScreen({super.key});

  @override
  State<GemMapExampleScreen> createState() => _GemMapExampleScreenState();
}

class _GemMapExampleScreenState extends State<GemMapExampleScreen> {
  // Keep a reference to the controller so the functions can use it.
  GemMapController? _mapController;

  /// Called when the GemMap is ready. Save the controller for later use.
  void _onMapCreated(final GemMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The GemMap widget from the SDK. We attach a creation callback
          // to receive the [GemMapController].
          GemMap(
            onMapCreated: _onMapCreated,
            appAuthorization: projectApiToken,
          ),

          // Bottom-aligned horizontally scrollable list of buttons.
          if (_mapController != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: ActionButtonList(controller: _mapController!),
            ),
        ],
      ),
    );
  }
}

/// A simple horizontally scrollable list of action buttons
/// showcasing operations.
class ActionButtonList extends StatelessWidget {
  const ActionButtonList({super.key, required this.controller});

  final GemMapController controller;

  /// Show points and lines markers on the map and center the camera to show all markers
  ///
  /// #### More examples of marker usage:
  /// - Add markers: https://developer.magiclane.com/docs/flutter/examples/maps-3dscene/add-markers/
  /// - Draw shapes: https://developer.magiclane.com/docs/flutter/examples/maps-3dscene/draw-shapes
  ///
  /// #### Documentation regarding markers:
  /// - Marker structure: https://developer.magiclane.com/docs/flutter/guides/core/markers
  /// - Display markers on the map: https://developer.magiclane.com/docs/flutter/guides/maps/display-map-items/display-markers
  Future<void> _showMarkers() async {
    // The area where the camera will be centered, containing all markers.
    final area = RectangleGeographicArea(
      topLeft: Coordinates.fromLatLong(51.5310, -0.1524),
      bottomRight: Coordinates.fromLatLong(51.4889, -0.0474),
    );
    controller.centerOnArea(area);

    // =======================
    // POINT MARKERS
    // =======================

    // Create the point markers
    final Marker pointMarker1 = Marker()
      ..name = 'Point 1'
      ..setCoordinates([Coordinates.fromLatLong(51.5262, -0.1097)]);
    final Marker pointMarker2 = Marker()
      ..name = 'Point 2'
      ..setCoordinates([Coordinates.fromLatLong(51.4931, -0.0966)]);

    // Create a marker collection and add the point markers to it
    final MarkerCollection pointCollection =
        MarkerCollection(name: 'Point markers', markerType: MarkerType.point)
          ..add(pointMarker1)
          ..add(pointMarker2);

    // Create the render settings for the point markers
    // Applicable for all markers in the collection, use MarkerSketches for per-marker settings
    final MarkerCollectionRenderSettings pointMarkerSettings =
        MarkerCollectionRenderSettings(
      image: GemImage(
        imageId:
            GemIcon.waypointStart.id, // Can also set custom images as Uint8List
      ),
      labelTextSize: 3,
    );

    // Add the collection to the map
    controller.preferences.markers.add(
      pointCollection,
      settings: pointMarkerSettings,
    );

    // =======================
    // LINE MARKERS
    // =======================

    // Create the line marker (each marker is a separate line)
    final Marker lineMarker = Marker()
      ..name = 'Line 1'
      ..setCoordinates([
        Coordinates.fromLatLong(51.4926, -0.1237),
        Coordinates.fromLatLong(51.5094, -0.1070),
        Coordinates.fromLatLong(51.5185, -0.0842),
        Coordinates.fromLatLong(51.5338, -0.0574),
      ]);

    final MarkerCollectionRenderSettings lineMarkerSettings =
        MarkerCollectionRenderSettings(
      polylineInnerColor: Colors.green,
      polylineInnerSize: 4.0,
    );

    final MarkerCollection lineCollectionRenderSettings = MarkerCollection(
      name: 'Line markers',
      markerType: MarkerType.polyline,
    )..add(lineMarker);

    controller.preferences.markers.add(
      lineCollectionRenderSettings,
      settings: lineMarkerSettings,
    );
  }

  /// Perform a simple text search for "Paris" and center to the first result
  ///
  /// #### More examples regarding search:
  /// - Text search: https://developer.magiclane.com/docs/flutter/examples/places-search/text-search
  /// - Address search: https://developer.magiclane.com/docs/flutter/examples/places-search/address-search
  /// - Search location: https://developer.magiclane.com/docs/flutter/examples/places-search/search-location
  /// - Search categories: https://developer.magiclane.com/docs/flutter/examples/places-search/search-category
  /// - What is nearby: https://developer.magiclane.com/docs/flutter/examples/places-search/what-is-nearby
  /// - What is nearby category: https://developer.magiclane.com/docs/flutter/examples/places-search/what-is-nearby-category
  /// - Search along route: https://developer.magiclane.com/docs/flutter/examples/places-search/search-along-route
  ///
  /// #### Documentation regarding search:
  /// - Search: https://developer.magiclane.com/docs/flutter/guides/search
  Future<void> _searchForParis() async {
    final Coordinates center = Coordinates.fromLatLong(49.20, 10.31);

    SearchService.search('Paris', center, (
      final GemError err,
      final List<Landmark> results,
    ) async {
      if (results.isNotEmpty) {
        final Landmark first = results.first;
        controller.centerOnCoordinates(first.coordinates);
      } else {
        print('Paris search returned no results: $err');
      }
    });
  }

  /// Search for food and drink places near the map center position and highlight and center to the first result
  ///
  /// #### More examples regarding search:
  /// - Text search: https://developer.magiclane.com/docs/flutter/examples/places-search/text-search
  /// - Address search: https://developer.magiclane.com/docs/flutter/examples/places-search/address-search
  /// - Search location: https://developer.magiclane.com/docs/flutter/examples/places-search/search-location
  /// - Search categories: https://developer.magiclane.com/docs/flutter/examples/places-search/search-category
  /// - What is nearby: https://developer.magiclane.com/docs/flutter/examples/places-search/what-is-nearby
  /// - What is nearby category: https://developer.magiclane.com/docs/flutter/examples/places-search/what-is-nearby-category
  /// - Search along route: https://developer.magiclane.com/docs/flutter/examples/places-search/search-along-route
  ///
  /// #### Documentation regarding search:
  /// - Search: https://developer.magiclane.com/docs/flutter/guides/search
  Future<void> _searchAndCenterFoodAndDrink() async {
    final GemMapController controller = this.controller;

    // Reset the cursor position to the center of the map
    await controller.resetMapSelection();

    // Get center coordinates of the current map view
    final Coordinates centerOfMapViewport = controller.cursorWgsPosition;

    // Get the food and drink landmark category
    final foodAndDrinkCategory = GenericCategories.getCategory(
      GenericCategoriesId.foodAndDrink.id,
    )!;

    // Set the preferences to search only for food and drink landmarks
    final SearchPreferences preferences = SearchPreferences(
      searchAddresses: false,
    );
    preferences.landmarks.addStoreCategoryId(
      foodAndDrinkCategory.landmarkStoreId,
      foodAndDrinkCategory.id,
    );

    // Perform the search around the center of the map view
    // using the provided preferences
    SearchService.searchAroundPosition(centerOfMapViewport, (
      err,
      results,
    ) async {
      if (results.isNotEmpty) {
        final Landmark selectedLandmark = results.first;

        // Highlight the found landmark
        controller.activateHighlight([selectedLandmark]);

        // Center the map on the found landmark
        controller.centerOnCoordinates(
          selectedLandmark.coordinates,
          viewAngle: 0,
          animation: GemAnimation.linear(duration: Duration(seconds: 1)),
        );
      } else {
        print('No results found. Error: $err');
      }
    }, preferences: preferences);
  }

  /// Calculate a route between Amsterdam and Bruxelles, display it briefly and start a demo simulation
  ///
  /// ### More examples regarding routing and navigation:
  /// - Calculate route: https://developer.magiclane.com/docs/flutter/examples/routing-navigation/calculate-route
  /// - Route profile: https://developer.magiclane.com/docs/flutter/examples/routing-navigation/route-profile
  /// - Route instructions: https://developer.magiclane.com/docs/flutter/examples/routing-navigation/route-instructions
  /// - Truck Profile: https://developer.magiclane.com/docs/flutter/examples/routing-navigation/truck-profile
  /// - Calculate bike route: https://developer.magiclane.com/docs/flutter/examples/routing-navigation/calculate-bike-route
  /// - Public Transit: https://developer.magiclane.com/docs/flutter/examples/routing-navigation/public-transit
  /// - Navigate route: https://developer.magiclane.com/docs/flutter/examples/routing-navigation/navigate-route
  /// - Simulate route: https://developer.magiclane.com/docs/flutter/examples/routing-navigation/simulate-navigation
  /// - Lane instruction: https://developer.magiclane.com/docs/flutter/examples/routing-navigation/lane-instruction
  /// - etc.
  ///
  /// #### Documentation regarding routing and navigation:
  /// - Routes: https://developer.magiclane.com/docs/flutter/guides/core/routes
  /// - Navigation instructions: https://developer.magiclane.com/docs/flutter/guides/core/navigation-instructions
  /// - Routing: https://developer.magiclane.com/docs/flutter/guides/routing
  /// - Navigation: https://developer.magiclane.com/docs/flutter/guides/navigation
  Future<void> _routeAndNavigateAmsterdamToBruxelles() async {
    // Create landmarks for Amsterdam and Bruxelles
    // Can also be retrieved from a search result, map selection or other sources
    final Landmark amsterdam = Landmark.withLatLng(
      latitude: 52.3676,
      longitude: 4.9041,
    );
    final Landmark bruxelles = Landmark.withLatLng(
      latitude: 50.8503,
      longitude: 4.3517,
    );

    // Simple route preferences
    final RoutePreferences prefs = RoutePreferences(
      transportMode: RouteTransportMode.car, // Make a car route
      routeType: RouteType.fastest, // Prioritize fastest route
    );

    // Completer to wait for route calculation
    Completer<Route> routeCompleter = Completer<Route>();

    // Start route calculation (async operation, result provided via callback)
    RoutingService.calculateRoute(<Landmark>[amsterdam, bruxelles], prefs, (
      final GemError err,
      final List<Route> routes,
    ) async {
      if (err == GemError.success && routes.isNotEmpty) {
        final Route route = routes.first;
        routeCompleter.complete(route);
      } else {
        print('Route calculation failed: $err');
        routeCompleter.completeError(err);
      }
    });

    // Wait for the route calculation to complete
    final route = await routeCompleter.future;

    // Compose a route label containing route information
    final timeDistanceInfo = route.getTimeDistance();
    final numberOfMinutes = (timeDistanceInfo.totalTimeS / 60).round();
    final numberOfKilometers = (timeDistanceInfo.totalDistanceM / 1000).round();
    final routeLabel =
        'AMS -> BRU\n$numberOfMinutes mins, $numberOfKilometers kms';

    // Add route to the map as main route
    controller.preferences.routes.add(route, true, label: routeLabel);

    // Calculate a viewport area box for the route to center the map
    // The RectType uses physical pixels for the screen dimensions
    final fullViewArea = controller.viewport;
    final routeArea = Rectangle<int>(
      50,
      300,
      fullViewArea.width - 100,
      fullViewArea.height - 700,
    );

    // Center the map on the route
    controller.centerOnRoute(route, screenRect: routeArea);

    // Keep route visible for a short moment
    await Future.delayed(const Duration(seconds: 3));

    // Start a simulation on the computed route
    // and listen to navigation events
    NavigationService.startSimulation(
      route,
      onNavigationInstruction: (instruction, events) {
        print('Next turn instruction: ${instruction.nextTurnInstruction}');

        // Also available on the NavigationInstruction object:
        // - next instruction image (abstract geometry image of the turn)
        // - lane image (image showing the correct lane for the turn)
        // - distance to next turn
        // - next speed limit variation
      },
      onNavigationStarted: () {
        print('Simulation started');
      },
      onDestinationReached: (final Landmark dest) {
        print('Destination reached: ${dest.description}');
      },
      onError: (final GemError error) {
        print('Navigation error: $error');
      },
      speedMultiplier: 2.0, // Speed up the simulation (2x real speed)
    );

    // Make the camera follow the simulated position
    controller.startFollowingPosition();
  }

  /// Clear all elements displayed on the map and cancel any ongoing navigation
  Future<void> _clearMap() async {
    await controller.preferences.markers.clear();
    controller.preferences.routes.clear();

    controller.deactivateHighlight();
    NavigationService.cancelNavigation();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 40,
        child: Center(
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () async {
                  await _clearMap();
                  await _showMarkers();
                },
                child: const Text('Show Markers'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  await _clearMap();
                  await _searchForParis();
                },
                child: const Text('Text Search'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  await _clearMap();
                  await _searchAndCenterFoodAndDrink();
                },
                child: const Text('Categories Search'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  await _clearMap();
                  await _routeAndNavigateAmsterdamToBruxelles();
                },
                child: const Text('Routing and Navigation'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  await _clearMap();
                },
                child: const Text('Reset'),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
