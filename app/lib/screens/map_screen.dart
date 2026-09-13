import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../widgets/app_tutorial_dialog.dart';
import '../widgets/animated_fade_slide.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.repository});

  final PandalRepository? repository;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late final MapController _mapController;
  late final PandalRepository _repo;
  final SupplementaryRepository _suppRepo = SupplementaryRepository();
  late final AnimationController _pulseController;

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _repo = widget.repository ?? LocalAssetPandalRepository();
    _loadData();
    _tryGetLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
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
      _animatedMapMove(
        LatLng(_userPosition!.latitude, _userPosition!.longitude),
        15.5,
      );
    } else {
      await _tryGetLocation();
      if (_userPosition != null) {
        _animatedMapMove(
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
          15.5,
        );
      } else {
        // Default center on central Kolkata
        _animatedMapMove(
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
      _animatedMapMove(
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
      _animatedMapMove(center, zoom);

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
                      width: 34,
                      height: 34,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _animatedMapMove(LatLng(f.lat, f.lng), (_mapController.camera.zoom < 15.5 ? 15.5 : _mapController.camera.zoom));
                          _showFoodSpotSheet(f, isDark);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 17),
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
                    width: isSelected ? 52 : 38,
                    height: isSelected ? 52 : 38,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedPandal = p);
                        _animatedMapMove(
                          LatLng(p.lat, p.lng),
                          (_mapController.camera.zoom < 15.0 ? 15.0 : _mapController.camera.zoom),
                        );
                      },
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isSelected)
                                Container(
                                  width: 42 + (10 * _pulseController.value),
                                  height: 42 + (10 * _pulseController.value),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: PujaColors.festivalGold.withValues(
                                      alpha: 0.35 * (1.0 - _pulseController.value),
                                    ),
                                  ),
                                ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: isSelected ? 44 : 36,
                                height: isSelected ? 44 : 36,
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
                                    size: isSelected ? 22 : 18,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),

              // User Location Marker with Animated Radar Pulse
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                      width: 48,
                      height: 48,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulse = _pulseController.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 22 + (20 * pulse),
                                height: 22 + (20 * pulse),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: PujaColors.metroBlue.withValues(alpha: 0.35 * (1.0 - pulse)),
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: PujaColors.metroBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
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

          // Bottom Mini-Card Preview when a Pandal is tapped (Animated entrance)
          if (_selectedPandal != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: AnimatedFadeSlide(
                duration: const Duration(milliseconds: 320),
                offset: const Offset(0, 0.14),
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
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: PujaColors.crimsonVelvet.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: PujaColors.festivalGold.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                _selectedPandal!.zone.label,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: PujaColors.durgaRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CrowdBadge(crowdLevel: _selectedPandal!.crowdLevel),
                          const SizedBox(width: 4),
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
                  heroTag: 'app_tutorial_fab',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    AppTutorialDialog.show(context);
                  },
                  backgroundColor: PujaColors.festivalGold,
                  foregroundColor: Colors.black87,
                  tooltip: 'App Walkthrough & Guide',
                  child: const Icon(Icons.help_outline_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'toggle_food_fab',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showFoodSpots = !_showFoodSpots);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 1),
                        content: Text(
                          _showFoodSpots
                              ? '🍲 Showing ${_foodSpots.length} Food & Bhog spots'
                              : 'Food stalls hidden',
                        ),
                      ),
                    );
                  },
                  backgroundColor: _showFoodSpots
                      ? Colors.orange.shade800
                      : (isDark ? PujaColors.nightCard : Colors.white),
                  foregroundColor: _showFoodSpots ? Colors.white : Colors.orange.shade800,
                  tooltip: _showFoodSpots ? 'Hide Food Stalls' : 'Show Food Stalls (${_foodSpots.length})',
                  child: Icon(_showFoodSpots ? Icons.restaurant_rounded : Icons.restaurant_outlined),
                ),
                const SizedBox(height: 8),
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

  void _showFoodSpotSheet(FoodSpot f, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final distanceStr = _userPosition != null
            ? formatDistance(haversineMeters(_userPosition!.latitude, _userPosition!.longitude, f.lat, f.lng))
            : null;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? PujaColors.nightCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark ? PujaColors.nightBorder : PujaColors.festivalGold.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade800.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.shade800.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              f.type,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFFFAB40) : Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.temple_hindu, size: 18, color: PujaColors.festivalGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nearby Pandal: ${f.nearbyPandal}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      if (distanceStr != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: PujaColors.crimsonVelvet.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            distanceStr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: PujaColors.durgaRed,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _mapController.move(LatLng(f.lat, f.lng), 16.5);
                        },
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('Center on Map'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=${f.lat},${f.lng}',
                          );
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Directions'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
