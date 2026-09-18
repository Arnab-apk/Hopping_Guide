// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Route, Path;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart' hide Provider, Route, Path;
import 'package:provider/provider.dart';

import 'package:latlong2/latlong.dart' as ll;

import '../config/app_config.dart';
import '../config/gemkit_config.dart';
import '../config/theme.dart';
import '../models/metro_station.dart';
import '../models/pandal.dart';
import '../models/squad_member.dart';
import '../repositories/local_pandal_repository.dart';
import '../repositories/metro_repository.dart';
import '../repositories/pandal_repository.dart';
import '../repositories/supplementary_repository.dart';
import '../services/auth_service.dart';
import '../services/custom_hopping_trail_service.dart';
import '../services/location_service.dart';
import '../services/squad_service.dart';
import '../utils/constants.dart';
import '../utils/haversine.dart';
import '../widgets/custom_trail_planner_dialog.dart';
import '../widgets/pandal_detail_sheet.dart';
import '../widgets/pandal_search_autocomplete.dart';
import '../widgets/puja_icons.dart';
import '../models/place.dart';
import '../widgets/user_profile_sheet.dart';
import 'map_screen.dart';
import 'pandal_list_screen.dart';

/// Complete Magic Lane Maps SDK (GemKit) implementation for Kolkata Puja Parikrama.
///
/// Provides:
/// - Hardware-accelerated 3D vector map with 3D buildings & terrain
/// - 387 Pandal markers with zone filtering and interactive detail sheets
/// - 41 Kolkata Metro station overlays with route-to capability
/// - 66 Food spot overlays with distance and recommendations
/// - Live Squad companions tracking and avatar pins
/// - Magic Lane native Turn-by-Turn navigation with TTS voice directions
/// - Offline map downloading via Magic Lane ContentStore
/// - Top Omni-search bar with instant camera centering
/// - Follow-me GPS tracking and compass bearing
class MapScreenGemKit extends StatefulWidget {
  const MapScreenGemKit({super.key, this.repository});

  final PandalRepository? repository;

  @override
  State<MapScreenGemKit> createState() => _MapScreenGemKitState();
}

/// Status notification data model for isolated ValueNotifier rebuilds.
class _StatusPillData {
  final String message;
  final IconData icon;
  final Color? color;

  const _StatusPillData({
    required this.message,
    required this.icon,
    this.color,
  });
}

/// Navigation instruction and countdown data model for isolated rebuilds.
class _NavProgressData {
  final String instruction;
  final int distanceM;
  final int timeS;

  const _NavProgressData({
    required this.instruction,
    required this.distanceM,
    required this.timeS,
  });
}

class _MapScreenGemKitState extends State<MapScreenGemKit>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  GemMapController? _mapController;
  late final PandalRepository _repo;
  final SupplementaryRepository _suppRepo = SupplementaryRepository();

  // Pre-allocated static marker icon wrappers to eliminate runtime allocations
  static final GemImage _pandalIcon = GemImage(imageId: GemIcon.redBall.id);
  static final GemImage _metroIcon = GemImage(imageId: GemIcon.blueBall.id);
  static final GemImage _foodIcon = GemImage(imageId: GemIcon.yellowBall.id);
  static final GemImage _squadIcon = GemImage(imageId: GemIcon.greenBall.id);
  static final GemImage _userLocationIcon = GemImage(imageId: GemIcon.waypointStart.id);
  static final GemImage _clusterLowIcon = GemImage(imageId: GemIcon.yellowBall.id);
  static final GemImage _clusterMedIcon = GemImage(imageId: GemIcon.yellowBall.id);
  static final GemImage _clusterHighIcon = GemImage(imageId: GemIcon.redBall.id);

  // Dedicated MarkerCollections for targeted updates without tearing down all pins
  MarkerCollection? _pandalCol;
  MarkerCollection? _metroCol;
  MarkerCollection? _foodCol;
  MarkerCollection? _squadCol;
  MarkerCollection? _userLocationCol;

  // Data
  List<Pandal> _pandals = [];
  List<Pandal> _cachedVisiblePandals = [];
  List<MetroStation> _metroStations = [];
  List<FoodSpot> _foodSpots = [];
  bool _isLoading = true;

  // Filters & Layers
  KolkataZone? _selectedZone;
  bool _filterNearby10Km = false;
  bool _showMetro = false;
  bool _showFood = false;
  bool _showMapSearchBar = true;
  bool _is3DMode = true;
  bool _followUser = false;

  // Selection
  Pandal? _selectedPandal;
  MetroStation? _selectedMetroStation;
  FoodSpot? _selectedFoodSpot;
  SquadMember? _selectedSquadMember;

  // Navigation & Routing state
  bool _isNavigating = false;
  String _activeNavInstruction = '';
  int _remainingDistanceM = 0;
  int _remainingTimeS = 0;
  TaskHandler? _navTaskHandler;
  final ValueNotifier<_NavProgressData?> _navProgressNotifier =
      ValueNotifier<_NavProgressData?>(null);

  // Status Pill (Isolated ValueNotifier to eliminate map widget tree rebuilds)
  final ValueNotifier<_StatusPillData?> _statusPillNotifier =
      ValueNotifier<_StatusPillData?>(null);
  Timer? _statusPillTimer;

  // User location
  double? _userLat;
  double? _userLng;

  // Offline maps store
  List<ContentStoreItem> _offlineItems = [];
  bool _isLoadingOfflineStore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repo = widget.repository ?? LocalAssetPandalRepository();

    // Listen to global external action requests (from cards/sheets)
    MapScreen.pendingPandalAction.addListener(_handlePendingPandalAction);
    MapScreen.pendingFoodSpotAction.addListener(_handlePendingFoodSpotAction);
    MapScreen.pendingMetroStationAction.addListener(_handlePendingMetroAction);

    if (MapScreen.pendingPandalAction.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingPandalAction());
    }
    if (MapScreen.pendingFoodSpotAction.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingFoodSpotAction());
    }
    if (MapScreen.pendingMetroStationAction.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingMetroAction());
    }

    _loadData();
    _startLocationUpdates();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      LocationService.instance.pauseLiveTracking();
    } else if (state == AppLifecycleState.resumed) {
      LocationService.instance.resumeLiveTracking();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocationService.instance.pauseLiveTracking();
    MapScreen.pendingPandalAction.removeListener(_handlePendingPandalAction);
    MapScreen.pendingFoodSpotAction.removeListener(_handlePendingFoodSpotAction);
    MapScreen.pendingMetroStationAction.removeListener(_handlePendingMetroAction);
    _statusPillTimer?.cancel();
    _statusPillNotifier.dispose();
    _navProgressNotifier.dispose();
    if (_isNavigating) {
      NavigationService.cancelNavigation(_navTaskHandler);
    }
    super.dispose();
  }

  void _showStatusPill(
    String message, {
    IconData? icon,
    Color? color,
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    _statusPillTimer?.cancel();
    _statusPillNotifier.value = _StatusPillData(
      message: message,
      icon: icon ?? Icons.info_outline_rounded,
      color: color,
    );
    _statusPillTimer = Timer(duration, () {
      if (mounted) {
        _statusPillNotifier.value = null;
      }
    });
  }

  void _recomputeVisiblePandals() {
    var list = _pandals;
    if (_selectedZone != null) {
      list = list.where((p) => p.zone == _selectedZone).toList();
    }
    if (_filterNearby10Km) {
      final refLat = _userLat ?? AppConfig.defaultLat;
      final refLng = _userLng ?? AppConfig.defaultLng;
      list = list.where((p) {
        final d = haversineMeters(refLat, refLng, p.lat, p.lng);
        return d <= 10000;
      }).toList();
    }
    _cachedVisiblePandals = list;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.all(),
        _suppRepo.getFoodSpots(),
      ]);

      if (!mounted) return;
      _pandals = results[0] as List<Pandal>;
      _foodSpots = results[1] as List<FoodSpot>;
      _metroStations = MetroRepository.allStations;
      _recomputeVisiblePandals();

      setState(() {
        _isLoading = false;
      });

      _refreshMapMarkers();
    } catch (e) {
      debugPrint('Error loading map data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startLocationUpdates() {
    LocationService.instance.startLiveTracking(
      throttleInterval: const Duration(milliseconds: 1500),
      onLocationChanged: (pos) {
        if (!mounted) return;
        _userLat = pos.latitude;
        _userLng = pos.longitude;

        // Smoothly update user position marker without tearing down other markers
        _updateUserLocationMarker(pos.latitude, pos.longitude);
        SquadService.instance.updateUserLocation(pos.latitude, pos.longitude);

        if (_followUser) {
          _mapController?.centerOnCoordinates(
            Coordinates.fromLatLong(pos.latitude, pos.longitude),
            zoomLevel: 16,
            viewAngle: _is3DMode ? 35.0 : 0.0,
            animation: GemAnimation(type: AnimationType.linear, duration: 600),
          );
        }
      },
    );
  }

  // --- External Action Handlers ---
  void _handlePendingPandalAction() {
    final action = MapScreen.pendingPandalAction.value;
    if (action != null) {
      MapScreen.pendingPandalAction.value = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _selectPandal(action.pandal);
        if (action.traceRoute) {
          _startTurnByTurnRoute(
            destLat: action.pandal.lat,
            destLng: action.pandal.lng,
            destName: action.pandal.name,
          );
        }
      });
    }
  }

  void _handlePendingFoodSpotAction() {
    final action = MapScreen.pendingFoodSpotAction.value;
    if (action != null) {
      MapScreen.pendingFoodSpotAction.value = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _showFood = true;
          _selectedFoodSpot = action.spot;
          _selectedPandal = null;
          _selectedMetroStation = null;
        });
        _centerOn(action.spot.lat, action.spot.lng, zoom: 16);
        if (action.traceRoute) {
          _startTurnByTurnRoute(
            destLat: action.spot.lat,
            destLng: action.spot.lng,
            destName: action.spot.name,
          );
        }
      });
    }
  }

  void _handlePendingMetroAction() {
    final action = MapScreen.pendingMetroStationAction.value;
    if (action != null) {
      MapScreen.pendingMetroStationAction.value = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _showMetro = true;
          _selectedMetroStation = action.station;
          _selectedPandal = null;
          _selectedFoodSpot = null;
        });
        _centerOn(action.station.latitude, action.station.longitude, zoom: 16);
        if (action.traceRoute) {
          _startTurnByTurnRoute(
            destLat: action.station.latitude,
            destLng: action.station.longitude,
            destName: action.station.name,
          );
        }
      });
    }
  }

  // --- Map Controller & Marker Setup ---
  void _onMapCreated(GemMapController controller) {
    _mapController = controller;
    debugPrint('[GemMap] Platform view created. Mode: AndroidViewMode.auto (HCPP enabled on API 34+)');

    // Apply 3D perspective tilt
    if (_is3DMode) {
      controller.preferences.viewAngle = 35.0;
    }

    // Register single-touch handler for interactive marker taps
    controller.registerOnTouch((pos) {
      _handleMapTouch(pos);
    });

    _initMarkerCollections(controller);
    _refreshMapMarkers();
  }

  void _initMarkerCollections(GemMapController controller) {
    // Clear any leftover collections
    while (controller.preferences.markers.size > 0) {
      controller.preferences.markers.removeAt(0);
    }

    // 1. Pandals collection with native clustering at zoom < 14
    _pandalCol = MarkerCollection(
      name: 'Pandals',
      markerType: MarkerType.point,
    );
    controller.preferences.markers.add(
      _pandalCol!,
      settings: MarkerCollectionRenderSettings(
        image: _pandalIcon,
        imageSize: 7.5,
        labelTextSize: 2.5,
        pointsGroupingZoomLevel: 14,
        lowDensityPointsGroupImage: _clusterLowIcon,
        mediumDensityPointsGroupImage: _clusterMedIcon,
        highDensityPointsGroupImage: _clusterHighIcon,
        labelGroupTextColor: Colors.white,
        labelGroupTextSize: 2.5,
        buildPointsGroupConfig: true,
      ),
    );

    // 2. Metro collection
    _metroCol = MarkerCollection(
      name: 'Metro',
      markerType: MarkerType.point,
    );
    controller.preferences.markers.add(
      _metroCol!,
      settings: MarkerCollectionRenderSettings(
        image: _metroIcon,
        imageSize: 7.0,
      ),
    );

    // 3. Food collection
    _foodCol = MarkerCollection(
      name: 'Food',
      markerType: MarkerType.point,
    );
    controller.preferences.markers.add(
      _foodCol!,
      settings: MarkerCollectionRenderSettings(
        image: _foodIcon,
        imageSize: 6.5,
      ),
    );

    // 4. Squad collection
    _squadCol = MarkerCollection(
      name: 'Squad',
      markerType: MarkerType.point,
    );
    controller.preferences.markers.add(
      _squadCol!,
      settings: MarkerCollectionRenderSettings(
        image: _squadIcon,
        imageSize: 8.5,
      ),
    );

    // 5. User Location collection
    _userLocationCol = MarkerCollection(
      name: 'UserLocation',
      markerType: MarkerType.point,
    );
    controller.preferences.markers.add(
      _userLocationCol!,
      settings: MarkerCollectionRenderSettings(
        image: _userLocationIcon,
        imageSize: 9.0,
      ),
    );
  }

  List<Pandal> get _visiblePandals {
    if (_cachedVisiblePandals.isEmpty && _pandals.isNotEmpty) {
      _recomputeVisiblePandals();
    }
    return _cachedVisiblePandals;
  }

  void _updatePandalMarkers() {
    final col = _pandalCol;
    if (col == null) return;
    col.clear();
    final pandals = _visiblePandals;
    for (final p in pandals) {
      final m = Marker()
        ..name = p.id
        ..setCoordinates([Coordinates.fromLatLong(p.lat, p.lng)]);
      col.add(m);
    }
  }

  void _updateMetroMarkers() {
    final col = _metroCol;
    if (col == null) return;
    col.clear();
    if (_showMetro && _metroStations.isNotEmpty) {
      for (final m in _metroStations) {
        final marker = Marker()
          ..name = 'metro_${m.id}'
          ..setCoordinates([Coordinates.fromLatLong(m.latitude, m.longitude)]);
        col.add(marker);
      }
    }
  }

  void _updateFoodMarkers() {
    final col = _foodCol;
    if (col == null) return;
    col.clear();
    if (_showFood && _foodSpots.isNotEmpty) {
      for (final f in _foodSpots) {
        final marker = Marker()
          ..name = 'food_${f.name}'
          ..setCoordinates([Coordinates.fromLatLong(f.lat, f.lng)]);
        col.add(marker);
      }
    }
  }

  void _updateSquadMarkers() {
    final col = _squadCol;
    if (col == null) return;
    col.clear();
    final squadService = Provider.of<SquadService>(context, listen: false);
    if (squadService.hasActiveSquad && squadService.showSquadOnMap) {
      final companions = squadService.companionMembers;
      for (final s in companions) {
        final marker = Marker()
          ..name = 'squad_${s.id}'
          ..setCoordinates([Coordinates.fromLatLong(s.latitude, s.longitude)]);
        col.add(marker);
      }
    }
  }

  void _updateUserLocationMarker(double lat, double lng) {
    final col = _userLocationCol;
    if (col == null) return;
    col.clear();
    final marker = Marker()
      ..name = 'user_my_location'
      ..setCoordinates([Coordinates.fromLatLong(lat, lng)]);
    col.add(marker);
  }

  void _refreshMapMarkers() {
    final controller = _mapController;
    if (controller == null) return;
    _updatePandalMarkers();
    _updateMetroMarkers();
    _updateFoodMarkers();
    _updateSquadMarkers();
    if (_userLat != null && _userLng != null) {
      _updateUserLocationMarker(_userLat!, _userLng!);
    }
  }

  void _handleMapTouch(math.Point<int> screenPos) {
    final controller = _mapController;
    if (controller == null) return;

    final coords = controller.transformScreenToWgs(screenPos);
    final tapLat = coords.latitude;
    final tapLng = coords.longitude;

    // 1. Check for nearby Pandals (within ~65 meters)
    Pandal? nearestPandal;
    double minPandalDist = 65.0;
    for (final p in _visiblePandals) {
      final d = haversineMeters(tapLat, tapLng, p.lat, p.lng);
      if (d < minPandalDist) {
        minPandalDist = d;
        nearestPandal = p;
      }
    }

    if (nearestPandal != null) {
      _selectPandal(nearestPandal);
      return;
    }

    // 2. Check for Metro Stations (within ~70 meters)
    if (_showMetro) {
      MetroStation? nearestMetro;
      double minMetroDist = 70.0;
      for (final m in _metroStations) {
        final d = haversineMeters(tapLat, tapLng, m.latitude, m.longitude);
        if (d < minMetroDist) {
          minMetroDist = d;
          nearestMetro = m;
        }
      }
      if (nearestMetro != null) {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedMetroStation = nearestMetro;
          _selectedPandal = null;
          _selectedFoodSpot = null;
          _selectedSquadMember = null;
        });
        _centerOn(nearestMetro.latitude, nearestMetro.longitude, zoom: 16);
        _showStatusPill('🚇 ${nearestMetro.name} (${nearestMetro.line.label})');
        return;
      }
    }

    // 3. Check for Food Spots (within ~70 meters)
    if (_showFood) {
      FoodSpot? nearestFood;
      double minFoodDist = 70.0;
      for (final f in _foodSpots) {
        final d = haversineMeters(tapLat, tapLng, f.lat, f.lng);
        if (d < minFoodDist) {
          minFoodDist = d;
          nearestFood = f;
        }
      }
      if (nearestFood != null) {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedFoodSpot = nearestFood;
          _selectedPandal = null;
          _selectedMetroStation = null;
          _selectedSquadMember = null;
        });
        _centerOn(nearestFood.lat, nearestFood.lng, zoom: 16);
        _showStatusPill('🍽️ ${nearestFood.name}');
        return;
      }
    }

    // Tap on empty space: clear selections
    if (_selectedPandal != null ||
        _selectedMetroStation != null ||
        _selectedFoodSpot != null ||
        _selectedSquadMember != null) {
      setState(() {
        _selectedPandal = null;
        _selectedMetroStation = null;
        _selectedFoodSpot = null;
        _selectedSquadMember = null;
      });
    }
  }

  void _selectPandal(Pandal pandal) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPandal = pandal;
      _selectedMetroStation = null;
      _selectedFoodSpot = null;
      _selectedSquadMember = null;
    });
    _centerOn(pandal.lat, pandal.lng, zoom: 16);

    PandalDetailSheet.show(context, pandal);
  }

  void _centerOn(double lat, double lng, {int zoom = 15}) {
    _mapController?.centerOnCoordinates(
      Coordinates.fromLatLong(lat, lng),
      zoomLevel: zoom,
      viewAngle: _is3DMode ? 35.0 : 0.0,
      animation: GemAnimation(type: AnimationType.linear, duration: 400),
    );
  }

  // --- Magic Lane Routing & Turn-by-Turn Navigation ---
  void _startTurnByTurnRoute({
    required double destLat,
    required double destLng,
    required String destName,
  }) {
    final startLat = _userLat ?? AppConfig.defaultLat;
    final startLng = _userLng ?? AppConfig.defaultLng;

    _showStatusPill('🚶 Calculating route to $destName...', icon: Icons.route);

    final startLandmark = Landmark()
      ..name = 'Current Location'
      ..coordinates = Coordinates.fromLatLong(startLat, startLng);

    final destLandmark = Landmark()
      ..name = destName
      ..coordinates = Coordinates.fromLatLong(destLat, destLng);

    final routePrefs = RoutePreferences(
      transportMode: RouteTransportMode.pedestrian,
      routeType: RouteType.fastest,
    );

    RoutingService.calculateRoute(
      [startLandmark, destLandmark],
      routePrefs,
      (err, routes) {
        if (!mounted) return;

        if (err == GemError.success && routes.isNotEmpty) {
          final route = routes.first;

          // Display route polyline on map
          _mapController?.preferences.routes.clear();
          _mapController?.preferences.routes.add(route, true);
          _mapController?.centerOnRoute(route);

          // Enable Voice Guidance
          SoundPlayingService.canPlaySounds = true;

          // Start Turn-by-Turn Navigation
          _navTaskHandler = NavigationService.startNavigation(
            route,
            onDestinationReached: (dest) {
              if (!mounted) return;
              _showStatusPill('🎉 You have arrived at ${dest.name}!');
              _cancelNavigation();
            },
            onNavigationInstruction: (instruction, events) {
              if (!mounted) return;
              _navProgressNotifier.value = _NavProgressData(
                instruction: instruction.nextTurnInstruction,
                distanceM:
                    instruction.remainingTravelTimeDistance.totalDistanceM,
                timeS:
                    instruction.remainingTravelTimeDistance.totalTimeS,
              );
            },
          );

          final timeDist = route.getTimeDistance();
          _navProgressNotifier.value = _NavProgressData(
            instruction: 'Proceed to $destName',
            distanceM: timeDist.totalDistanceM,
            timeS: timeDist.totalTimeS,
          );

          setState(() {
            _isNavigating = true;
            _activeNavInstruction = 'Proceed to $destName';
          });

          _showStatusPill('🧭 Navigation started with voice guidance',
              icon: Icons.navigation_rounded);
        } else {
          _showStatusPill('⚠ Could not calculate walking route ($err)',
              icon: Icons.error_outline_rounded);
        }
      },
    );
  }

  void _cancelNavigation() {
    if (_isNavigating) {
      NavigationService.cancelNavigation(_navTaskHandler);
    }
    _mapController?.preferences.routes.clear();
    _navProgressNotifier.value = null;
    setState(() {
      _isNavigating = false;
      _activeNavInstruction = '';
      _remainingDistanceM = 0;
      _remainingTimeS = 0;
    });
    _showStatusPill('Navigation ended', icon: Icons.flag_rounded);
  }

  // --- Offline Maps Store ---
  void _openOfflineMapsDialog() {
    setState(() => _isLoadingOfflineStore = true);

    ContentStore.asyncGetStoreContentList(
      ContentType.roadMap,
      (err, items, isCached) {
        if (!mounted) return;
        setState(() {
          _isLoadingOfflineStore = false;
          _offlineItems = items;
        });

        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (ctx) => _buildOfflineBottomSheet(ctx),
        );
      },
    );
  }

  Widget _buildOfflineBottomSheet(BuildContext ctx) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(ctx).size.height * 0.65,
      decoration: BoxDecoration(
        color: isDark ? PujaColors.nightCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.download_for_offline_rounded,
                      color: PujaColors.festivalGold, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Offline Maps Store',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Download offline regional map packs for uninterrupted navigation during peak Puja crowd nights.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 14),
          // One-Click Kolkata Region Pre-Cache Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PujaColors.festivalGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PujaColors.festivalGold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.offline_pin_rounded, color: PujaColors.festivalGold, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kolkata Mega Puja Pack',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Pre-cache vector roads & 3D buildings for zero-stall offline panning.',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showStatusPill('✓ Kolkata offline vector cache verified active');
                  },
                  child: const Text('Verify', style: TextStyle(color: PujaColors.festivalGold, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _offlineItems.isEmpty
                ? Center(
                    child: Text(
                      _isLoadingOfflineStore
                          ? 'Loading regional packages...'
                          : 'Kolkata map is pre-cached and ready offline.',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _offlineItems.length,
                    itemBuilder: (context, index) {
                      final item = _offlineItems[index];
                      final sizeMb = (item.totalSize / (1024 * 1024)).toStringAsFixed(1);
                      return ListTile(
                        title: Text(
                          item.name.isNotEmpty ? item.name : 'West Bengal Region',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('$sizeMb MB · Magic Lane Offline Map'),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PujaColors.festivalGold,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            item.asyncDownload((err) {
                              if (err == GemError.success) {
                                _showStatusPill('✓ Map downloaded successfully!');
                              } else {
                                _showStatusPill('⚠ Download error: $err');
                              }
                            });
                            Navigator.pop(ctx);
                            _showStatusPill('📥 Starting download for ${item.name}...');
                          },
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Download'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final squadService = Provider.of<SquadService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pujo Parikrama (Magic Lane 3D)'),
        actions: [
          // Engine Switcher: Switch to 2D OSM Map
          IconButton(
            icon: const Icon(Icons.layers_outlined, color: Colors.white70),
            tooltip: 'Switch to 2D OSM Map',
            onPressed: () {
              HapticFeedback.lightImpact();
              GemKitConfig.isMagicLaneActive.value = false;
            },
          ),
          // 3D Perspective Toggle
          IconButton(
            icon: Icon(
              _is3DMode ? Icons.view_in_ar_rounded : Icons.map_outlined,
              color: _is3DMode ? PujaColors.goldBright : Colors.white70,
            ),
            tooltip: _is3DMode ? '3D View Enabled' : 'Switch to 3D View',
            onPressed: () {
              setState(() => _is3DMode = !_is3DMode);
              _mapController?.preferences.viewAngle = _is3DMode ? 35.0 : 0.0;
              _showStatusPill(
                _is3DMode ? '🏢 3D Buildings & Tilt Enabled' : '🗺️ 2D Flat View Enabled',
                icon: Icons.layers_outlined,
              );
            },
          ),
          // Offline Maps Store Button
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined, color: Colors.white70),
            tooltip: 'Download Offline Maps',
            onPressed: _openOfflineMapsDialog,
          ),
          // Search toggle
          IconButton(
            icon: Icon(
              _showMapSearchBar ? Icons.search_rounded : Icons.search_outlined,
              color: _showMapSearchBar ? PujaColors.goldBright : Colors.white70,
            ),
            tooltip: _showMapSearchBar ? 'Hide Search' : 'Search Pandals',
            onPressed: () {
              setState(() => _showMapSearchBar = !_showMapSearchBar);
            },
          ),
          // User profile avatar
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: _buildProfileAvatar(isDark),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Native Magic Lane Map Surface (Isolated RepaintBoundary + Stable Key)
          _IsolatedGemMapSurface(
            onMapCreated: _onMapCreated,
          ),

          // 2. Loading Indicator
          if (_isLoading)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(PujaColors.goldBright),
                  ),
                ),
              ),
            ),

          // 3. Top Floating Search & Zone Filter Bar
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showMapSearchBar) ...[
                  PandalSearchAutocomplete(
                    pandals: _pandals,
                    foodSpots: _foodSpots,
                    metroStations: _metroStations,
                    userLat: _userLat,
                    userLng: _userLng,
                    isFloatingOnMap: true,
                    hintText: 'Search 387 pandals, metro, food...',
                    onPandalSelected: (p) => _selectPandal(p),
                    onMetroSelected: (m) {
                      setState(() {
                        _showMetro = true;
                        _selectedMetroStation = m;
                      });
                      _updateMetroMarkers();
                      _centerOn(m.latitude, m.longitude, zoom: 16);
                      _showStatusPill('🚇 ${m.name}');
                    },
                    onFoodSpotSelected: (f) {
                      setState(() {
                        _showFood = true;
                        _selectedFoodSpot = f;
                      });
                      _updateFoodMarkers();
                      _centerOn(f.lat, f.lng, zoom: 16);
                      _showStatusPill('🍽️ ${f.name}');
                    },
                    onSubmitted: (_) => setState(() => _showMapSearchBar = false),
                  ),
                  const SizedBox(height: 8),
                ],
                _buildFilterPills(isDark, squadService),
              ],
            ),
          ),

          // 4. Turn-by-Turn Navigation Banner (Isolated ValueListenableBuilder Rebuild)
          if (_isNavigating)
            Positioned(
              top: _showMapSearchBar ? 150 : 80,
              left: 14,
              right: 14,
              child: ValueListenableBuilder<_NavProgressData?>(
                valueListenable: _navProgressNotifier,
                builder: (context, navData, _) {
                  return _buildNavigationBanner(isDark, navData);
                },
              ),
            ),

          // 5. Selected Metro / Food Spot Quick Card
          if (_selectedMetroStation != null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: _buildMetroCard(isDark),
            ),
          if (_selectedFoodSpot != null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: _buildFoodCard(isDark),
            ),

          // 6. Floating Action Controls (Right side)
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recenter / Follow GPS Button
                FloatingActionButton.small(
                  heroTag: 'gps_follow',
                  backgroundColor: _followUser ? PujaColors.festivalGold : (isDark ? PujaColors.nightCard : Colors.white),
                  foregroundColor: _followUser ? Colors.black : PujaColors.festivalGold,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (_userLat != null && _userLng != null) {
                      setState(() => _followUser = !_followUser);
                      if (_followUser) {
                        _mapController?.startFollowingPosition();
                        _centerOn(_userLat!, _userLng!, zoom: 16);
                        _showStatusPill('🧭 Following your location');
                      } else {
                        _mapController?.stopFollowingPosition();
                        _showStatusPill('Free-roam mode enabled');
                      }
                    } else {
                      _centerOn(GemKitConfig.defaultLatitude, GemKitConfig.defaultLongitude, zoom: 13);
                      _showStatusPill('Centered on Kolkata');
                    }
                  },
                  child: Icon(_followUser ? Icons.my_location_rounded : Icons.location_searching_rounded),
                ),
                const SizedBox(height: 10),
                // Recenter Kolkata
                FloatingActionButton.small(
                  heroTag: 'recenter_kolkata',
                  backgroundColor: isDark ? PujaColors.nightCard : Colors.white,
                  foregroundColor: PujaColors.festivalGold,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _centerOn(GemKitConfig.defaultLatitude, GemKitConfig.defaultLongitude, zoom: 13);
                    _showStatusPill('Centered on Kolkata');
                  },
                  child: const Icon(Icons.center_focus_strong_rounded),
                ),
              ],
            ),
          ),

          // 7. Floating Status Notification Pill (Isolated ValueListenableBuilder Rebuild)
          ValueListenableBuilder<_StatusPillData?>(
            valueListenable: _statusPillNotifier,
            builder: (context, pillData, _) {
              if (pillData == null) return const SizedBox.shrink();
              return Positioned(
                bottom: 30,
                left: 20,
                right: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black87 : Colors.grey[900]!)
                        .withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(pillData.icon,
                          color: pillData.color ?? PujaColors.goldBright, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pillData.message,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills(bool isDark, SquadService squadService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? PujaColors.nightCard : Colors.white).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3)),
        ],
        border: Border.all(color: PujaColors.festivalGold.withValues(alpha: 0.35), width: 1.2),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Custom Hopping Trail Chip
            _buildCustomTrailChip(isDark),
            const SizedBox(width: 6),

            // Metro toggle chip
            _buildToggleChip(
              label: 'Metro (41)',
              icon: Icons.subway_rounded,
              isActive: _showMetro,
              color: const Color(0xFF2979FF),
              onTap: () {
                setState(() => _showMetro = !_showMetro);
                _updateMetroMarkers();
                _showStatusPill(_showMetro ? '🚇 Metro Stations Shown' : 'Metro Layer Hidden');
              },
            ),
            const SizedBox(width: 6),

            // Food chip (deep-links to Food Spots on Pandals screen)
            _buildToggleChip(
              label: 'Food (66)',
              customIcon: PujaIcon.bhogSweets(
                size: 18,
                color: const Color(0xFFFF9100),
              ),
              isActive: false,
              color: const Color(0xFFFF9100),
              onTap: () {
                HapticFeedback.lightImpact();
                PandalListScreen.switchToCategory(PlaceCategory.foodSpot);
              },
            ),
            const SizedBox(width: 6),

            // 10km filter
            _buildToggleChip(
              label: 'Nearby 10km',
              icon: Icons.near_me_rounded,
              isActive: _filterNearby10Km,
              color: PujaColors.festivalGold,
              onTap: () {
                setState(() => _filterNearby10Km = !_filterNearby10Km);
                _recomputeVisiblePandals();
                _updatePandalMarkers();
                _showStatusPill(_filterNearby10Km ? '📍 Filtered to 10km radius' : 'Showing all pandals');
              },
            ),
            const SizedBox(width: 6),

            // Zone chips
            ...KolkataZone.values.map((zone) {
              final isSelected = _selectedZone == zone;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(zone.label),
                  selected: isSelected,
                  selectedColor: PujaColors.festivalGold.withValues(alpha: 0.25),
                  checkmarkColor: PujaColors.festivalGold,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? PujaColors.festivalGold : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  onSelected: (val) {
                    setState(() => _selectedZone = val ? zone : null);
                    _recomputeVisiblePandals();
                    _updatePandalMarkers();
                    _showStatusPill(val ? '📍 Switched to ${zone.label}' : 'Zone filter cleared');
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTrailChip(bool isDark) {
    return Consumer<CustomHoppingTrailService>(
      builder: (context, trailService, _) {
        final hasActive = trailService.hasActiveTrail;
        final trail = trailService.activeTrail;

        return Material(
          elevation: hasActive ? 3 : 0,
          color: hasActive
              ? PujaColors.festivalGold
              : (isDark ? PujaColors.nightSurface : Colors.grey.shade100),
          shape: StadiumBorder(
            side: BorderSide(
              color: hasActive
                  ? PujaColors.durgaRed
                  : PujaColors.festivalGold.withValues(alpha: 0.4),
              width: hasActive ? 1.5 : 1.0,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              HapticFeedback.selectionClick();
              CustomTrailPlannerDialog.show(
                context,
                initialLocation: _userLat != null && _userLng != null
                    ? ll.LatLng(_userLat!, _userLng!)
                    : null,
                initialLocationLabel: _userLat != null
                    ? 'My Live Location'
                    : null,
                onTrailStarted: () {
                  final firstStop = trailService.activeTrail?.currentTargetPandal;
                  if (firstStop != null) {
                    _centerOn(firstStop.lat, firstStop.lng, zoom: 16);
                    _showStatusPill('🚀 Trail started! Stop 1: ${firstStop.name}');
                  }
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: hasActive ? Colors.black87 : PujaColors.festivalGold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasActive
                        ? 'Trail (${trail!.visitedCount}/${trail.totalStops})'
                        : 'Plan Trail ⏱️',
                    style: TextStyle(
                      color: hasActive
                          ? Colors.black87
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontSize: 11,
                      fontWeight: hasActive ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleChip({
    required String label,
    IconData? icon,
    Widget? customIcon,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            customIcon ??
                (icon != null
                    ? Icon(icon, size: 14, color: isActive ? Colors.white : color)
                    : const SizedBox.shrink()),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBanner(bool isDark, [_NavProgressData? navData]) {
    final remainingM = navData?.distanceM ?? _remainingDistanceM;
    final remainingS = navData?.timeS ?? _remainingTimeS;
    final distKm = (remainingM / 1000).toStringAsFixed(1);
    final timeMin = (remainingS / 60).round();
    final instruction = (navData?.instruction.isNotEmpty ?? false)
        ? navData!.instruction
        : (_activeNavInstruction.isNotEmpty ? _activeNavInstruction : 'Follow walking route');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? PujaColors.nightCard : Colors.white).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
        border: Border.all(color: PujaColors.festivalGold, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: PujaColors.festivalGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.navigation_rounded, color: PujaColors.festivalGold, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  instruction,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$distKm km remaining · ~$timeMin min walk',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
            tooltip: 'End Navigation',
            onPressed: _cancelNavigation,
          ),
        ],
      ),
    );
  }

  Widget _buildMetroCard(bool isDark) {
    final m = _selectedMetroStation!;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? PujaColors.nightCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: m.line.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.subway_rounded, color: m.line.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${m.line.label} · Kolkata Metro', style: TextStyle(color: m.line.color, fontSize: 12)),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: m.line.color, foregroundColor: Colors.white),
              onPressed: () {
                _startTurnByTurnRoute(
                  destLat: m.latitude,
                  destLng: m.longitude,
                  destName: m.name,
                );
              },
              icon: const Icon(Icons.directions_walk, size: 16),
              label: const Text('Route'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard(bool isDark) {
    final f = _selectedFoodSpot!;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? PujaColors.nightCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9100).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: PujaIcon.bhogSweets(color: const Color(0xFFFF9100), size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(f.type, style: const TextStyle(color: Color(0xFFFF9100), fontSize: 12)),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9100),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _startTurnByTurnRoute(
                  destLat: f.lat,
                  destLng: f.lng,
                  destName: f.name,
                );
              },
              icon: const Icon(Icons.directions_walk, size: 16),
              label: const Text('Route'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(bool isDark) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final initial = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName![0].toUpperCase()
        : 'P';

    return GestureDetector(
      onTap: () => UserProfileSheet.show(context),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: PujaColors.festivalGold,
        child: Text(
          initial,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}

/// Platform View isolation container for the native Magic Lane Map surface.
///
/// Wraps [GemMap] with an explicit [RepaintBoundary] and a stable [Key].
/// This ensures sibling UI overlays (typing in the search bar, status notification pill
/// opacity fades, floating buttons) never invalidate or resize the native Android platform view,
/// maintaining a buttery smooth 60/120 FPS experience.
class _IsolatedGemMapSurface extends StatelessWidget {
  const _IsolatedGemMapSurface({
    required this.onMapCreated,
  }) : super(key: const ValueKey('main-gem-map'));

  final void Function(GemMapController) onMapCreated;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GemMap(
        androidViewMode: AndroidViewMode.auto,
        appAuthorization: GemKitConfig.apiToken,
        coordinates: Coordinates.fromLatLong(
          GemKitConfig.defaultLatitude,
          GemKitConfig.defaultLongitude,
        ),
        zoomLevel: 13,
        onMapCreated: onMapCreated,
      ),
    );
  }
}
