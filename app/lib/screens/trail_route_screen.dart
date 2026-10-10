import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../models/pandal.dart';
import '../services/journey_planner.dart';
import '../services/journey_session.dart';
import '../services/location_service.dart';
import '../services/multimodal_routing_service.dart' hide haversineMeters;
import '../widgets/route_polylines.dart';
import '../services/routing_service.dart';

class TrailRouteScreen extends StatefulWidget {
  const TrailRouteScreen({
    super.key,
    required this.stops,
    this.allowMetro = true,
    this.allowTrain = true,
    this.existingRoutes,
    required this.onUseJourney,
  });
  final List<Pandal> stops;
  final bool allowMetro, allowTrain;
  final List<MultimodalRoute>? existingRoutes;
  final VoidCallback onUseJourney;
  @override
  State<TrailRouteScreen> createState() => _TrailRouteScreenState();
}

class _TrailRouteScreenState extends State<TrailRouteScreen> {
  List<MultimodalRoute>? _routes;
  String? _error;
  int _loaded = 0;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _error = null;
      _routes = null;
      _loaded = 0;
    });
    if (widget.existingRoutes != null) {
      setState(() => _routes = widget.existingRoutes);
      return;
    }
    try {
      var fix = await LocationService.instance.currentPosition();
      if (fix != null &&
          DateTime.now().difference(fix.timestamp).abs() >
              const Duration(seconds: 30)) {
        fix = await LocationService.instance.updateLiveLocation();
      }
      if (fix == null) {
        throw StateError(
          'Turn on location to route from your actual position.',
        );
      }
      var origin = LatLng(fix.latitude, fix.longitude);
      final routes = <MultimodalRoute>[];
      for (final stop in widget.stops) {
        routes.add(
          await JourneyPlanner.instance.plan(
            origin: origin,
            destination: LatLng(stop.lat, stop.lng),
            destinationName: stop.name,
            targetPandal: stop,
            allowMetro: widget.allowMetro,
            allowTrain: widget.allowTrain,
          ),
        );
        if (!mounted || generation != _generation) return;
        origin = LatLng(stop.lat, stop.lng);
        setState(() => _loaded = routes.length);
      }
      if (mounted && generation == _generation) {
        setState(() => _routes = routes);
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = 'Could not load a connected itinerary. Enable location, check your connection and retry.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routes = _routes;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Pandal trail route')),
      body: routes == null
          ? Center(
              child: _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Connecting roads, trains and metro… $_loaded/${widget.stops.length}',
                        ),
                      ],
                    ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 5,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        widget.stops.first.lat,
                        widget.stops.first.lng,
                      ),
                      initialCameraFit: CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints([
                          for (final route in routes) ...route.allDisplayPoints,
                        ]),
                        padding: const EdgeInsets.all(40),
                        maxZoom: 17,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: AppConfig.tileUrlTemplate,
                        userAgentPackageName: 'com.kolkatapuja.kolkata_puja',
                        keepBuffer: 1,
                      ),
                      PolylineLayer(
                        polylines: [
                          for (final route in routes)
                            ...buildHighlightedRoutePolylines(
                              WalkingRoute(
                                points: route.allDisplayPoints,
                                distanceMeters: route.totalDistanceMeters,
                                durationSeconds: route.totalDurationSeconds,
                                segments: route.polylines,
                              ),
                              dark,
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          for (var i = 0; i < widget.stops.length; i++)
                            Marker(
                              point: LatLng(
                                widget.stops[i].lat,
                                widget.stops[i].lng,
                              ),
                              width: 40,
                              height: 40,
                              child: Tooltip(
                                message: widget.stops[i].name,
                                child: CircleAvatar(child: Text('${i + 1}')),
                              ),
                            ),
                          for (final route in routes)
                            for (final leg in route.legs)
                              if (leg is! WalkLeg) ...[
                                Marker(
                                  point: leg.startPoint,
                                  width: 32,
                                  height: 32,
                                  child: const Icon(
                                    Icons.train,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                Marker(
                                  point: leg.endPoint,
                                  width: 32,
                                  height: 32,
                                  child: const Icon(
                                    Icons.train,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                        ],
                      ),
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution('OpenStreetMap contributors'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: ListView(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Ride times are estimates, not live departures. Dashed rail lines show approximate sections. Check service information at the station.',
                        ),
                      ),
                      for (var i = 0; i < routes.length; i++) ...[
                        ListTile(
                          title: Text('${i + 1}. ${widget.stops[i].name}'),
                          subtitle: Text(
                            '${routes[i].bestModeBadge} · ${routes[i].formattedTotalDuration} estimated',
                          ),
                        ),
                        for (final leg in routes[i].legs)
                          ListTile(
                            dense: true,
                            leading: Icon(
                              leg is WalkLeg
                                  ? Icons.directions_walk
                                  : leg is MetroLeg
                                  ? Icons.subway
                                  : Icons.train,
                            ),
                            title: Text(leg.instructions),
                            subtitle: Text(
                              '${leg.formattedDistance} · ${leg.formattedDuration}',
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.navigation),
                        label: const Text('Directions to next destination'),
                        onPressed: () {
                          if (widget.existingRoutes == null) {
                            JourneySession.instance.load(widget.stops, routes);
                          }
                          Navigator.pop(context);
                          widget.onUseJourney();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
