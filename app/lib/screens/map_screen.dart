import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../utils/haversine.dart';

/// P0 map screen: renders OSM raster tiles + pandal markers (and, later, live
/// group pins). This stub shows a working map centered on Kolkata so the
/// toolchain can be smoke-tested before the data layer is wired.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;

  // TODO(P0): replace with pandals streamed from PandalRepository.
  final List<({String name, double lat, double lng})> _sample = [
    (name: 'Sample Pandal — Park Street', lat: 22.5536, lng: 88.3517),
    (name: 'Sample Pandal — Maddox Square', lat: 22.5290, lng: 88.3637),
    (name: 'Sample Pandal — Ekdalia', lat: 22.5245, lng: 88.3688),
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kolkata Puja')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(AppConfig.defaultLat, AppConfig.defaultLng),
          initialZoom: AppConfig.defaultZoom,
        ),
        children: [
          TileLayer(
            urlTemplate: AppConfig.tileUrlTemplate,
            userAgentPackageName: 'com.kolkatapuja.kolkata_puja',
          ),
          MarkerLayer(
            markers: [
              for (final p in _sample)
                Marker(
                  point: LatLng(p.lat, p.lng),
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on,
                      color: Colors.red, size: 32),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _centerOnMe,
        icon: const Icon(Icons.my_location),
        label: const Text('Nearest to me'),
      ),
    );
  }

  /// P0 "nearest pandals to me" entry — opens device GPS and sorts.
  /// Wire LocationService.currentPosition() + PandalRepository once configured.
  void _centerOnMe() {
    // Placeholder UX until location + data are wired.
    final p = _sample.first;
    _mapController.move(LatLng(p.lat, p.lng), 15);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Demo: ${p.name} (${formatDistance(0)})')),
    );
  }
}
