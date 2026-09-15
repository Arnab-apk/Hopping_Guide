// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// TODO: Uncomment after obtaining GemKit package from Magic Lane
// import 'package:gem_kit/gem_kit.dart';
// import 'package:gem_kit/api/gem_map.dart';
// import 'package:gem_kit/api/gem_map_controller.dart';

import '../models/pandal.dart';
import '../models/metro_station.dart';
import '../models/food_spot.dart';
import '../repositories/pandal_repository.dart';
import '../repositories/metro_repository.dart';
import '../repositories/supplementary_repository.dart';
import '../services/location_service.dart';
import '../services/omni_search_service.dart';
import '../services/routing_service.dart';

/// GemKit-powered map screen for Kolkata Puja app
/// 
/// This replaces the flutter_map implementation with Magic Lane's GemKit SDK
/// providing advanced features like:
/// - Offline map support
/// - Turn-by-turn navigation
/// - Better performance
/// - 3D rendering capabilities
/// - Advanced routing algorithms
class MapScreenGemKit extends StatefulWidget {
  const MapScreenGemKit({super.key});

  @override
  State<MapScreenGemKit> createState() => _MapScreenGemKitState();
}

class _MapScreenGemKitState extends State<MapScreenGemKit> {
  // TODO: Uncomment after obtaining GemKit
  // GemMapController? _mapController;
  
  // Data
  List<Pandal> _pandals = [];
  List<MetroStation> _metroStations = [];
  List<FoodSpot> _foodSpots = [];
  
  // Layer toggles
  bool _showMetro = false;
  bool _showFood = false;
  
  // Search state
  bool _isSearching = false;
  
  // Routing state
  LatLng? _routeDestination;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pandals = await PandalRepository.loadAllPandals();
    final metro = await MetroRepository.loadMetroStations();
    final food = await SupplementaryRepository.loadFoodSpots();
    
    if (mounted) {
      setState(() {
        _pandals = pandals;
        _metroStations = metro;
        _foodSpots = food;
      });
    }
  }

  @override
  void dispose() {
    // TODO: Release GemKit resources
    // GemKit.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildLayerToggles(),
          _buildSearchButton(),
          _buildLocationButton(),
          if (_routeDestination != null) _buildRouteHUD(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    // TODO: Replace with actual GemMap widget after obtaining SDK
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 80,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 24),
              Text(
                'GemKit Map Placeholder',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[700]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber[900]),
                        const SizedBox(width: 8),
                        Text(
                          'Action Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Obtain GemKit SDK from Magic Lane International B.V.\n'
                      '2. Add gem_kit package to pubspec.yaml\n'
                      '3. Configure API token in environment variables\n'
                      '4. Uncomment GemMap widget code in this file\n\n'
                      'See MAGIC_LANE_INTEGRATION.md for detailed instructions.',
                      style: TextStyle(
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loaded: ${_pandals.length} pandals, ${_metroStations.length} metro stations, ${_foodSpots.length} food spots',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    
    /* TODO: Uncomment and configure after obtaining GemKit SDK
    
    return GemMap(
      onMapCreated: _onMapCreated,
      appAuthorization: const String.fromEnvironment(
        'MAGIC_LANE_API_KEY',
        defaultValue: 'YOUR_API_TOKEN_HERE',
      ),
      // Initial camera position - Kolkata center
      initialCameraPosition: CameraPosition(
        target: LatLng(22.5726, 88.3639), // Kolkata
        zoom: 12.0,
        bearing: 0,
        tilt: 0,
      ),
    );
    */
  }

  /* TODO: Uncomment after obtaining GemKit SDK
  
  void _onMapCreated(GemMapController controller) {
    _mapController = controller;
    _addPandalMarkers();
    if (_showMetro) _addMetroMarkers();
    if (_showFood) _addFoodMarkers();
  }

  void _addPandalMarkers() {
    if (_mapController == null) return;
    
    // Add pandal markers to map
    // Implementation will depend on GemKit's marker API
    for (final pandal in _pandals) {
      // Create marker for each pandal
      // _mapController!.addMarker(/* pandal marker config */);
    }
  }

  void _addMetroMarkers() {
    if (_mapController == null) return;
    
    for (final station in _metroStations) {
      // Add metro station markers
      // _mapController!.addMarker(/* metro marker config */);
    }
  }

  void _addFoodMarkers() {
    if (_mapController == null) return;
    
    for (final spot in _foodSpots) {
      // Add food spot markers
      // _mapController!.addMarker(/* food marker config */);
    }
  }
  */

  Widget _buildLayerToggles() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: Column(
        children: [
          _buildToggleChip(
            label: 'Metro',
            icon: Icons.directions_subway,
            isActive: _showMetro,
            onTap: () {
              setState(() {
                _showMetro = !_showMetro;
              });
              // TODO: Toggle metro markers on map
            },
          ),
          const SizedBox(height: 8),
          _buildToggleChip(
            label: 'Food',
            icon: Icons.restaurant,
            isActive: _showFood,
            onTap: () {
              setState(() {
                _showFood = !_showFood;
              });
              // TODO: Toggle food markers on map
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF800020) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.white : const Color(0xFF800020),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF800020),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: GestureDetector(
        onTap: () {
          // TODO: Open omni-search overlay
          setState(() {
            _isSearching = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Color(0xFF800020)),
              SizedBox(width: 8),
              Text(
                'Search pandals, metro, food...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    final locationService = context.watch<LocationService>();
    
    return Positioned(
      bottom: 100,
      right: 16,
      child: FloatingActionButton(
        heroTag: 'location',
        onPressed: () {
          final pos = locationService.currentPosition;
          if (pos != null) {
            // TODO: Animate camera to user location
            // _mapController?.animateCamera(/* user position */);
          }
        },
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.my_location,
          color: Color(0xFF800020),
        ),
      ),
    );
  }

  Widget _buildRouteHUD() {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_walk, color: Color(0xFF800020)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Navigating to destination',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Route calculated with GemKit',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _routeDestination = null;
                });
                // TODO: Clear route from map
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
