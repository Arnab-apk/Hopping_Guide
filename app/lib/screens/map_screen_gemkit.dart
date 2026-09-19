// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Route, Path;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart' hide Provider, Path;
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
import 'main_navigation_screen.dart';
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

  // Trail Routing State
  TaskHandler? _trailRoutingTaskHandler;
  TaskHandler? _gettingThereTaskHandler;
  String? _renderedTrailId;
  int? _lastRenderedVisitedCount;

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

  // Search Active & Overlay Coordination
  late final TextEditingController _mapSearchController;
  late final FocusNode _mapSearchFocusNode;
  bool _isSearchActive = false;

  String? _contextualMessage;
  IconData? _contextualIcon;
  Color? _contextualColor;
  Timer? _contextualTimer;

  void _handleSearchFocusOrTextChange() {
    final active = _mapSearchFocusNode.hasFocus || _mapSearchController.text.isNotEmpty;
    if (_isSearchActive != active) {
      if (mounted) {
        setState(() => _isSearchActive = active);
      }
      if (active) {
        _statusPillTimer?.cancel();
        _statusPillNotifier.value = null;
        _contextualTimer?.cancel();
        if (_contextualMessage != null) {
          setState(() => _contextualMessage = null);
        }
      }
    }
  }

  void _setContextualBanner(
    String message, {
    IconData? icon,
    Color? color,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (_isSearchActive) return;
    _contextualTimer?.cancel();
    if (mounted) {
      setState(() {
        _contextualMessage = message;
        _contextualIcon = icon;
        _contextualColor = color;
      });
    }
    _contextualTimer = Timer(duration, () {
      if (mounted && _contextualMessage == message) {
        setState(() => _contextualMessage = null);
      }
    });
  }

  void _clearContextualBanner() {
    _contextualTimer?.cancel();
    if (_contextualMessage != null && mounted) {
      setState(() => _contextualMessage = null);
    }
  }

  @override
  void initState() {
    super.initState();
    _mapSearchController = TextEditingController();
    _mapSearchFocusNode = FocusNode();
    _mapSearchFocusNode.addListener(_handleSearchFocusOrTextChange);
    _mapSearchController.addListener(_handleSearchFocusOrTextChange);
    WidgetsBinding.instance.addObserver(this);
    _repo = widget.repository ?? LocalAssetPandalRepository();

    // Listen to global external action requests (from cards/sheets)
    MapScreen.pendingPandalAction.addListener(_handlePendingPandalAction);
    MapScreen.pendingFoodSpotAction.addListener(_handlePendingFoodSpotAction);
    MapScreen.pendingMetroStationAction.addListener(_handlePendingMetroAction);

    // Listen to active custom hopping trail state
    CustomHoppingTrailService.instance.addListener(_handleTrailServiceChange);

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
    CustomHoppingTrailService.instance.removeListener(_handleTrailServiceChange);
    if (_trailRoutingTaskHandler != null) {
      RoutingService.cancelRoute(_trailRoutingTaskHandler!);
      _trailRoutingTaskHandler = null;
    }
    if (_gettingThereTaskHandler != null) {
      RoutingService.cancelRoute(_gettingThereTaskHandler!);
      _gettingThereTaskHandler = null;
    }
    _mapSearchFocusNode.removeListener(_handleSearchFocusOrTextChange);
    _mapSearchController.removeListener(_handleSearchFocusOrTextChange);
    _mapSearchFocusNode.dispose();
    _mapSearchController.dispose();
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
    if (_isSearchActive) return;
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
    // Stops in active custom trail are ALWAYS preserved
    if (CustomHoppingTrailService.instance.hasActiveTrail) {
      final active = CustomHoppingTrailService.instance.activeTrail;
      if (active != null) {
        for (final stop in active.stops) {
          if (!list.any((p) => p.id == stop.id)) {
            list = [...list, stop];
          }
        }
      }
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

    if (CustomHoppingTrailService.instance.hasActiveTrail) {
      _renderTrailRoute(CustomHoppingTrailService.instance.activeTrail!);
    }
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

  // --- Native Road-Following Trail Routing (GemKit Pedestrian Profile) ---

  void _handleTrailServiceChange() {
    if (!mounted) return;
    final trailService = CustomHoppingTrailService.instance;
    final trail = trailService.activeTrail;

    if (!trailService.hasActiveTrail || trail == null) {
      _clearTrailRoute();
      return;
    }

    // Re-render when trail ID or visited stop count changes
    if (_renderedTrailId != trail.id ||
        _lastRenderedVisitedCount != trail.visitedCount) {
      _renderTrailRoute(trail);
    } else {
      setState(() {});
    }
  }

  void _clearTrailRoute() {
    if (_trailRoutingTaskHandler != null) {
      RoutingService.cancelRoute(_trailRoutingTaskHandler!);
      _trailRoutingTaskHandler = null;
    }
    if (_gettingThereTaskHandler != null) {
      RoutingService.cancelRoute(_gettingThereTaskHandler!);
      _gettingThereTaskHandler = null;
    }
    _renderedTrailId = null;
    _lastRenderedVisitedCount = null;
    if (!_isNavigating) {
      _mapController?.preferences.routes.clear();
    }
    if (mounted) setState(() {});
  }

  Future<void> _renderTrailRoute(ActiveCustomTrail trail) async {
    final controller = _mapController;
    if (controller == null) return;

    _renderedTrailId = trail.id;
    _lastRenderedVisitedCount = trail.visitedCount;

    // Cancel any ongoing calculations
    if (_trailRoutingTaskHandler != null) {
      RoutingService.cancelRoute(_trailRoutingTaskHandler!);
      _trailRoutingTaskHandler = null;
    }
    if (_gettingThereTaskHandler != null) {
      RoutingService.cancelRoute(_gettingThereTaskHandler!);
      _gettingThereTaskHandler = null;
    }

    // Unvisited stops in visit order (curated circuit order or optimizer resolved order)
    final unvisitedStops = trail.stops
        .where((s) => !trail.visitedPandalIds.contains(s.id))
        .toList();

    if (unvisitedStops.isEmpty) {
      _clearTrailRoute();
      return;
    }

    final routePreferences = RoutePreferences(
      transportMode: RouteTransportMode.pedestrian,
      routeType: RouteType.fastest,
    );

    // Prepare ordered waypoints for "Your trail"
    final trailWaypoints = <Landmark>[];
    final startCoord = trail.startPoint;
    final firstUnvisited = unvisitedStops.first;

    if (trail.visitedCount == 0) {
      // Trail just started: include startPoint if separated from first stop
      final distToFirst = haversineMeters(
        startCoord.latitude,
        startCoord.longitude,
        firstUnvisited.lat,
        firstUnvisited.lng,
      );
      if (distToFirst > 15.0) {
        trailWaypoints.add(
          Landmark()
            ..name = trail.startingAddress.isNotEmpty ? trail.startingAddress : 'Trail Start'
            ..coordinates = Coordinates.fromLatLong(startCoord.latitude, startCoord.longitude),
        );
      }
    } else if (_userLat != null && _userLng != null) {
      // User is en route: route from current live location to remaining stops
      trailWaypoints.add(
        Landmark()
          ..name = 'My Location'
          ..coordinates = Coordinates.fromLatLong(_userLat!, _userLng!),
      );
    }

    for (final s in unvisitedStops) {
      trailWaypoints.add(
        Landmark()
          ..name = s.name
          ..coordinates = Coordinates.fromLatLong(s.lat, s.lng),
      );
    }

    if (trailWaypoints.length < 2) {
      final refLat = _userLat ?? startCoord.latitude;
      final refLng = _userLng ?? startCoord.longitude;
      trailWaypoints.insert(
        0,
        Landmark()
          ..name = 'Current Location'
          ..coordinates = Coordinates.fromLatLong(refLat, refLng),
      );
    }

    final liveLat = _userLat;
    final liveLng = _userLng;
    final bool needsGettingThere = trail.visitedCount == 0 &&
        liveLat != null &&
        liveLng != null &&
        haversineMeters(liveLat, liveLng, startCoord.latitude, startCoord.longitude) > 60.0;

    final routesToCenter = <Route>[];

    _trailRoutingTaskHandler = RoutingService.calculateRoute(
      trailWaypoints,
      routePreferences,
      (err, routes) {
        if (!mounted) return;
        if (err == GemError.success && routes.isNotEmpty) {
          final mainRoute = routes.first;

          controller.preferences.routes.clear();
          // true = main route -> renders highlighted
          controller.preferences.routes.add(mainRoute, true);
          routesToCenter.add(mainRoute);

          final timeDist = mainRoute.getTimeDistance();
          final double distKm = double.parse(
            (timeDist.totalDistanceM / 1000.0).toStringAsFixed(1),
          );
          final int walkingMins = (timeDist.totalTimeS / 60).round();
          final int dwellMins = unvisitedStops.length * 15;
          final int totalEstMinutes = walkingMins + dwellMins;

          List<ll.LatLng>? roadCoords;
          try {
            final geoJsonStr = mainRoute.exportAs(PathFileFormat.geoJson);
            roadCoords = _parseGeoJsonCoordinates(geoJsonStr);
          } catch (e) {
            debugPrint('[GemKit TrailRoute] GeoJSON parsing: $e');
          }

          CustomHoppingTrailService.instance.updateRoutedStats(
            distanceKm: distKm,
            durationMinutes: totalEstMinutes,
            polyline: roadCoords,
            remainingDistanceKm: distKm,
            remainingDurationMinutes: totalEstMinutes,
          );

          controller.centerOnRoutes(routes: routesToCenter);

          // Segment 1: "Getting there" (Live location -> Trail's start point)
          // Muted line (bMainRoute: false)
          if (needsGettingThere) {
            final gettingThereWaypoints = [
              Landmark()
                ..name = 'My Location'
                ..coordinates = Coordinates.fromLatLong(liveLat, liveLng),
              Landmark()
                ..name = trail.startingAddress.isNotEmpty ? trail.startingAddress : 'Trail Start'
                ..coordinates = Coordinates.fromLatLong(startCoord.latitude, startCoord.longitude),
            ];

            _gettingThereTaskHandler = RoutingService.calculateRoute(
              gettingThereWaypoints,
              routePreferences,
              (gErr, gRoutes) {
                if (!mounted) return;
                if (gErr == GemError.success && gRoutes.isNotEmpty) {
                  final gRoute = gRoutes.first;
                  // false = not main -> renders muted
                  controller.preferences.routes.add(gRoute, false);
                  routesToCenter.add(gRoute);
                  controller.centerOnRoutes(routes: routesToCenter);

                  final gTimeDist = gRoute.getTimeDistance();
                  final combinedDistKm = double.parse(
                    ((timeDist.totalDistanceM + gTimeDist.totalDistanceM) / 1000.0).toStringAsFixed(1),
                  );
                  final combinedMins = totalEstMinutes + (gTimeDist.totalTimeS / 60).round();

                  CustomHoppingTrailService.instance.updateRoutedStats(
                    distanceKm: combinedDistKm,
                    durationMinutes: combinedMins,
                    polyline: roadCoords,
                    remainingDistanceKm: combinedDistKm,
                    remainingDurationMinutes: combinedMins,
                  );
                }
              },
            );
          }
        } else {
          debugPrint('[GemKit TrailRoute] calculateRoute error: $err');
        }
      },
    );
  }

  List<ll.LatLng> _parseGeoJsonCoordinates(String geoJsonStr) {
    final result = <ll.LatLng>[];
    try {
      final decoded = jsonDecode(geoJsonStr);
      if (decoded is Map<String, dynamic>) {
        if (decoded['features'] is List && (decoded['features'] as List).isNotEmpty) {
          for (final f in decoded['features']) {
            final geom = f['geometry'];
            if (geom is Map && geom['coordinates'] is List) {
              for (final pt in geom['coordinates']) {
                if (pt is List && pt.length >= 2) {
                  result.add(ll.LatLng((pt[1] as num).toDouble(), (pt[0] as num).toDouble()));
                }
              }
            }
          }
        } else if (decoded['coordinates'] is List) {
          for (final pt in decoded['coordinates']) {
            if (pt is List && pt.length >= 2) {
              result.add(ll.LatLng((pt[1] as num).toDouble(), (pt[0] as num).toDouble()));
            }
          }
        }
      }
    } catch (_) {}
    return result;
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
    final trailService = Provider.of<CustomHoppingTrailService>(context);
    final bool isTrailActive = trailService.hasActiveTrail;
    final activeTrail = trailService.activeTrail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uma (Magic Lane 3D)'),
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
          // Search button
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: PujaColors.goldBright,
            ),
            tooltip: 'Search Pandals',
            onPressed: () {
              _mapSearchFocusNode.requestFocus();
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
                PandalSearchAutocomplete(
                  controller: _mapSearchController,
                  focusNode: _mapSearchFocusNode,
                  pandals: _pandals,
                  foodSpots: _foodSpots,
                  metroStations: _metroStations,
                  userLat: _userLat,
                  userLng: _userLng,
                  isFloatingOnMap: true,
                  hintText: 'Search 387 pandals, metro, food...',
                  onPandalSelected: (p) {
                    _mapSearchController.clear();
                    FocusScope.of(context).unfocus();
                    _selectPandal(p);
                  },
                  onMetroSelected: (m) {
                    _mapSearchController.clear();
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _showMetro = true;
                      _selectedMetroStation = m;
                    });
                    _updateMetroMarkers();
                    _centerOn(m.latitude, m.longitude, zoom: 16);
                    _showStatusPill('🚇 ${m.name}');
                  },
                  onFoodSpotSelected: (f) {
                    _mapSearchController.clear();
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _showFood = true;
                      _selectedFoodSpot = f;
                    });
                    _updateFoodMarkers();
                    _centerOn(f.lat, f.lng, zoom: 16);
                    _showStatusPill('🍽️ ${f.name}');
                  },
                  onSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                  },
                ),
                const SizedBox(height: 8),
                if (!_isSearchActive) ...[
                  isTrailActive && activeTrail != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: (isDark ? PujaColors.nightCard : Colors.white)
                                .withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
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
                          child: _buildTrailSummaryBar(
                            context,
                            activeTrail,
                            trailService,
                            isDark,
                          ),
                        )
                      : _buildFilterPills(isDark, squadService),
                  if (_contextualMessage != null) ...[
                    const SizedBox(height: 6),
                    _buildContextualBanner(isDark),
                  ],
                ],
              ],
            ),
          ),

          // 4. Turn-by-Turn Navigation Banner (Isolated ValueListenableBuilder Rebuild)
          if (_isNavigating)
            Positioned(
              top: 150,
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

  Widget _buildTrailSummaryBar(
    BuildContext context,
    ActiveCustomTrail trail,
    CustomHoppingTrailService trailService,
    bool isDark,
  ) {
    double remainingDistKm = trail.remainingRoutedDistanceKm ?? 0.0;
    int remainingMin = trail.remainingRoutedDurationMinutes ?? 0;
    final unvisitedStops = trail.stops
        .where((s) => !trail.visitedPandalIds.contains(s.id))
        .toList();

    if (trail.remainingRoutedDistanceKm == null) {
      if (unvisitedStops.isNotEmpty) {
        final refLat = _userLat ?? trail.startPoint.latitude;
        final refLng = _userLng ?? trail.startPoint.longitude;
        var prev = ll.LatLng(refLat, refLng);
        for (final s in unvisitedStops) {
          final dMeters = haversineMeters(
            prev.latitude,
            prev.longitude,
            s.lat,
            s.lng,
          );
          remainingDistKm += dMeters / 1000.0;
          prev = ll.LatLng(s.lat, s.lng);
        }
      }

      remainingMin =
          ((remainingDistKm / 4.2) * 60 + (unvisitedStops.length * 15)).round();
    }

    final String distStr = remainingDistKm < 1.0
        ? '${(remainingDistKm * 1000).round()}m'
        : '${remainingDistKm.toStringAsFixed(1)} km';

    final target = trail.currentTargetPandal;

    return Row(
      children: [
        // Trail Icon / Mode Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: PujaColors.festivalGold.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: PujaColors.festivalGold.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.route_rounded,
                size: 14,
                color: PujaColors.festivalGold,
              ),
              const SizedBox(width: 4),
              Text(
                'TRAIL',
                style: GoogleFonts.plusJakartaSans(
                  color: PujaColors.festivalGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Trail Metrics: Distance · Time · Stops
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (target != null) {
                _centerOn(target.lat, target.lng, zoom: 16);
                _selectPandal(target);
              } else {
                _centerOn(trail.startPoint.latitude, trail.startPoint.longitude, zoom: 14);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$distStr · ${remainingMin > 0 ? "$remainingMin min left" : "Finished"}',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${trail.visitedCount}/${trail.totalStops})',
                      style: const TextStyle(
                        color: PujaColors.festivalGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (target != null)
                  Text(
                    'Next: ${target.name}',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),

        // Quick Mark-Visited Action Button (if target pending)
        if (target != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF00C853),
              size: 20,
            ),
            tooltip: 'Mark ${target.name} Visited',
            onPressed: () {
              HapticFeedback.lightImpact();
              trailService.recordAutoVisit(target);
              _showStatusPill(
                '✓ Visited ${target.name}!',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF00C853),
              );
            },
          ),

        // Exit Trail Mode Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.selectionClick();
              trailService.endTrail();
              _clearTrailRoute();
              _showStatusPill(
                'Exited trail mode · Browse restored',
                icon: Icons.map_outlined,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF1744).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFF1744).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: Color(0xFFFF1744),
                  ),
                  SizedBox(width: 3),
                  Text(
                    'Exit',
                    style: TextStyle(
                      color: Color(0xFFFF1744),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
            // Live Squad Status Chip
            if (squadService.hasActiveSquad) ...[
              _buildSquadStatusChip(isDark, squadService),
              const SizedBox(width: 6),
            ],
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
                if (_showMetro) {
                  _setContextualBanner(
                    '🚇 Showing 40+ Kolkata Metro stations on map',
                    icon: Icons.subway_rounded,
                    color: const Color(0xFF2979FF),
                  );
                } else {
                  _clearContextualBanner();
                }
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
                if (_filterNearby10Km) {
                  _setContextualBanner(
                    '📍 Filtered to 10km radius',
                    icon: Icons.near_me_rounded,
                    color: PujaColors.festivalGold,
                  );
                } else {
                  _clearContextualBanner();
                }
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
                    if (val) {
                      _setContextualBanner(
                        '📍 Switched to ${zone.label}',
                        icon: Icons.location_on_rounded,
                        color: PujaColors.festivalGold,
                      );
                    } else {
                      _setContextualBanner(
                        'Showing all ${_pandals.length} pandals across Kolkata & Suburbs',
                        icon: Icons.auto_awesome_rounded,
                        color: PujaColors.festivalGold,
                      );
                    }
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildContextualBanner(bool isDark) {
    if (_contextualMessage == null) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxWidth: 540),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E1E24) : Colors.white).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (_contextualColor ?? PujaColors.festivalGold).withValues(alpha: 0.55),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_contextualIcon != null) ...[
            Icon(
              _contextualIcon,
              size: 15,
              color: _contextualColor ?? PujaColors.festivalGold,
            ),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              _contextualMessage!,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _clearContextualBanner,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
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

  Widget _buildSquadStatusChip(bool isDark, SquadService squadService) {
    final companions = squadService.companionMembers;
    final count = companions.length + 1;
    final label = companions.isEmpty ? 'Squad' : 'Squad ($count)';

    return Material(
      elevation: 1.5,
      color: isDark ? const Color(0xFF132A1C) : const Color(0xFFE8F5E9),
      shape: StadiumBorder(
        side: BorderSide(
          color: const Color(0xFF00E676).withValues(alpha: 0.7),
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          HapticFeedback.selectionClick();
          _showSquadDetailsSheet(context, squadService, isDark);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7.5,
                height: 7.5,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00E676),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? const Color(0xFF69F0AE) : const Color(0xFF1B5E20),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSquadDetailsSheet(BuildContext context, SquadService squadService, bool isDark) {
    final companions = squadService.companionMembers;
    final squadCode = squadService.squadCode ?? 'SQUAD';
    final userLat = _userLat;
    final userLng = _userLng;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181318) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E676),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00E676),
                          blurRadius: 6,
                          spreadRadius: 1.5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hopping Squad Active',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    visualDensity: VisualDensity.compact,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: PujaColors.festivalGold.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_rounded, size: 20, color: PujaColors.festivalGold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INVITE CODE',
                            style: TextStyle(
                              fontSize: 9.5,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            squadCode,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: isDark ? PujaColors.festivalGold : const Color(0xFFB8860B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Clipboard.setData(ClipboardData(text: squadCode));
                        Navigator.pop(ctx);
                        _showStatusPill('Invite code $squadCode copied!');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 15),
                      label: const Text('Copy'),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? PujaColors.festivalGold : const Color(0xFFB8860B),
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (companions.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF221A22) : const Color(0xFFFFF9E6))
                        .withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: PujaColors.festivalGold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: PujaColors.festivalGold.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          size: 20,
                          color: PujaColors.festivalGold,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Waiting for friends...',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Share your code to let companions join and view live GPS locations.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  'Companions Nearby (${companions.length})',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: companions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final member = companions[idx];
                      final dist = (userLat != null && userLng != null)
                          ? haversineMeters(userLat, userLng, member.latitude, member.longitude)
                          : null;
                      final distStr = dist != null
                          ? (dist < 1000
                              ? '${dist.round()} m away'
                              : '${(dist / 1000).toStringAsFixed(1)} km away')
                          : 'Live location';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: member.avatarColor,
                              backgroundImage: (member.photoUrl != null && member.photoUrl!.isNotEmpty)
                                  ? NetworkImage(member.photoUrl!)
                                  : null,
                              child: (member.photoUrl == null || member.photoUrl!.isEmpty)
                                  ? Text(
                                      member.initials,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    distStr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF00E676),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                HapticFeedback.selectionClick();
                                _centerOn(member.latitude, member.longitude, zoom: 16);
                              },
                              icon: const Icon(Icons.near_me_rounded, size: 14),
                              label: const Text('Locate'),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: PujaColors.festivalGold,
                                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    HapticFeedback.selectionClick();
                    MainNavigationScreen.switchTab(context, 3);
                  },
                  icon: const Icon(Icons.groups_rounded, size: 18),
                  label: const Text(
                    'Open Hopping Squad Hub',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PujaColors.durgaRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
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
