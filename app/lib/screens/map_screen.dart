import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../models/pandal.dart';
import '../repositories/local_pandal_repository.dart';
import '../repositories/pandal_repository.dart';
import '../repositories/supplementary_repository.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../utils/haversine.dart';
import '../utils/responsive.dart';
import '../widgets/crowd_badge.dart';
import '../widgets/pandal_detail_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.repository});

  final PandalRepository? repository;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  late final PandalRepository _repo;
  final SupplementaryRepository _suppRepo = SupplementaryRepository();

  List<Pandal> _pandals = [];
  List<FoodSpot> _foodSpots = [];
  bool _showFoodSpots = false;
  bool _isLoading = true;

  KolkataZone? _selectedZone;
  Pandal? _selectedPandal;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _repo = widget.repository ?? LocalAssetPandalRepository();
    _loadData();
    _tryGetLocation();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _repo.all(),
      _suppRepo.getFoodSpots(),
    ]);

    if (!mounted) return;
    setState(() {
      _pandals = results[0] as List<Pandal>;
      _foodSpots = results[1] as List<FoodSpot>;
      _isLoading = false;
    });
  }

  Future<void> _tryGetLocation() async {
    try {
      final pos = await LocationService.instance.currentPosition();
      if (!mounted) return;
      setState(() => _userPosition = pos);
    } catch (_) {
      // Permission denied or services disabled; non-fatal in demo/desktop
    }
  }

  void _centerOnUser() async {
    if (_userPosition != null) {
      _mapController.move(
        LatLng(_userPosition!.latitude, _userPosition!.longitude),
        15,
      );
    } else {
      await _tryGetLocation();
      if (_userPosition != null) {
        _mapController.move(
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
          15,
        );
      } else {
        // Default center on central Kolkata
        _mapController.move(
          const LatLng(AppConfig.defaultLat, AppConfig.defaultLng),
          AppConfig.defaultZoom,
        );
      }
    }
  }

  List<Pandal> get _visiblePandals {
    if (_selectedZone == null) return _pandals;
    return _pandals.where((p) => p.zone == _selectedZone).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final visible = _visiblePandals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kolkata Puja Map'),
        actions: [
          IconButton(
            icon: Icon(
              _showFoodSpots ? Icons.restaurant : Icons.restaurant_outlined,
              color: _showFoodSpots ? PujaColors.goldBright : Colors.white,
            ),
            tooltip: 'Toggle Food & Bhog Spots',
            onPressed: () {
              setState(() => _showFoodSpots = !_showFoodSpots);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 1),
                  content: Text(_showFoodSpots ? 'Food & Bhog stalls shown' : 'Food stalls hidden'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'View as List',
            onPressed: () => Navigator.of(context).pushNamed('/list'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(AppConfig.defaultLat, AppConfig.defaultLng),
              initialZoom: AppConfig.defaultZoom,
              onTap: (_, _) {
                if (_selectedPandal != null) {
                  setState(() => _selectedPandal = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.tileUrlTemplate,
                userAgentPackageName: 'com.kolkatapuja.kolkata_puja',
              ),

              // Food / Bhog Spot Markers
              if (_showFoodSpots)
                MarkerLayer(
                  markers: _foodSpots.map((f) {
                    return Marker(
                      point: LatLng(f.lat, f.lng),
                      width: 32,
                      height: 32,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('🍲 ${f.name} (${f.type}) near ${f.nearbyPandal}')),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.shade800,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.restaurant, color: Colors.white, size: 16),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Pandal Markers Layer
              MarkerLayer(
                markers: visible.map((p) {
                  final isSelected = _selectedPandal?.id == p.id;
                  return Marker(
                    point: LatLng(p.lat, p.lng),
                    width: isSelected ? 48 : 38,
                    height: isSelected ? 48 : 38,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedPandal = p);
                        _mapController.move(LatLng(p.lat, p.lng), _mapController.camera.zoom);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? PujaColors.goldBright : PujaColors.crimsonVelvet,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : PujaColors.festivalGold,
                            width: isSelected ? 3 : 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? PujaColors.festivalGold.withValues(alpha: 0.7)
                                  : Colors.black45,
                              blurRadius: isSelected ? 12 : 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.temple_hindu,
                            color: isSelected ? PujaColors.crimsonVelvet : PujaColors.goldBright,
                            size: isSelected ? 24 : 18,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // User Location Marker
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          color: PujaColors.metroBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Floating Zone Filter Chips Bar
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildZoneChip('All (${_pandals.length})', null, isDark),
                  ...KolkataZone.values.map((zone) {
                    final count = _pandals.where((p) => p.zone == zone).length;
                    return _buildZoneChip('${zone.label} ($count)', zone, isDark);
                  }),
                ],
              ),
            ),
          ),

          // Bottom Mini-Card Preview when a Pandal is tapped
          if (_selectedPandal != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Card(
                elevation: 8,
                shadowColor: Colors.black54,
                color: isDark ? PujaColors.nightCard : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(
                    color: PujaColors.festivalGold.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: PujaColors.crimsonVelvet.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: PujaColors.festivalGold.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              _selectedPandal!.zone.label,
                              style: const TextStyle(
                                color: PujaColors.durgaRed,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          CrowdBadge(crowdLevel: _selectedPandal!.crowdLevel),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => _selectedPandal = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedPandal!.name,
                        style: TextStyle(
                          fontSize: context.dynamicFont(18),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedPandal!.theme} · ${_selectedPandal!.nearestMetro ?? _selectedPandal!.timings}',
                        style: TextStyle(
                          fontSize: context.dynamicFont(13),
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                PandalDetailSheet.show(context, _selectedPandal!);
                              },
                              icon: Icon(Icons.info_outline, size: context.dynamicIcon(18)),
                              label: Text(
                                'View Details',
                                style: TextStyle(fontSize: context.dynamicFont(14), fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PujaColors.crimsonVelvet,
                                foregroundColor: PujaColors.goldBright,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: PujaColors.festivalGold.withValues(alpha: 0.4)),
                                ),
                              ),
                            ),
                            if (_userPosition != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? PujaColors.nightSurface : PujaColors.goldSoft,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: PujaColors.festivalGold.withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  formatDistance(
                                    haversineMeters(
                                      _userPosition!.latitude,
                                      _userPosition!.longitude,
                                      _selectedPandal!.lat,
                                      _selectedPandal!.lng,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: context.dynamicFont(12),
                                    fontWeight: FontWeight.w700,
                                    color: PujaColors.crimsonVelvet,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: PujaColors.durgaRed),
            ),
        ],
      ),
      floatingActionButton: _selectedPandal == null
          ? FloatingActionButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _centerOnUser();
              },
              backgroundColor: PujaColors.crimsonVelvet,
              foregroundColor: PujaColors.goldBright,
              tooltip: 'Center on My Location',
              child: Icon(Icons.my_location, size: context.dynamicIcon(24)),
            )
          : null,
    );
  }

  Widget _buildZoneChip(String label, KolkataZone? zone, bool isDark) {
    final isSelected = _selectedZone == zone;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        elevation: isSelected ? 4 : 2,
        borderRadius: BorderRadius.circular(999),
        color: isSelected ? PujaColors.crimsonVelvet : (isDark ? PujaColors.nightCard : Colors.white),
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? PujaColors.festivalGold : PujaColors.festivalGold.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedZone = isSelected && zone != null ? null : zone);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? PujaColors.goldBright : (isDark ? Colors.white70 : Colors.black87),
                fontSize: context.dynamicFont(12),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
