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

  LatLng _getZoneCenter(KolkataZone zone) {
    switch (zone) {
      case KolkataZone.northKolkata:
        return const LatLng(22.597, 88.368);
      case KolkataZone.centralKolkata:
        return const LatLng(22.571, 88.363);
      case KolkataZone.southKolkata:
        return const LatLng(22.520, 88.358);
      case KolkataZone.saltLake:
        return const LatLng(22.588, 88.415);
      case KolkataZone.newTown:
        return const LatLng(22.585, 88.468);
      case KolkataZone.nadiaKalyani:
        return const LatLng(22.980, 88.433);
      case KolkataZone.hooghlyChinsurah:
        return const LatLng(22.896, 88.389);
      case KolkataZone.hooghlyBandel:
        return const LatLng(22.919, 88.381);
    }
  }

  double _getZoneZoom(KolkataZone zone) {
    switch (zone) {
      case KolkataZone.nadiaKalyani:
        return 13.5;
      case KolkataZone.hooghlyChinsurah:
      case KolkataZone.hooghlyBandel:
        return 13.8;
      case KolkataZone.northKolkata:
      case KolkataZone.centralKolkata:
      case KolkataZone.southKolkata:
      case KolkataZone.saltLake:
      case KolkataZone.newTown:
        return 13.5;
    }
  }

  void _locateZone(KolkataZone? zone) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedZone = zone;
      _selectedPandal = null;
    });

    if (zone == null) {
      _mapController.move(
        const LatLng(22.65, 88.38),
        10.8,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text('Showing all ${_pandals.length} pandals across Kolkata & Suburbs'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final center = _getZoneCenter(zone);
      final zoom = _getZoneZoom(zone);
      _mapController.move(center, zoom);

      final count = _pandals.where((p) => p.zone == zone).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('📍 Centered on ${zone.label} · $count Pandals'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            icon: const Icon(Icons.travel_explore),
            tooltip: 'Locate Region & Suburbs',
            onPressed: () => _showRegionPickerSheet(context, isDark),
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

          // Floating Zone Filter & Locate Bar (Responsive, Pinned & Never Cut Out)
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: (isDark ? PujaColors.nightCard : Colors.white).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: PujaColors.festivalGold.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  // Pinned "Regions ▾" button that opens bottom sheet
                  _buildRegionMenuButton(isDark),
                  Container(
                    height: 22,
                    width: 1,
                    color: isDark ? Colors.white24 : Colors.black12,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  // Scrollable zone chips with short labels
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildZoneChip('All (${_pandals.length})', null, isDark),
                          ...KolkataZone.values.map((zone) {
                            final count = _pandals.where((p) => p.zone == zone).length;
                            return _buildZoneChip('${zone.shortLabel} ($count)', zone, isDark);
                          }),
                        ],
                      ),
                    ),
                  ),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.dynamicFont(18),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedPandal!.theme} · ${_selectedPandal!.nearestMetro ?? _selectedPandal!.timings}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'locate_region_fab',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showRegionPickerSheet(context, isDark);
                  },
                  backgroundColor: isDark ? PujaColors.nightCard : Colors.white,
                  foregroundColor: PujaColors.durgaRed,
                  tooltip: 'Locate Region & Suburbs',
                  child: const Icon(Icons.travel_explore),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'locate_user_fab',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _centerOnUser();
                  },
                  backgroundColor: PujaColors.crimsonVelvet,
                  foregroundColor: PujaColors.goldBright,
                  tooltip: 'Center on My Location',
                  child: Icon(Icons.my_location, size: context.dynamicIcon(24)),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildRegionMenuButton(bool isDark) {
    final hasFilter = _selectedZone != null;
    return Material(
      color: hasFilter ? PujaColors.crimsonVelvet : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.lightImpact();
          _showRegionPickerSheet(context, isDark);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 15,
                color: hasFilter ? PujaColors.goldBright : PujaColors.durgaRed,
              ),
              const SizedBox(width: 4),
              Text(
                hasFilter ? _selectedZone!.shortLabel : 'Regions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: hasFilter ? PujaColors.goldBright : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(width: 1),
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: hasFilter ? PujaColors.goldBright : (isDark ? Colors.white70 : Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneChip(String label, KolkataZone? zone, bool isDark) {
    final isSelected = _selectedZone == zone;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Material(
        elevation: isSelected ? 3 : 0,
        borderRadius: BorderRadius.circular(999),
        color: isSelected
            ? PujaColors.crimsonVelvet
            : (isDark ? PujaColors.nightSurface : Colors.grey.shade100),
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? PujaColors.festivalGold : PujaColors.festivalGold.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _locateZone(isSelected && zone != null ? null : zone),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? PujaColors.goldBright : (isDark ? Colors.white70 : Colors.black87),
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRegionPickerSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? PujaColors.nightSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.travel_explore, color: PujaColors.durgaRed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Locate Region & Suburbs',
                            style: TextStyle(
                              fontSize: context.dynamicFont(18),
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : PujaColors.crimsonVelvet,
                            ),
                          ),
                          Text(
                            'Tap to center map and filter pandals',
                            style: TextStyle(
                              fontSize: context.dynamicFont(12),
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _locateZone(null);
                      },
                      child: const Text(
                        'Reset All',
                        style: TextStyle(fontWeight: FontWeight.bold, color: PujaColors.durgaRed),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    _buildRegionCategoryHeader('Kolkata Metro Zones', isDark),
                    _buildRegionTile(KolkataZone.northKolkata, 'উত্তর কলকাতা', Icons.location_city, isDark, ctx),
                    _buildRegionTile(KolkataZone.centralKolkata, 'মধ্য কলকাতা', Icons.account_balance, isDark, ctx),
                    _buildRegionTile(KolkataZone.southKolkata, 'দক্ষিণ কলকাতা', Icons.festival, isDark, ctx),
                    _buildRegionTile(KolkataZone.saltLake, 'সল্টলেক', Icons.domain, isDark, ctx),
                    _buildRegionTile(KolkataZone.newTown, 'নিউ টাউন', Icons.apartment, isDark, ctx),
                    const SizedBox(height: 12),
                    _buildRegionCategoryHeader('Greater Bengal Suburbs (Nadia & Hooghly)', isDark),
                    _buildRegionTile(KolkataZone.nadiaKalyani, 'কল্যাণী (নদিয়া)', Icons.temple_hindu, isDark, ctx),
                    _buildRegionTile(KolkataZone.hooghlyChinsurah, 'চুঁচুড়া (হুগলি)', Icons.water, isDark, ctx),
                    _buildRegionTile(KolkataZone.hooghlyBandel, 'ব্যান্ডেল (হুগলি)', Icons.church, isDark, ctx),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegionCategoryHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: PujaColors.durgaRed,
        ),
      ),
    );
  }

  Widget _buildRegionTile(
    KolkataZone zone,
    String bengaliName,
    IconData icon,
    bool isDark,
    BuildContext sheetCtx,
  ) {
    final isSelected = _selectedZone == zone;
    final count = _pandals.where((p) => p.zone == zone).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: isSelected
            ? PujaColors.crimsonVelvet.withValues(alpha: 0.12)
            : (isDark ? PujaColors.nightCard : Colors.grey.shade50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected ? PujaColors.festivalGold : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(sheetCtx);
            _locateZone(zone);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PujaColors.crimsonVelvet
                        : (isDark ? PujaColors.nightSurface : PujaColors.goldSoft),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? PujaColors.goldBright : PujaColors.crimsonVelvet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        bengaliName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? PujaColors.crimsonVelvet : PujaColors.goldSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count Pandals',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? PujaColors.goldBright : PujaColors.crimsonVelvet,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: isSelected ? PujaColors.crimsonVelvet : (isDark ? Colors.white38 : Colors.black26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
