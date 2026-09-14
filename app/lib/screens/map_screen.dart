import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kolkata_puja/models/metro_station.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../models/app_user.dart';
import '../models/pandal.dart';
import '../models/squad_member.dart';
import '../repositories/local_pandal_repository.dart';
import '../repositories/metro_repository.dart';
import '../repositories/pandal_repository.dart';
import '../repositories/supplementary_repository.dart';
import '../services/auth_service.dart';
import '../services/custom_hopping_trail_service.dart';
import '../services/location_service.dart';
import '../services/routing_service.dart';
import '../services/squad_service.dart';
import '../services/theme_service.dart';
import '../utils/constants.dart';
import '../utils/haversine.dart';
import '../utils/pandal_spatial_cluster.dart';
import '../utils/responsive.dart';
import '../widgets/crowd_badge.dart';
import '../widgets/custom_trail_planner_dialog.dart';
import '../widgets/pandal_detail_sheet.dart';
import '../widgets/pandal_search_autocomplete.dart';
import '../widgets/app_tutorial_dialog.dart';
import '../widgets/animated_fade_slide.dart';
import '../widgets/durga_face_icon.dart';
import '../widgets/user_profile_sheet.dart';
import 'main_navigation_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.repository});

  final PandalRepository? repository;

  /// Global notifier to request an in-app walking route or centering on a target food spot.
  static final ValueNotifier<({FoodSpot spot, bool traceRoute})?>
  pendingFoodSpotAction = ValueNotifier<({FoodSpot spot, bool traceRoute})?>(
    null,
  );

  /// Helper to route to a food spot from any screen without external apps
  static void routeToFoodSpot(BuildContext context, FoodSpot spot) {
    pendingFoodSpotAction.value = (spot: spot, traceRoute: true);
    MainNavigationScreen.switchTab(context, 0);
  }

  /// Helper to center on a food spot from any screen
  static void centerOnFoodSpot(BuildContext context, FoodSpot spot) {
    pendingFoodSpotAction.value = (spot: spot, traceRoute: false);
    MainNavigationScreen.switchTab(context, 0);
  }

  /// Global notifier to request an in-app walking route or centering on a target metro station.
  static final ValueNotifier<({MetroStation station, bool traceRoute})?>
  pendingMetroStationAction =
      ValueNotifier<({MetroStation station, bool traceRoute})?>(null);

  /// Helper to route to a metro station from any screen
  static void routeToMetroStation(BuildContext context, MetroStation station) {
    pendingMetroStationAction.value = (station: station, traceRoute: true);
    MainNavigationScreen.switchTab(context, 0);
  }

  /// Helper to center on a metro station from any screen
  static void centerOnMetroStation(BuildContext context, MetroStation station) {
    pendingMetroStationAction.value = (station: station, traceRoute: false);
    MainNavigationScreen.switchTab(context, 0);
  }

  /// Global notifier to request an in-app walking route or centering on a target pandal.
  static final ValueNotifier<({Pandal pandal, bool traceRoute})?>
  pendingPandalAction = ValueNotifier<({Pandal pandal, bool traceRoute})?>(
    null,
  );

  /// Helper to route to a pandal from any screen without external apps
  static void routeToPandal(BuildContext context, Pandal pandal) {
    pendingPandalAction.value = (pandal: pandal, traceRoute: true);
    MainNavigationScreen.switchTab(context, 0);
  }

  /// Helper to center on a pandal from any screen
  static void centerOnPandal(BuildContext context, Pandal pandal) {
    pendingPandalAction.value = (pandal: pandal, traceRoute: false);
    MainNavigationScreen.switchTab(context, 0);
  }

  @override
  State<MapScreen> createState() => _MapScreenState();
}

const ColorFilter _kDarkMatrix = ColorFilter.matrix(<double>[
  -0.85,
  0.0,
  0.0,
  0.0,
  255.0,
  0.0,
  -0.85,
  0.0,
  0.0,
  255.0,
  0.0,
  0.0,
  -0.85,
  0.0,
  255.0,
  0.0,
  0.0,
  0.0,
  1.0,
  0.0,
]);

/// Throttles tile updates by 50ms with trailing emission and filters out tap & zero-movement events.
/// Stops rapid panning/swiping from queueing dead tile HTTP requests.
TileUpdateTransformer _throttleTileUpdates() {
  return StreamTransformer.fromBind((Stream<TileUpdateEvent> tileUpdateEvents) {
    return tileUpdateEvents
        // Only trigger a tile fetch if the user stops/slows down for 50ms
        // This stops rapid swipes from queueing 100s of dead HTTP requests
        .throttleTime(const Duration(milliseconds: 50), trailing: true)
        // Ignore micro-movements and taps
        .where((event) => !event.wasTriggeredByTap() && event.zoom != 0);
  });
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late final MapController _mapController;
  late final PandalRepository _repo;
  final SupplementaryRepository _suppRepo = SupplementaryRepository();
  late final AnimationController _pulseController;
  AnimationController? _cameraMoveController;

  List<Pandal> _pandals = [];
  List<FoodSpot> _foodSpots = [];
  bool _showFoodSpots = false;
  bool _showMetroStations = false;
  bool _filterNearby10Km = false;
  bool _showMapSearchBar = true;
  bool _isLoading = true;

  KolkataZone? _selectedZone;
  Pandal? _selectedPandal;
  SquadMember? _selectedSquadMember;
  FoodSpot? _selectedFoodSpot;
  MetroStation? _selectedMetroStation;
  Position? _userPosition;

  LatLng? get _effectiveUserLocation {
    // If a walking route is active, ensure the user's DP is anchored to the path's starting point
    // when GPS coordinates are still resolving or if the user is testing from outside Kolkata (> 70 km).
    if (_highlightedRoute != null && _highlightedRoute!.points.isNotEmpty) {
      if (_userPosition == null) {
        return _highlightedRoute!.points.first;
      }
      final distToKolkata = haversineMeters(
        _userPosition!.latitude,
        _userPosition!.longitude,
        AppConfig.defaultLat,
        AppConfig.defaultLng,
      );
      if (distToKolkata > 70000) {
        return _highlightedRoute!.points.first;
      }
      return LatLng(_userPosition!.latitude, _userPosition!.longitude);
    }

    if (_userPosition != null) {
      return LatLng(_userPosition!.latitude, _userPosition!.longitude);
    }

    return null;
  }

  // Live Location & Path Highlight States
  WalkingRoute? _highlightedRoute;
  bool _isCalculatingRoute = false;
  bool _followUser = false;
  bool _isTrailHudExpanded = false;

  // Floating Status Pill State (Minimal Negative Feedback)
  String? _statusPillMessage;
  IconData? _statusPillIcon;
  Color? _statusPillColor;
  Timer? _statusPillTimer;

  void _showStatusPill(
    String message, {
    IconData? icon,
    Color? color,
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    _statusPillTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _statusPillMessage = message;
      _statusPillIcon = icon ?? Icons.info_outline_rounded;
      _statusPillColor = color;
    });
    _statusPillTimer = Timer(duration, () {
      if (mounted) {
        setState(() => _statusPillMessage = null);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _repo = widget.repository ?? LocalAssetPandalRepository();
    MapScreen.pendingFoodSpotAction.addListener(_onPendingFoodSpotAction);
    if (MapScreen.pendingFoodSpotAction.value != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onPendingFoodSpotAction(),
      );
    }
    MapScreen.pendingPandalAction.addListener(_onPendingPandalAction);
    if (MapScreen.pendingPandalAction.value != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onPendingPandalAction(),
      );
    }
    MapScreen.pendingMetroStationAction.addListener(
      _onPendingMetroStationAction,
    );
    if (MapScreen.pendingMetroStationAction.value != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onPendingMetroStationAction(),
      );
    }
    _loadData();
    _startContinuousTracking();
  }

  @override
  void dispose() {
    MapScreen.pendingFoodSpotAction.removeListener(_onPendingFoodSpotAction);
    MapScreen.pendingPandalAction.removeListener(_onPendingPandalAction);
    MapScreen.pendingMetroStationAction.removeListener(
      _onPendingMetroStationAction,
    );
    _statusPillTimer?.cancel();
    LocationService.instance.stopLiveTracking();
    _cameraMoveController?.stop();
    _cameraMoveController?.dispose();
    _cameraMoveController = null;
    _pulseController.dispose();
    super.dispose();
  }

  void _onPendingFoodSpotAction() {
    final action = MapScreen.pendingFoodSpotAction.value;
    if (action != null) {
      MapScreen.pendingFoodSpotAction.value = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (action.traceRoute) {
          _highlightRouteToFoodSpot(action.spot);
        } else {
          _selectFoodSpot(action.spot);
        }
      });
    }
  }

  void _onPendingMetroStationAction() {
    final action = MapScreen.pendingMetroStationAction.value;
    if (action != null) {
      MapScreen.pendingMetroStationAction.value = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (action.traceRoute) {
          _highlightRouteToMetroStation(action.station);
        } else {
          _selectMetroStation(action.station);
        }
      });
    }
  }

  void _selectMetroStation(MetroStation station) {
    HapticFeedback.selectionClick();
    _animatedMapMove(
      LatLng(station.latitude, station.longitude),
      (_mapController.camera.zoom < 16.0 ? 16.0 : _mapController.camera.zoom),
    );
    setState(() {
      _selectedMetroStation = station;
      _selectedPandal = null;
      _selectedSquadMember = null;
      _selectedFoodSpot = null;
    });
  }

  void _onPendingPandalAction() {
    final action = MapScreen.pendingPandalAction.value;
    if (action != null) {
      MapScreen.pendingPandalAction.value = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _selectPandal(action.pandal);
        if (action.traceRoute) {
          _highlightRouteTo(action.pandal);
        }
      });
    }
  }

  void _selectPandal(Pandal pandal) => _onPandalSelectedFromSearch(pandal);

  void _selectFoodSpot(FoodSpot spot) {
    if (_followUser) {
      setState(() => _followUser = false);
    }
    setState(() {
      _selectedFoodSpot = spot;
      _selectedPandal = null;
      _selectedSquadMember = null;
      _showFoodSpots = true;
    });
    _animatedMapMove(LatLng(spot.lat, spot.lng), 16.5);
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    _cameraMoveController?.stop();
    _cameraMoveController?.dispose();

    final camera = _mapController.camera;
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    _cameraMoveController = controller;

    controller.addListener(() {
      final t = Curves.fastOutSlowIn.transform(controller.value);
      _mapController.move(
        LatLng(latTween.transform(t), lngTween.transform(t)),
        zoomTween.transform(t),
      );
      _mapController.rotate(0.0);
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (_cameraMoveController == controller) {
          _cameraMoveController = null;
        }
        controller.dispose();
      }
    });

    controller.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([_repo.all(), _suppRepo.getFoodSpots()]);

    if (!mounted) return;
    setState(() {
      _pandals = results[0] as List<Pandal>;
      _foodSpots = results[1] as List<FoodSpot>;
      _isLoading = false;
    });
  }

  void _startContinuousTracking() {
    LocationService.instance.startLiveTracking(
      onLocationChanged: (pos) {
        if (!mounted) return;
        setState(() => _userPosition = pos);
        SquadService.instance.updateUserLocation(pos.latitude, pos.longitude);
        if (_followUser) {
          _animatedMapMove(
            LatLng(pos.latitude, pos.longitude),
            _mapController.camera.zoom < 15.0
                ? 15.5
                : _mapController.camera.zoom,
          );
        }
      },
    );
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

  void _toggleFollowUser() async {
    HapticFeedback.lightImpact();
    if (_userPosition == null) {
      await _tryGetLocation();
    }

    if (!mounted) return;

    if (_userPosition != null) {
      setState(() => _followUser = !_followUser);
      if (_followUser) {
        _animatedMapMove(
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
          16.0,
        );
        _showStatusPill(
          '🧭 Live Tracking: Following your location',
          icon: Icons.my_location_rounded,
        );
      } else {
        _showStatusPill('Free-roam mode enabled', icon: Icons.explore_outlined);
      }
    } else {
      _animatedMapMove(
        const LatLng(AppConfig.defaultLat, AppConfig.defaultLng),
        AppConfig.defaultZoom,
      );
    }
  }

  void _onPandalSelectedFromSearch(Pandal pandal) {
    // 1. Auto-harmonize active filter if search target is outside current bounds
    if (_filterNearby10Km) {
      final center = _get10KmReferenceCenter();
      final dist = haversineMeters(
        center.latitude,
        center.longitude,
        pandal.lat,
        pandal.lng,
      );
      if (dist > 10000) {
        setState(() {
          _filterNearby10Km = false;
          _selectedZone = pandal.zone;
        });
        _showStatusPill(
          '📍 Filter adjusted to ${pandal.zone.label}',
          icon: Icons.tune_rounded,
          color: PujaColors.festivalGold,
        );
      }
    } else if (_selectedZone != null && _selectedZone != pandal.zone) {
      setState(() {
        _selectedZone = pandal.zone;
      });
      _showStatusPill(
        '📍 Switched zone to ${pandal.zone.label}',
        icon: Icons.tune_rounded,
        color: PujaColors.festivalGold,
      );
    }

    // 2. Pause live GPS tracking so camera isn't yanked back
    if (_followUser) {
      setState(() => _followUser = false);
    }

    _animatedMapMove(LatLng(pandal.lat, pandal.lng), 16.5);
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedPandal = pandal;
      _selectedSquadMember = null;
      _selectedFoodSpot = null;
      _selectedMetroStation = null;
      _showMapSearchBar = false;
    });
    _highlightRouteTo(pandal);
    _showStatusPill(
      '📍 Found ${pandal.name}',
      icon: Icons.place_rounded,
      color: PujaColors.festivalGold,
    );
  }

  void _onMetroSelectedFromSearch(MetroStation station) {
    HapticFeedback.mediumImpact();
    if (_followUser) {
      setState(() => _followUser = false);
    }

    _animatedMapMove(LatLng(station.latitude, station.longitude), 16.2);
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedMetroStation = station;
      _selectedPandal = null;
      _selectedSquadMember = null;
      _selectedFoodSpot = null;
      _highlightedRoute = null;
      _showMapSearchBar = false;
    });

    _showStatusPill(
      '🚇 ${station.name} · ${station.line.label}',
      icon: Icons.subway_rounded,
      color: station.line.color,
    );
  }

  void _onFoodSpotSelectedFromSearch(FoodSpot spot) {
    HapticFeedback.mediumImpact();
    if (_followUser) {
      setState(() => _followUser = false);
    }

    _animatedMapMove(LatLng(spot.lat, spot.lng), 16.8);
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedFoodSpot = spot;
      _showFoodSpots = true;
      _selectedPandal = null;
      _selectedSquadMember = null;
      _selectedMetroStation = null;
      _showMapSearchBar = false;
    });

    _showStatusPill(
      '🍽️ Found ${spot.name}',
      icon: Icons.restaurant_rounded,
      color: const Color(0xFFFF9100),
    );
  }

  Future<void> _highlightRouteToMetroStation(MetroStation station) async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    var userPos = _userPosition;
    userPos ??= await LocationService.instance.currentPosition();

    final double userLat = userPos?.latitude ?? AppConfig.defaultLat;
    final double userLng = userPos?.longitude ?? AppConfig.defaultLng;

    final distToKolkata = haversineMeters(
      userLat,
      userLng,
      AppConfig.defaultLat,
      AppConfig.defaultLng,
    );
    final bool isFarAway = distToKolkata > 70000;

    final refLat = (isFarAway || userPos == null) ? AppConfig.defaultLat : userLat;
    final refLng = (isFarAway || userPos == null) ? AppConfig.defaultLng : userLng;
    final start = LatLng(refLat, refLng);
    final dest = LatLng(station.latitude, station.longitude);

    setState(() {
      if (userPos != null) _userPosition = userPos;
      _isCalculatingRoute = true;
      _selectedMetroStation = station;
      _selectedPandal = null;
      _selectedSquadMember = null;
      _selectedFoodSpot = null;
      _followUser = false;
      _showMapSearchBar = false;
    });

    final route = await RoutingService.instance.getWalkingRouteToPoint(
      start: start,
      destination: dest,
      destinationName: station.name,
    );

    if (!mounted) return;

    setState(() {
      _highlightedRoute = route;
      _isCalculatingRoute = false;
      _showMapSearchBar = false;
    });

    if (route.points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints([...route.points, start, dest]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(48, 140, 48, 240),
        ),
      );
    }
  }

  Future<void> _highlightRouteTo(Pandal pandal) async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    var userPos = _userPosition;
    userPos ??= await LocationService.instance.currentPosition();

    final double userLat = userPos?.latitude ?? AppConfig.defaultLat;
    final double userLng = userPos?.longitude ?? AppConfig.defaultLng;

    final distToKolkata = haversineMeters(
      userLat,
      userLng,
      AppConfig.defaultLat,
      AppConfig.defaultLng,
    );
    final bool isFarAway = distToKolkata > 70000;

    final refLat = (isFarAway || userPos == null) ? AppConfig.defaultLat : userLat;
    final refLng = (isFarAway || userPos == null) ? AppConfig.defaultLng : userLng;
    final start = LatLng(refLat, refLng);
    final dest = LatLng(pandal.lat, pandal.lng);

    setState(() {
      if (userPos != null) _userPosition = userPos;
      _isCalculatingRoute = true;
      _selectedPandal = pandal;
      _showMapSearchBar = false;
    });

    if (userPos == null && mounted) {
      _showStatusPill(
        '📍 Using central Kolkata as starting point for path.',
        icon: Icons.near_me_outlined,
      );
    }

    final route = await RoutingService.instance.getWalkingRouteToPoint(
      start: start,
      destination: dest,
      destinationName: pandal.name,
      targetPandal: pandal,
    );

    if (!mounted) return;
    setState(() {
      _highlightedRoute = route;
      _isCalculatingRoute = false;
      _showMapSearchBar = false;
    });

    // Fit camera to display both user and pandal walking corridor
    if (route.points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints([...route.points, start, dest]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(48, 140, 48, 240),
        ),
      );
    }
  }

  Future<void> _findAndHighlightNearestPandal() async {
    HapticFeedback.mediumImpact();
    var userPos = _userPosition;
    userPos ??= await LocationService.instance.currentPosition();

    final double userLat = userPos?.latitude ?? AppConfig.defaultLat;
    final double userLng = userPos?.longitude ?? AppConfig.defaultLng;

    // Check if user is far from Kolkata (e.g. testing on an emulator or remote location)
    final distToKolkata = haversineMeters(
      userLat,
      userLng,
      AppConfig.defaultLat,
      AppConfig.defaultLng,
    );
    final bool isFarAway = distToKolkata > 70000;

    final refLat = (isFarAway || userPos == null) ? AppConfig.defaultLat : userLat;
    final refLng = (isFarAway || userPos == null) ? AppConfig.defaultLng : userLng;
    final refPoint = LatLng(refLat, refLng);

    // Find all pandals within 10 km (10,000 meters)
    final nearbyPandals = _pandals.where((p) {
      final d = haversineMeters(refLat, refLng, p.lat, p.lng);
      return d <= 10000;
    }).toList();

    // Sort by distance ascending so closest is first
    nearbyPandals.sort((a, b) {
      final da = haversineMeters(refLat, refLng, a.lat, a.lng);
      final db = haversineMeters(refLat, refLng, b.lat, b.lng);
      return da.compareTo(db);
    });

    final effectivePandals = nearbyPandals.isNotEmpty
        ? nearbyPandals
        : (_pandals.take(15).toList());

    final nearest = effectivePandals.first;

    setState(() {
      if (userPos != null) _userPosition = userPos;
      _filterNearby10Km = true;
      _selectedZone = null;
      _selectedPandal = nearest;
      _selectedSquadMember = null;
      _followUser = false;
    });

    await _highlightRouteTo(nearest);

    if (mounted) {
      final points = [
        refPoint,
        ...effectivePandals.map((p) => LatLng(p.lat, p.lng)),
      ];
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(40, 140, 40, 240),
          maxZoom: 15.0,
        ),
      );
      _mapController.rotate(0.0);

      final msg = isFarAway
          ? '📍 ${effectivePandals.length} pandals within 10 km • Nearest: ${nearest.name}'
          : '📍 ${effectivePandals.length} pandals within 10 km • Nearest: ${nearest.name}';
      _showStatusPill(msg, icon: Icons.near_me_rounded);
    }
  }

  Future<void> _highlightRouteToMember(SquadMember member) async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    var userPos = _userPosition;
    userPos ??= await LocationService.instance.currentPosition();

    final double userLat = userPos?.latitude ?? AppConfig.defaultLat;
    final double userLng = userPos?.longitude ?? AppConfig.defaultLng;

    final distToKolkata = haversineMeters(
      userLat,
      userLng,
      AppConfig.defaultLat,
      AppConfig.defaultLng,
    );
    final bool isFarAway = distToKolkata > 70000;

    final refLat = (isFarAway || userPos == null) ? AppConfig.defaultLat : userLat;
    final refLng = (isFarAway || userPos == null) ? AppConfig.defaultLng : userLng;
    final start = LatLng(refLat, refLng);
    final dest = LatLng(member.latitude, member.longitude);

    setState(() {
      if (userPos != null) _userPosition = userPos;
      _isCalculatingRoute = true;
      _selectedSquadMember = member;
      _selectedPandal = null;
      _showMapSearchBar = false;
    });

    final route = await RoutingService.instance.getWalkingRouteToPoint(
      start: start,
      destination: dest,
      destinationName: member.name,
    );

    if (!mounted) return;

    setState(() {
      _highlightedRoute = route;
      _isCalculatingRoute = false;
      _showMapSearchBar = false;
    });

    if (route.points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints([...route.points, start, dest]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(
            top: 140,
            bottom: 220,
            left: 60,
            right: 60,
          ),
        ),
      );
    }
  }

  Future<void> _highlightRouteToFoodSpot(FoodSpot spot) async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    var userPos = _userPosition;
    userPos ??= await LocationService.instance.currentPosition();

    final double userLat = userPos?.latitude ?? AppConfig.defaultLat;
    final double userLng = userPos?.longitude ?? AppConfig.defaultLng;

    // Check if user is far from Kolkata (e.g. testing on an emulator or remote location)
    final distToKolkata = haversineMeters(
      userLat,
      userLng,
      AppConfig.defaultLat,
      AppConfig.defaultLng,
    );
    final bool isFarAway = distToKolkata > 70000;

    final refLat = (isFarAway || userPos == null) ? AppConfig.defaultLat : userLat;
    final refLng = (isFarAway || userPos == null) ? AppConfig.defaultLng : userLng;
    final start = LatLng(refLat, refLng);
    final dest = LatLng(spot.lat, spot.lng);

    setState(() {
      if (userPos != null) _userPosition = userPos;
      _isCalculatingRoute = true;
      _selectedFoodSpot = spot;
      _selectedPandal = null;
      _selectedSquadMember = null;
      _followUser = false;
      _showFoodSpots = true;
      _showMapSearchBar = false;
    });

    final route = await RoutingService.instance.getWalkingRouteToPoint(
      start: start,
      destination: dest,
      destinationName: spot.name,
    );

    if (!mounted) return;

    setState(() {
      _highlightedRoute = route;
      _isCalculatingRoute = false;
      _showMapSearchBar = false;
    });

    if (route.points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints([...route.points, start, dest]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(48, 140, 48, 240),
        ),
      );
      _mapController.rotate(0.0);
    }

    _showStatusPill(
      '🚶 Path to ${spot.name} (${route.formattedDistance} · ${route.formattedDuration})',
      icon: Icons.restaurant_rounded,
      color: Colors.orange.shade800,
    );
  }

  void _clearRoute() {
    HapticFeedback.selectionClick();
    setState(() {
      _highlightedRoute = null;
      _selectedSquadMember = null;
      _selectedFoodSpot = null;
      _selectedMetroStation = null;
    });
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
      _filterNearby10Km = false;
      _selectedZone = zone;
      _selectedPandal = null;
      _followUser = false;
    });

    if (zone == null) {
      _animatedMapMove(const LatLng(22.65, 88.38), 10.8);
      _showStatusPill(
        'Showing all ${_pandals.length} pandals across Kolkata & Suburbs',
        icon: Icons.auto_awesome_rounded,
      );
    } else {
      final center = _getZoneCenter(zone);
      final zoom = _getZoneZoom(zone);
      _animatedMapMove(center, zoom);

      final count = _pandals.where((p) => p.zone == zone).length;
      _showStatusPill(
        '📍 ${zone.label} · $count Pandals',
        icon: Icons.location_on_rounded,
      );
    }
  }

  LatLng _get10KmReferenceCenter() {
    final double userLat = _userPosition?.latitude ?? AppConfig.defaultLat;
    final double userLng = _userPosition?.longitude ?? AppConfig.defaultLng;
    final distToKolkata = haversineMeters(
      userLat,
      userLng,
      AppConfig.defaultLat,
      AppConfig.defaultLng,
    );
    if (distToKolkata > 70000) {
      return const LatLng(AppConfig.defaultLat, AppConfig.defaultLng);
    }
    return LatLng(userLat, userLng);
  }

  List<Pandal> get _visiblePandals {
    List<Pandal> list;
    if (_filterNearby10Km) {
      final center = _get10KmReferenceCenter();
      final nearby = _pandals.where((p) {
        return haversineMeters(
              center.latitude,
              center.longitude,
              p.lat,
              p.lng,
            ) <=
            10000;
      }).toList();
      list = nearby.isNotEmpty ? nearby : _pandals;
    } else if (_selectedZone != null) {
      list = _pandals.where((p) => p.zone == _selectedZone).toList();
    } else {
      list = _pandals;
    }

    // Zero-intervention guarantee: Selected pandal is ALWAYS preserved
    if (_selectedPandal != null &&
        !list.any((p) => p.id == _selectedPandal!.id)) {
      list = [_selectedPandal!, ...list];
    }

    // Zero-intervention guarantee: Stops in active custom trail are ALWAYS preserved
    try {
      final trailService = Provider.of<CustomHoppingTrailService>(
        context,
        listen: false,
      );
      if (trailService.hasActiveTrail) {
        for (final stop in trailService.activeTrail!.stops) {
          if (!list.any((p) => p.id == stop.id)) {
            list = [...list, stop];
          }
        }
      }
    } catch (_) {}

    return list;
  }

  List<FoodSpot> get _visibleFoodSpots {
    List<FoodSpot> result;
    // If a specific pandal is selected, contextualize food spots to nearby walking radius (2.5 km)
    if (_selectedPandal != null) {
      final pLat = _selectedPandal!.lat;
      final pLng = _selectedPandal!.lng;
      final nearbyToPandal = _foodSpots.where((f) {
        return haversineMeters(pLat, pLng, f.lat, f.lng) <= 2500;
      }).toList();
      result = nearbyToPandal.isNotEmpty ? nearbyToPandal : _foodSpots;
    } else if (_filterNearby10Km) {
      final center = _get10KmReferenceCenter();
      result = _foodSpots.where((f) {
        return haversineMeters(
              center.latitude,
              center.longitude,
              f.lat,
              f.lng,
            ) <=
            10000;
      }).toList();
    } else if (_selectedZone != null) {
      result = _foodSpots.where((f) {
        final matchingPandal = _pandals.cast<Pandal?>().firstWhere(
          (p) =>
              p != null &&
              (p.name.toLowerCase() == f.nearbyPandal.toLowerCase() ||
                  f.nearbyPandal.toLowerCase().contains(p.name.toLowerCase()) ||
                  p.name.toLowerCase().contains(f.nearbyPandal.toLowerCase())),
          orElse: () => null,
        );
        return matchingPandal?.zone == _selectedZone;
      }).toList();
    } else {
      result = _foodSpots;
    }

    // Zero-intervention guarantee: Selected food spot is ALWAYS preserved
    if (_selectedFoodSpot != null &&
        !result.any((f) => f.id == _selectedFoodSpot!.id)) {
      result = [_selectedFoodSpot!, ...result];
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final visible = _visiblePandals;
    final squadService = Provider.of<SquadService>(context);

    // Deep-focus on squad member if navigated from Squads screen
    if (squadService.focusedMemberId != null) {
      final target = squadService.getMemberById(squadService.focusedMemberId!);
      if (target != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _animatedMapMove(LatLng(target.latitude, target.longitude), 16.5);
            setState(() {
              _selectedSquadMember = target;
              _selectedPandal = null;
            });
            squadService.clearFocus();
          }
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pujo Parikrama Map'),
        actions: [
          IconButton(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _showMapSearchBar
                    ? PujaColors.festivalGold.withValues(alpha: 0.28)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: _showMapSearchBar
                    ? Border.all(color: PujaColors.goldBright, width: 1.2)
                    : null,
              ),
              child: Icon(
                _showMapSearchBar
                    ? Icons.search_rounded
                    : Icons.search_outlined,
                color: _showMapSearchBar
                    ? PujaColors.goldBright
                    : Colors.white.withValues(alpha: 0.75),
                size: 20,
              ),
            ),
            tooltip: _showMapSearchBar ? 'Hide Search Bar' : 'Search Pandals',
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _showMapSearchBar = !_showMapSearchBar);
            },
          ),
          // Pinned User Profile Avatar (Accessible where the Theme Toggle was)
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: _buildProfileAvatarButton(context, isDark),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(
                AppConfig.defaultLat,
                AppConfig.defaultLng,
              ),
              initialZoom: AppConfig.defaultZoom,
              initialRotation: 0.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                enableMultiFingerGestureRace: true,
              ),
              onTap: (_, _) {
                if (_selectedPandal != null ||
                    _selectedSquadMember != null ||
                    _selectedFoodSpot != null) {
                  setState(() {
                    _selectedPandal = null;
                    _selectedSquadMember = null;
                    _selectedFoodSpot = null;
                  });
                }
              },
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && _followUser) {
                  setState(() => _followUser = false);
                }
              },
            ),
            children: [
              RepaintBoundary(
                child: TileLayer(
                  urlTemplate: AppConfig.tileUrlTemplate,
                  subdomains: AppConfig.osmSubdomains,
                  // 1. CRITICAL: Prevents OSM from blocking your app (Missing Blocks fix)
                  userAgentPackageName: 'com.kolkatapuja.kolkata_puja',

                  // 2. TILE CULLING: Cancels tile downloads if the user pans away quickly
                  tileUpdateTransformer: _throttleTileUpdates(),

                  // 3. IN-MEMORY CACHE: Keeps tiles loaded to prevent re-fetching when panning back
                  keepBuffer: 5, // Keeps a 5-tile radius in RAM
                  panBuffer: 2,  // Pre-loads 2 tiles ahead of the pan direction

                  // 4. HARDWARE ACCELERATED DARK MODE: Applies your matrix at the GPU level
                  tileBuilder: (context, tileWidget, tile) {
                    if (isDark) {
                      return ColorFiltered(
                        colorFilter: _kDarkMatrix,
                        child: tileWidget,
                      );
                    }
                    return tileWidget;
                  },

                  // 5. SMOOTH TRANSITIONS: Eliminates the jarring pop-in of tiles
                  tileDisplay: const TileDisplay.fadeIn(
                    duration: Duration(milliseconds: 150),
                  ),

                  // 6. SHARED HTTP CLIENT: Prevents socket exhaustion
                  tileProvider: NetworkTileProvider(
                    headers: <String, String>{
                      'Accept': 'image/png',
                      'User-Agent': 'flutter_map (com.yourdomain.kolkatapuja2026)',
                    },
                  ),
                ),
              ),

              // 10 km Radius Boundary Layer (shows 10km radius when Nearest filter is active)
              if (_filterNearby10Km)
                RepaintBoundary(
                  child: CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _get10KmReferenceCenter(),
                        radius: 10000,
                        useRadiusInMeter: true,
                        color: PujaColors.festivalGold.withValues(alpha: 0.08),
                        borderColor: PujaColors.festivalGold.withValues(
                          alpha: 0.85,
                        ),
                        borderStrokeWidth: 2.0,
                      ),
                    ],
                  ),
                ),

              // GPS Accuracy Circle Layer
              if (_userPosition != null &&
                  _userPosition!.accuracy > 0 &&
                  _userPosition!.accuracy < 300 &&
                  _effectiveUserLocation != null &&
                  (_effectiveUserLocation!.latitude == _userPosition!.latitude &&
                   _effectiveUserLocation!.longitude == _userPosition!.longitude))
                RepaintBoundary(
                  child: CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(
                          _userPosition!.latitude,
                          _userPosition!.longitude,
                        ),
                        radius: _userPosition!.accuracy,
                        useRadiusInMeter: true,
                        color: const Color(0xFF2979FF).withValues(alpha: 0.12),
                        borderColor: const Color(0xFF2979FF)
                            .withValues(alpha: 0.35),
                        borderStrokeWidth: 1.2,
                      ),
                    ],
                  ),
                ),

              // Nearest / Selected Pandal Walking Route Polyline
              if (_highlightedRoute != null &&
                  _highlightedRoute!.points.isNotEmpty)
                RepaintBoundary(
                  child: PolylineLayer(
                    polylines: [
                      // Outer glow halo
                      Polyline(
                        points: _highlightedRoute!.points,
                        strokeWidth: 7.5,
                        color:
                            (isDark
                                    ? const Color(0xFF00E5FF)
                                    : PujaColors.durgaRed)
                                .withValues(alpha: 0.35),
                      ),
                      // Core route line
                      Polyline(
                        points: _highlightedRoute!.points,
                        strokeWidth: 4.2,
                        color: isDark
                            ? const Color(0xFF00E5FF)
                            : PujaColors.durgaRed,
                      ),
                    ],
                  ),
                ),

              // Custom AI Hopping Trail Connected Polyline
              Consumer<CustomHoppingTrailService>(
                builder: (context, trailService, _) {
                  if (!trailService.hasActiveTrail ||
                      trailService.activeTrail!.stops.length < 2) {
                    return const SizedBox.shrink();
                  }
                  final stops = trailService.activeTrail!.stops;
                  final pts = stops.map((p) => LatLng(p.lat, p.lng)).toList();
                  final bool dimTrail =
                      _highlightedRoute != null &&
                      _highlightedRoute!.points.isNotEmpty;
                  final double alphaMul = dimTrail ? 0.25 : 1.0;
                  return RepaintBoundary(
                    child: PolylineLayer(
                      polylines: [
                        Polyline(
                          points: pts,
                          strokeWidth: 7.0,
                          color: PujaColors.festivalGold.withValues(
                            alpha: 0.35 * alphaMul,
                          ),
                        ),
                        Polyline(
                          points: pts,
                          strokeWidth: 3.8,
                          color: PujaColors.festivalGold.withValues(
                            alpha: alphaMul,
                          ),
                          pattern: StrokePattern.dashed(
                            segments: const [10, 6],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Food / Bhog Spot Markers (Minimalist & Accessible Touch Target)
              if (_showFoodSpots)
                RepaintBoundary(
                  child: MarkerLayer(
                    markers: _visibleFoodSpots.map((f) {
                      return Marker(
                        point: LatLng(f.lat, f.lng),
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _animatedMapMove(
                              LatLng(f.lat, f.lng),
                              (_mapController.camera.zoom < 15.5
                                  ? 15.5
                                  : _mapController.camera.zoom),
                            );
                            _showFoodSpotSheet(f, isDark);
                          },
                          child: Center(
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF57C00),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.0),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 4,
                                    offset: Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.restaurant_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Selected Metro / Railway Station Beacon Layer (Prominent Glow & Accessible Target)
              if (_selectedMetroStation != null)
                RepaintBoundary(
                  child: MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          _selectedMetroStation!.latitude,
                          _selectedMetroStation!.longitude,
                        ),
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _animatedMapMove(
                              LatLng(
                                _selectedMetroStation!.latitude,
                                _selectedMetroStation!.longitude,
                              ),
                              (_mapController.camera.zoom < 16.0
                                  ? 16.0
                                  : _mapController.camera.zoom),
                            );
                          },
                          child: Center(
                            child: Builder(
                              builder: (context) {
                                final isRailway = _selectedMetroStation!.name.toLowerCase().contains('railway');
                                final baseColor = isRailway ? PujaColors.railwayPurple : _selectedMetroStation!.line.color;
                                return Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: baseColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: baseColor.withValues(
                                          alpha: 0.85,
                                        ),
                                        blurRadius: 12,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: isRailway
                                        ? const Icon(
                                            Icons.train_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          )
                                        : const Text(
                                            'M',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Full Kolkata Metro & Railway Stations Network Layer (Large & Distinct)
              if (_showMetroStations)
                RepaintBoundary(
                  child: MarkerLayer(
                    markers: MetroRepository.allStations.map((stn) {
                      final isStationSelected = _selectedMetroStation?.id == stn.id;
                      final isRailway = stn.name.toLowerCase().contains('railway');
                      final baseColor = isRailway ? PujaColors.railwayPurple : stn.line.color;
                      return Marker(
                        point: LatLng(stn.latitude, stn.longitude),
                        width: isStationSelected ? 56 : 48,
                        height: isStationSelected ? 56 : 48,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedMetroStation = stn;
                              _selectedPandal = null;
                              _selectedFoodSpot = null;
                              _highlightedRoute = null;
                            });
                            _animatedMapMove(
                              LatLng(stn.latitude, stn.longitude),
                              _mapController.camera.zoom < 15.0
                                  ? 15.0
                                  : _mapController.camera.zoom,
                            );
                          },
                          child: Center(
                            child: Container(
                              width: isStationSelected ? 40 : 32,
                              height: isStationSelected ? 40 : 32,
                              decoration: BoxDecoration(
                                color: baseColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isStationSelected ? Colors.amberAccent : Colors.white,
                                  width: isStationSelected ? 2.5 : 1.8,
                                ),
                                boxShadow: [
                                  if (isStationSelected)
                                    BoxShadow(
                                      color: baseColor.withValues(alpha: 0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  else
                                    const BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 4,
                                      offset: Offset(0, 1.5),
                                    ),
                                ],
                              ),
                              child: Center(
                                child: isRailway
                                    ? Icon(
                                        Icons.train_rounded,
                                        color: Colors.white,
                                        size: isStationSelected ? 20 : 16,
                                      )
                                    : Text(
                                        'M',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: isStationSelected ? 16 : 13,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Clustered Pandal Markers Layer (Smooth Spatial LOD)
              RepaintBoundary(
                child: _ClusteredPandalLayer(
                  visiblePandals: visible,
                  selectedPandal: _selectedPandal,
                  pulseController: _pulseController,
                  onSelectPandal: (p) {
                    if (_followUser) {
                      setState(() => _followUser = false);
                    }
                    setState(() {
                      _selectedPandal = p;
                      _selectedSquadMember = null;
                      _highlightedRoute = null;
                    });
                    _animatedMapMove(
                      LatLng(p.lat, p.lng),
                      (_mapController.camera.zoom < 15.0
                          ? 15.0
                          : _mapController.camera.zoom),
                    );
                  },
                  onZoomToCluster: (point, targetZoom) {
                    _animatedMapMove(point, targetZoom);
                  },
                ),
              ),

              // Designated Squad Meet-up Landmark Flag Marker (Enlarged)
              if (squadService.hasActiveSquad && squadService.showSquadOnMap)
                RepaintBoundary(
                  child: MarkerLayer(
                    markers: [
                      Marker(
                        point: squadService.meetupPointCoords,
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '🚩 Designated Squad Meet-up: ${squadService.meetupPointName}',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, _) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 36 + (10 * _pulseController.value),
                                      height: 36 + (10 * _pulseController.value),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: PujaColors.festivalGold.withValues(
                                          alpha:
                                              0.3 *
                                              (1.0 - _pulseController.value),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: PujaColors.festivalGold,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.2,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black45,
                                            blurRadius: 5,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.flag_rounded,
                                        color: Colors.black87,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Live Squad Members MarkerLayer (Stable Glowing DP - Enlarged)
              if (squadService.hasActiveSquad && squadService.showSquadOnMap)
                RepaintBoundary(
                  child: MarkerLayer(
                    markers: squadService.companionMembers.map((member) {
                      final isSelected = _selectedSquadMember?.id == member.id;
                      final avatarColor = member.avatarColor;
                      final size = isSelected ? 46.0 : 40.0;
                      return Marker(
                        point: LatLng(member.latitude, member.longitude),
                        width: size + 20,
                        height: size + 20,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _animatedMapMove(
                              LatLng(member.latitude, member.longitude),
                              (_mapController.camera.zoom < 15.5
                                  ? 15.5
                                  : _mapController.camera.zoom),
                            );
                            setState(() {
                              _selectedSquadMember = member;
                              _selectedPandal = null;
                            });
                          },
                          child: RepaintBoundary(
                            child: Center(
                              child: Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: avatarColor,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF00E5FF)
                                        : Colors.white,
                                    width: isSelected ? 2.8 : 2.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                                          : avatarColor.withValues(alpha: 0.45),
                                      blurRadius: isSelected ? 12 : 6,
                                      spreadRadius: isSelected ? 2 : 1,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // 1. Google Avatar or Clean Letter Fallback
                                    ClipOval(
                                      child: (member.photoUrl != null &&
                                              member.photoUrl!.isNotEmpty)
                                          ? Image.network(
                                              member.photoUrl!,
                                              width: size,
                                              height: size,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) =>
                                                      Center(
                                                child: Text(
                                                  member.initials,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Container(
                                            color: avatarColor,
                                            child: Center(
                                              child: Text(
                                                member.initials,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                    ),
                                    // Online active dot
                                    Positioned(
                                      right: -1,
                                      bottom: -1,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E676),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // User Location Marker with Animated Radar Pulse & Directional Navigation Arrow
              if (_effectiveUserLocation != null)
                RepaintBoundary(
                  child: MarkerLayer(
                  markers: [
                    Marker(
                      point: _effectiveUserLocation!,
                      width: 64,
                      height: 64,
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final pulse = _pulseController.value;
                            final userLatLng = _effectiveUserLocation!;

                            // Calculate directional bearing towards destination pandal, squad member, food spot, or metro
                            double? arrowBearing;
                            bool isNavigatingToTarget = false;

                            if (_selectedPandal != null) {
                              arrowBearing = calculateBearing(
                                userLatLng.latitude,
                                userLatLng.longitude,
                                _selectedPandal!.lat,
                                _selectedPandal!.lng,
                              );
                              isNavigatingToTarget = true;
                            } else if (_selectedSquadMember != null) {
                              arrowBearing = calculateBearing(
                                userLatLng.latitude,
                                userLatLng.longitude,
                                _selectedSquadMember!.latitude,
                                _selectedSquadMember!.longitude,
                              );
                              isNavigatingToTarget = true;
                            } else if (_selectedFoodSpot != null) {
                              arrowBearing = calculateBearing(
                                userLatLng.latitude,
                                userLatLng.longitude,
                                _selectedFoodSpot!.lat,
                                _selectedFoodSpot!.lng,
                              );
                              isNavigatingToTarget = true;
                            } else if (_selectedMetroStation != null) {
                              arrowBearing = calculateBearing(
                                userLatLng.latitude,
                                userLatLng.longitude,
                                _selectedMetroStation!.latitude,
                                _selectedMetroStation!.longitude,
                              );
                              isNavigatingToTarget = true;
                            } else if (_userPosition != null &&
                                _userPosition!.heading > 0 &&
                                _userPosition!.heading <= 360) {
                              arrowBearing = _userPosition!.heading;
                            }

                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulsing radar wave
                                Container(
                                  width: 30 + (28 * pulse),
                                  height: 30 + (28 * pulse),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        (isNavigatingToTarget
                                                ? PujaColors.festivalGold
                                                : const Color(0xFF2979FF))
                                            .withValues(
                                              alpha: 0.35 * (1.0 - pulse),
                                            ),
                                  ),
                                ),
                                // Directional Navigation Arrow pointing towards target or forward heading
                                if (arrowBearing != null)
                                  Transform.rotate(
                                    angle: (arrowBearing * math.pi / 180),
                                    child: Transform.translate(
                                      offset: const Offset(0, -20),
                                      child: Icon(
                                        Icons.navigation_rounded,
                                        size: 26,
                                        color: isNavigatingToTarget
                                            ? PujaColors.goldBright
                                            : const Color(0xFF2979FF),
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black54,
                                            blurRadius: 5,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                // Inner location core with golden outline & prominent Google DP
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF2979FF),
                                        Color(0xFF1565C0),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isNavigatingToTarget
                                          ? PujaColors.goldBright
                                          : Colors.white,
                                      width: 2.6,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isNavigatingToTarget
                                                ? PujaColors.goldBright
                                                : const Color(0xFF2979FF))
                                            .withValues(alpha: 0.55),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Builder(
                                      builder: (context) {
                                        final auth = context.watch<AuthService?>();
                                        final user = auth?.currentUserModel ??
                                            AuthService.instance.currentUserModel;
                                        final userPhoto = user?.photoUrl;
                                        final name = user?.displayName ?? '';
                                        final initial = name.trim().isNotEmpty
                                            ? name.trim()[0].toUpperCase()
                                            : 'U';

                                        if (userPhoto != null && userPhoto.isNotEmpty) {
                                          return Image.network(
                                            userPhoto,
                                            width: 32,
                                            height: 32,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stack) =>
                                                Center(
                                              child: Text(
                                                initial,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            loadingBuilder:
                                                (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: Text(
                                                  initial,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        }

                                        return Center(
                                          child: name.trim().isNotEmpty
                                              ? Text(
                                                  initial,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.person_rounded,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Floating Zone Filter & Locate Bar (Responsive, Pinned & Never Cut Out)
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_showMapSearchBar) ...[
                  PandalSearchAutocomplete(
                    pandals: _pandals,
                    foodSpots: _foodSpots,
                    metroStations: MetroRepository.allStations,
                    userLat: _userPosition?.latitude,
                    userLng: _userPosition?.longitude,
                    isFloatingOnMap: true,
                    hintText: 'Search pandals, metro, food spots...',
                    onPandalSelected: _onPandalSelectedFromSearch,
                    onMetroSelected: _onMetroSelectedFromSearch,
                    onFoodSpotSelected: _onFoodSpotSelectedFromSearch,
                    onSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                      setState(() => _showMapSearchBar = false);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? PujaColors.nightCard : Colors.white)
                        .withValues(alpha: 0.94),
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
                              if (squadService.hasActiveSquad)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      if (squadService
                                          .companionMembers
                                          .isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Squad "${squadService.squadName}" is empty (0 companions). Share code ${squadService.squadCode} to add friends!',
                                            ),
                                            duration: const Duration(
                                              seconds: 3,
                                            ),
                                            action: SnackBarAction(
                                              label: 'Squads',
                                              onPressed: () =>
                                                  MainNavigationScreen.switchTab(
                                                    context,
                                                    3,
                                                  ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        squadService.toggleSquadOnMap(
                                          !squadService.showSquadOnMap,
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: squadService.showSquadOnMap
                                            ? const Color(0xFF00E676)
                                                  .withValues(alpha: 0.16)
                                            : (isDark
                                                  ? Colors.white10
                                                  : Colors.black12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: squadService.showSquadOnMap
                                              ? const Color(0xFF00E676)
                                              : (isDark
                                                    ? Colors.white24
                                                    : Colors.black26),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: squadService.showSquadOnMap
                                                  ? const Color(0xFF00E676)
                                                  : Colors.grey,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Squad (${squadService.companionMembers.length})',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: squadService.showSquadOnMap
                                                  ? (isDark
                                                        ? const Color(
                                                            0xFF00E676,
                                                          )
                                                        : const Color(
                                                            0xFF2E7D32,
                                                          ))
                                                  : (isDark
                                                        ? Colors.white60
                                                        : Colors.black54),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              _buildZoneChip(
                                'All (${_pandals.length})',
                                null,
                                isDark,
                              ),
                              _buildNearbyChip(isDark),
                              _buildCustomTrailChip(isDark),
                              _buildMetroToggleChip(isDark),
                              _buildFoodToggleChip(isDark),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 22,
                        width: 1,
                        color: isDark ? Colors.white24 : Colors.black12,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      // Pinned Theme Toggle Chip (Light / Dark Mode)
                      _buildThemeToggleChip(context, isDark),
                    ],
                  ),
                ),
                // Squad Friends At-A-Glance Floating Bar
                if (squadService.hasActiveSquad) ...[
                  const SizedBox(height: 6),
                  _buildSquadFriendsAtAGlance(isDark, squadService),
                ],
              ],
            ),
          ),

          // Non-Intrusive Floating Status Pill (Minimal Negative Feedback)
          if (_statusPillMessage != null)
            Positioned(
              top: _showMapSearchBar ? 116 : 58,
              left: 24,
              right: 24,
              child: Center(
                child: AnimatedFadeSlide(
                  duration: const Duration(milliseconds: 220),
                  offset: const Offset(0, -0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF1E1E24) : Colors.white)
                          .withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            _statusPillColor ??
                            PujaColors.festivalGold.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.12,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusPillIcon,
                          size: 16,
                          color: _statusPillColor ?? PujaColors.festivalGold,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            _statusPillMessage!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Top Floating Route HUD Banner
          if (_highlightedRoute != null)
            Positioned(
              top: _showMapSearchBar ? 122 : 66,
              left: 14,
              right: 14,
              child: AnimatedFadeSlide(
                duration: const Duration(milliseconds: 280),
                offset: const Offset(0, -0.15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF1E1E1E) : Colors.white)
                        .withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                          : PujaColors.durgaRed.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.45 : 0.15,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? const Color(0xFF00E5FF)
                                      : PujaColors.durgaRed)
                                  .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.directions_walk_rounded,
                          size: 19,
                          color: isDark
                              ? const Color(0xFF00E5FF)
                              : PujaColors.durgaRed,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _highlightedRoute!.destinationTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_highlightedRoute!.formattedDistance} · ${_highlightedRoute!.formattedDuration}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF00E5FF)
                                    : PujaColors.durgaRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fit_screen_rounded, size: 20),
                        tooltip: 'Fit Route in View',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final bounds = LatLngBounds.fromPoints(
                            _highlightedRoute!.points,
                          );
                          _mapController.fitCamera(
                            CameraFit.bounds(
                              bounds: bounds,
                              padding: const EdgeInsets.fromLTRB(
                                48,
                                140,
                                48,
                                240,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        tooltip: 'Clear Route',
                        onPressed: _clearRoute,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top Floating Active Custom Hopping Trail HUD
          Consumer<CustomHoppingTrailService>(
            builder: (context, trailService, _) {
              if (!trailService.hasActiveTrail) return const SizedBox.shrink();
              final trail = trailService.activeTrail!;
              final target = trail.currentTargetPandal;
              final total = trail.totalStops;
              final visited = trail.visitedCount;
              final percent = total > 0 ? (visited / total) : 0.0;

              final baseTop = _showMapSearchBar ? 122.0 : 66.0;

              return Positioned(
                top: _highlightedRoute != null ? (baseTop + 74) : baseTop,
                left: 14,
                right: 14,
                child: AnimatedFadeSlide(
                  duration: const Duration(milliseconds: 280),
                  offset: const Offset(0, -0.15),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: _isTrailHudExpanded ? 10 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF1E1F29) : Colors.white)
                          .withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: PujaColors.festivalGold,
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: PujaColors.festivalGold.withValues(
                            alpha: 0.22,
                          ),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isTrailHudExpanded
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF1744),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Stop ${trail.currentStopIndex + 1} of $total',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      target != null
                                          ? target.name
                                          : 'All stops visited!',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      size: 20,
                                    ),
                                    tooltip: 'Collapse',
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      setState(
                                        () => _isTrailHudExpanded = false,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                    tooltip: 'End Trail',
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      trailService.endTrail();
                                      _showStatusPill(
                                        'Custom trail ended',
                                        icon: Icons.flag_outlined,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Progress Bar
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: percent,
                                        minHeight: 6,
                                        backgroundColor: isDark
                                            ? Colors.white12
                                            : Colors.grey.shade200,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Color(0xFFFF1744),
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$visited/$total Visited',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: PujaColors.festivalGold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Bottom row: Auto-visit status & Actions
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00E676),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Auto-Visit (80m) Active',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? const Color(0xFF00E676)
                                              : const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      if (target != null)
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          onPressed: () {
                                            _highlightRouteTo(target);
                                          },
                                          child: const Text(
                                            'Path 🗺️',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (target != null)
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          onPressed: () {
                                            trailService.recordAutoVisit(
                                              target,
                                            );
                                            _showStatusPill(
                                              '✓ Visited ${target.name}!',
                                              icon: Icons.check_circle_rounded,
                                              color: const Color(0xFF00C853),
                                            );
                                          },
                                          child: const Text(
                                            '✓ Visited',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: PujaColors.festivalGold,
                                            ),
                                          ),
                                        ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () =>
                                            trailService.skipCurrentStop(),
                                        child: const Text(
                                          'Skip ⏭',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF1744),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${trail.currentStopIndex + 1}/$total',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(
                                    () => _isTrailHudExpanded = true,
                                  ),
                                  child: Text(
                                    target != null
                                        ? target.name
                                        : 'All stops visited!',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              if (target != null)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF00C853),
                                    size: 20,
                                  ),
                                  tooltip: 'Mark Visited',
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
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: PujaColors.festivalGold,
                                ),
                                tooltip: 'Expand Details',
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _isTrailHudExpanded = true);
                                },
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                tooltip: 'End Trail',
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  trailService.endTrail();
                                  _showStatusPill(
                                    'Custom trail ended',
                                    icon: Icons.flag_outlined,
                                  );
                                },
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
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
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF181818) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.45 : 0.12,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: PujaColors.durgaRed.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: PujaColors.durgaRed.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                _selectedPandal!.zone.label,
                                style: const TextStyle(
                                  color: PujaColors.durgaRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CrowdBadge(crowdLevel: _selectedPandal!.crowdLevel),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                              tooltip: 'Dismiss',
                              onPressed: () => setState(() {
                                _selectedPandal = null;
                                _highlightedRoute = null;
                              }),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedPandal!.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.dynamicFont(15.5),
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            height: 1.22,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (_selectedPandal!.theme.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _selectedPandal!.theme,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.dynamicFont(12.5),
                              fontWeight: FontWeight.w400,
                              color: isDark ? Colors.white70 : Colors.black54,
                              height: 1.25,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildInfoBadge(
                              icon: Icons.schedule_rounded,
                              label: _selectedPandal!.timings,
                              isDark: isDark,
                            ),
                            if (_selectedPandal!.nearestMetro != null &&
                                _selectedPandal!.nearestMetro!.isNotEmpty)
                              _buildInfoBadge(
                                icon: Icons.directions_subway_rounded,
                                label: _selectedPandal!.nearestMetro!,
                                isDark: isDark,
                                iconColor: PujaColors.metroBlue,
                              ),
                            if (_userPosition != null)
                              _buildInfoBadge(
                                icon: Icons.near_me_rounded,
                                label: formatDistance(
                                  haversineMeters(
                                    _userPosition!.latitude,
                                    _userPosition!.longitude,
                                    _selectedPandal!.lat,
                                    _selectedPandal!.lng,
                                  ),
                                ),
                                isDark: isDark,
                                iconColor: PujaColors.durgaRed,
                                highlight: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: FilledButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  PandalDetailSheet.show(
                                    context,
                                    _selectedPandal!,
                                  );
                                },
                                icon: const Icon(
                                  Icons.info_outline_rounded,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Details',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: PujaColors.durgaRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 5,
                              child: Builder(
                                builder: (context) {
                                  final bool isPathActive =
                                      _highlightedRoute != null &&
                                      _highlightedRoute!.destinationTitle ==
                                          _selectedPandal!.name;
                                  return FilledButton.icon(
                                    onPressed: _isCalculatingRoute
                                        ? null
                                        : () {
                                            if (isPathActive) {
                                              _clearRoute();
                                            } else {
                                              _highlightRouteTo(
                                                _selectedPandal!,
                                              );
                                            }
                                          },
                                    icon: _isCalculatingRoute
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            isPathActive
                                                ? Icons.close_rounded
                                                : Icons.directions_walk_rounded,
                                            size: 16,
                                          ),
                                    label: Text(
                                      isPathActive
                                          ? 'Clear Path'
                                          : 'Trace Path',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isPathActive
                                          ? (isDark
                                                ? Colors.white12
                                                : Colors.grey.shade200)
                                          : (isDark
                                                ? const Color(0xFF00E5FF)
                                                : const Color(0xFF1565C0)),
                                      foregroundColor: isPathActive
                                          ? (isDark
                                                ? Colors.white70
                                                : Colors.black87)
                                          : (isDark
                                                ? Colors.black87
                                                : Colors.white),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Mini-Card Preview when a Squad Member is tapped
          if (_selectedSquadMember != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: AnimatedFadeSlide(
                duration: const Duration(milliseconds: 320),
                offset: const Offset(0, 0.14),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF181818) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _selectedSquadMember!.avatarColor.withValues(
                        alpha: 0.4,
                      ),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.45 : 0.12,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: PujaColors.festivalGold,
                                  width: 1.5,
                                ),
                              ),
                              child: ClipOval(
                                child: _selectedSquadMember!.photoUrl != null &&
                                        _selectedSquadMember!.photoUrl!.isNotEmpty
                                    ? Image.network(
                                        _selectedSquadMember!.photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => CircleAvatar(
                                          backgroundColor: _selectedSquadMember!.avatarColor
                                              .withValues(alpha: 0.2),
                                          foregroundColor: _selectedSquadMember!.avatarColor,
                                          child: Text(
                                            _selectedSquadMember!.initials,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                    : CircleAvatar(
                                        backgroundColor: _selectedSquadMember!.avatarColor
                                            .withValues(alpha: 0.2),
                                        foregroundColor: _selectedSquadMember!.avatarColor,
                                        child: Text(
                                          _selectedSquadMember!.initials,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _selectedSquadMember!.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      if (_selectedSquadMember!.isHost) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'HOST',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedSquadMember!.status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                              tooltip: 'Dismiss',
                              onPressed: () =>
                                  setState(() => _selectedSquadMember = null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Distance badge and Battery
                        Row(
                          children: [
                            if (_userPosition != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.near_me_outlined,
                                      size: 12,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formatDistance(
                                        haversineMeters(
                                          _userPosition!.latitude,
                                          _userPosition!.longitude,
                                          _selectedSquadMember!.latitude,
                                          _selectedSquadMember!.longitude,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.battery_std_rounded,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_selectedSquadMember!.batteryLevel}% Battery',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Action buttons: Trace Path & Ping
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: PujaColors.durgaRed,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                icon: _isCalculatingRoute
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.directions_walk_rounded,
                                        size: 18,
                                      ),
                                label: Text(
                                  _isCalculatingRoute
                                      ? 'Tracing...'
                                      : 'Trace Path to ${_selectedSquadMember!.name.split(' ')[0]}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: _isCalculatingRoute
                                    ? null
                                    : () => _highlightRouteToMember(
                                        _selectedSquadMember!,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              icon: const Icon(
                                Icons.notifications_active_outlined,
                                size: 20,
                              ),
                              tooltip: 'Ping Member',
                              onPressed: () {
                                HapticFeedback.heavyImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '🔔 Ping sent to ${_selectedSquadMember!.name}!',
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Mini-Card Preview when a Food Spot / Restaurant is tapped
          if (_selectedFoodSpot != null &&
              _selectedPandal == null &&
              _selectedSquadMember == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: AnimatedFadeSlide(
                duration: const Duration(milliseconds: 320),
                offset: const Offset(0, 0.14),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1C18) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.45 : 0.12,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                _selectedFoodSpot!.type,
                                style: const TextStyle(
                                  color: Color(0xFFE65100),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (_selectedFoodSpot!.rating != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C853)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 12,
                                      color: Color(0xFF00C853),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      _selectedFoodSpot!.rating!
                                          .toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF00C853),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                              tooltip: 'Dismiss',
                              onPressed: () => setState(() {
                                _selectedFoodSpot = null;
                                _highlightedRoute = null;
                              }),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFoodSpot!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.dynamicFont(15.5),
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (_selectedFoodSpot!.mustTry != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '🍲 Must Try: ${_selectedFoodSpot!.mustTry}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.dynamicFont(12.5),
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFFFFAB40)
                                  : const Color(0xFFD84315),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildInfoBadge(
                              icon: Icons.location_on_outlined,
                              label: 'Near ${_selectedFoodSpot!.nearbyPandal}',
                              isDark: isDark,
                            ),
                            if (_selectedFoodSpot!.priceRange != null)
                              _buildInfoBadge(
                                icon: Icons.payments_outlined,
                                label: _selectedFoodSpot!.priceRange!,
                                isDark: isDark,
                              ),
                            if (_userPosition != null)
                              _buildInfoBadge(
                                icon: Icons.near_me_rounded,
                                label: formatDistance(
                                  haversineMeters(
                                    _userPosition!.latitude,
                                    _userPosition!.longitude,
                                    _selectedFoodSpot!.lat,
                                    _selectedFoodSpot!.lng,
                                  ),
                                ),
                                isDark: isDark,
                                iconColor: Colors.orange.shade800,
                                highlight: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: FilledButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _showFoodSpotSheet(
                                    _selectedFoodSpot!,
                                    isDark,
                                  );
                                },
                                icon: const Icon(
                                  Icons.info_outline_rounded,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Details',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFE65100),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 5,
                              child: Builder(
                                builder: (context) {
                                  final bool isPathActive =
                                      _highlightedRoute != null &&
                                      _highlightedRoute!.destinationTitle ==
                                          _selectedFoodSpot!.name;
                                  return FilledButton.icon(
                                    onPressed: _isCalculatingRoute
                                        ? null
                                        : () {
                                            if (isPathActive) {
                                              _clearRoute();
                                            } else {
                                              _highlightRouteToFoodSpot(
                                                _selectedFoodSpot!,
                                              );
                                            }
                                          },
                                    icon: _isCalculatingRoute
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            isPathActive
                                                ? Icons.close_rounded
                                                : Icons.directions_walk_rounded,
                                            size: 16,
                                          ),
                                    label: Text(
                                      isPathActive
                                          ? 'Clear Path'
                                          : 'Trace Path',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isPathActive
                                          ? (isDark
                                                ? Colors.white12
                                                : Colors.grey.shade200)
                                          : (isDark
                                                ? const Color(0xFF00E5FF)
                                                : const Color(0xFF1565C0)),
                                      foregroundColor: isPathActive
                                          ? (isDark
                                                ? Colors.white70
                                                : Colors.black87)
                                          : (isDark
                                                ? Colors.black87
                                                : Colors.white),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Mini-Card Preview when a Metro Station is tapped
          if (_selectedMetroStation != null &&
              _selectedPandal == null &&
              _selectedSquadMember == null &&
              _selectedFoodSpot == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: AnimatedFadeSlide(
                duration: const Duration(milliseconds: 320),
                offset: const Offset(0, 0.14),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1F2A) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _selectedMetroStation!.line.color.withValues(
                        alpha: 0.6,
                      ),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.45 : 0.12,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedMetroStation!.line.color
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: _selectedMetroStation!.line.color
                                      .withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                _selectedMetroStation!.line.label.toUpperCase(),
                                style: TextStyle(
                                  color: _selectedMetroStation!.line.color,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if (_selectedMetroStation!.isInterchange) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32)
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: const Color(0xFF2E7D32)
                                        .withValues(alpha: 0.5),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'INTERCHANGE',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                              tooltip: 'Dismiss',
                              onPressed: () => setState(() {
                                _selectedMetroStation = null;
                                _highlightedRoute = null;
                              }),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedMetroStation!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.dynamicFont(16),
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _selectedMetroStation!.line.corridor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.dynamicFont(11.5),
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        if (_selectedMetroStation!
                            .popularPandalsNearby
                            .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _selectedMetroStation!
                                .popularPandalsNearby
                                .take(3)
                                .map((pandalName) {
                                  return ActionChip(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    labelPadding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.grey.shade100,
                                    avatar: const Icon(
                                      Icons.temple_hindu_rounded,
                                      size: 12,
                                      color: PujaColors.festivalGold,
                                    ),
                                    label: Text(
                                      pandalName,
                                      style: TextStyle(
                                        fontSize: context.dynamicFont(10),
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                    onPressed: () {
                                      final match = _pandals.firstWhere(
                                        (p) => p.name.toLowerCase().contains(
                                          pandalName.toLowerCase(),
                                        ),
                                        orElse: () => _pandals.first,
                                      );
                                      _onPandalSelectedFromSearch(match);
                                    },
                                  );
                                })
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _animatedMapMove(
                                    LatLng(
                                      _selectedMetroStation!.latitude,
                                      _selectedMetroStation!.longitude,
                                    ),
                                    16.5,
                                  );
                                },
                                icon: const Icon(
                                  Icons.my_location_rounded,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Center on Map',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      _selectedMetroStation!.line.color,
                                  side: BorderSide(
                                    color: _selectedMetroStation!.line.color
                                        .withValues(alpha: 0.5),
                                    width: 1.2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 5,
                              child: Builder(
                                builder: (context) {
                                  final bool isPathActive =
                                      _highlightedRoute != null &&
                                      _highlightedRoute!.destinationTitle ==
                                          _selectedMetroStation!.name;
                                  return FilledButton.icon(
                                    onPressed: _isCalculatingRoute
                                        ? null
                                        : () {
                                            if (isPathActive) {
                                              _clearRoute();
                                            } else {
                                              _highlightRouteToMetroStation(
                                                _selectedMetroStation!,
                                              );
                                            }
                                          },
                                    icon: _isCalculatingRoute
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            isPathActive
                                                ? Icons.close_rounded
                                                : Icons.directions_walk_rounded,
                                            size: 16,
                                          ),
                                    label: Text(
                                      isPathActive
                                          ? 'Clear Path'
                                          : 'Trace Path',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isPathActive
                                          ? (isDark
                                                ? Colors.white12
                                                : Colors.grey.shade200)
                                          : (isDark
                                                ? const Color(0xFF00E5FF)
                                                : const Color(0xFF1565C0)),
                                      foregroundColor: isPathActive
                                          ? (isDark
                                                ? Colors.white70
                                                : Colors.black87)
                                          : (isDark
                                                ? Colors.black87
                                                : Colors.white),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
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

          // Floating Quick Actions (Nearest Pandal, Cuisine, Guide, Region, GPS)
          // Managed inside the Stack with a subtle, minimalistic fade & micro-glide
          Positioned(
            right: 16,
            bottom: 24,
            child: AnimatedOpacity(
              opacity:
                  (_selectedPandal == null &&
                      _selectedSquadMember == null &&
                      _selectedFoodSpot == null &&
                      _selectedMetroStation == null)
                  ? 1.0
                  : 0.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: IgnorePointer(
                ignoring:
                    (_selectedPandal != null ||
                    _selectedSquadMember != null ||
                    _selectedFoodSpot != null ||
                    _selectedMetroStation != null),
                child: AnimatedSlide(
                  offset:
                      (_selectedPandal == null &&
                          _selectedSquadMember == null &&
                          _selectedFoodSpot == null &&
                          _selectedMetroStation == null)
                      ? Offset.zero
                      : const Offset(0, 0.04),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Light / Dark Mode Toggle FAB (Easy thumb navigation on map)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark
                                      ? PujaColors.festivalGold
                                      : Colors.black87)
                                  .withValues(alpha: 0.20),
                              blurRadius: 10,
                              spreadRadius: 0.5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Consumer<ThemeService>(
                          builder: (context, themeService, _) {
                            final isDarkActive = themeService.isDarkMode;
                            return FloatingActionButton(
                              heroTag: 'theme_toggle_map_fab',
                              elevation: 3,
                              highlightElevation: 6,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                themeService.toggleTheme();
                              },
                              backgroundColor: isDark
                                  ? const Color(0xFF22232A)
                                  : Colors.white,
                              foregroundColor: isDarkActive
                                  ? PujaColors.goldBright
                                  : const Color(0xFF1E293B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  color: isDarkActive
                                      ? PujaColors.goldBright
                                          .withValues(alpha: 0.7)
                                      : const Color(0xFFCBD5E1),
                                  width: 1.8,
                                ),
                              ),
                              tooltip: isDarkActive
                                  ? 'Switch to Light Mode'
                                  : 'Switch to Dark Mode',
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                transitionBuilder: (child, anim) =>
                                    RotationTransition(
                                  turns: anim,
                                  child: FadeTransition(
                                    opacity: anim,
                                    child: child,
                                  ),
                                ),
                                child: Icon(
                                  isDarkActive
                                      ? Icons.light_mode_rounded
                                      : Icons.dark_mode_rounded,
                                  key: ValueKey<bool>(isDarkActive),
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Quick Nearest Pandal (Red Navigation Arrow Button)
                      Tooltip(
                        message: 'Nearest Pandal (10km) • Red Arrow Radar',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF1744)
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                spreadRadius: 0.5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: FloatingActionButton(
                            heroTag: 'nearest_pandal_red_arrow_fab',
                            elevation: 3,
                            highlightElevation: 6,
                            onPressed: _isCalculatingRoute
                                ? null
                                : _findAndHighlightNearestPandal,
                            backgroundColor: isDark
                                ? const Color(0xFF22232A)
                                : Colors.white,
                            foregroundColor: const Color(0xFFFF1744),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(
                                color: Color(0xFFFF1744),
                                width: 2.2,
                              ),
                            ),
                            child: _isCalculatingRoute
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Color(0xFFFF1744),
                                    ),
                                  )
                                : const Icon(
                                    Icons.navigation_rounded,
                                    color: Color(0xFFFF1744),
                                    size: 26,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // App Walkthrough & Guide (Festival Gold Button)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: PujaColors.festivalGold
                                  .withValues(alpha: 0.30),
                              blurRadius: 10,
                              spreadRadius: 0.5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: FloatingActionButton(
                          heroTag: 'app_tutorial_fab',
                          elevation: 3,
                          highlightElevation: 6,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            AppTutorialDialog.show(context);
                          },
                          backgroundColor: isDark
                              ? const Color(0xFF22232A)
                              : Colors.white,
                          foregroundColor: PujaColors.festivalGold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(
                              color: PujaColors.festivalGold,
                              width: 2.2,
                            ),
                          ),
                          tooltip: 'App Walkthrough & Guide',
                          child: const Icon(
                            Icons.help_outline_rounded,
                            color: PujaColors.festivalGold,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Center & Follow My GPS Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: _followUser
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF2979FF)
                                        .withValues(alpha: 0.38),
                                    blurRadius: 10,
                                    spreadRadius: 0.5,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: FloatingActionButton(
                          heroTag: 'follow_user_gps_fab',
                          elevation: 3,
                          highlightElevation: 6,
                          onPressed: _toggleFollowUser,
                          backgroundColor: _followUser
                              ? const Color(0xFF2979FF)
                              : (isDark
                                  ? const Color(0xFF22232A)
                                  : Colors.white),
                          foregroundColor: _followUser
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: _followUser
                                  ? const Color(0xFF2979FF)
                                  : (isDark
                                      ? const Color(0xFF4A4B56)
                                      : const Color(0xFFCFD1DC)),
                              width: 2.2,
                            ),
                          ),
                          tooltip: _followUser
                              ? 'Live Tracking Active (Tap for free-roam)'
                              : 'Center & Follow My GPS',
                          child: Icon(
                            _followUser
                                ? Icons.navigation_rounded
                                : Icons.my_location,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
                  color: hasFilter
                      ? PujaColors.goldBright
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(width: 2),
              if (hasFilter)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _locateZone(null);
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: PujaColors.goldBright,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneChip(String label, KolkataZone? zone, bool isDark) {
    final isSelected = !_filterNearby10Km && _selectedZone == zone;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Material(
        elevation: isSelected ? 3 : 0,
        color: isSelected
            ? PujaColors.crimsonVelvet
            : (isDark ? PujaColors.nightSurface : Colors.grey.shade100),
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected
                ? PujaColors.festivalGold
                : PujaColors.festivalGold.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            setState(() => _filterNearby10Km = false);
            _locateZone(isSelected && zone != null ? null : zone);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? PujaColors.goldBright
                    : (isDark ? Colors.white70 : Colors.black87),
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyChip(bool isDark) {
    final isSelected = _filterNearby10Km;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Material(
        elevation: isSelected ? 3 : 0,
        color: isSelected
            ? PujaColors.crimsonVelvet
            : (isDark ? PujaColors.nightSurface : Colors.grey.shade100),
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected
                ? PujaColors.festivalGold
                : PujaColors.festivalGold.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            if (_filterNearby10Km) {
              setState(() {
                _filterNearby10Km = false;
                _highlightedRoute = null;
              });
              _showStatusPill(
                'Nearby filter cleared · Showing all',
                icon: Icons.filter_alt_off_rounded,
              );
            } else {
              setState(() {
                _selectedZone = null;
                _followUser = false;
              });
              _findAndHighlightNearestPandal();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.navigation_rounded,
                  size: 14,
                  color: Color(0xFFFF1744),
                ),
                const SizedBox(width: 5),
                Text(
                  'Nearby (10km)',
                  style: TextStyle(
                    color: isSelected
                        ? PujaColors.goldBright
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTrailChip(bool isDark) {
    return Consumer<CustomHoppingTrailService>(
      builder: (context, trailService, _) {
        final hasActive = trailService.hasActiveTrail;
        final trail = trailService.activeTrail;

        return Padding(
          padding: const EdgeInsets.only(right: 6.0),
          child: Material(
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
                  initialLocation: _userPosition != null
                      ? LatLng(
                          _userPosition!.latitude,
                          _userPosition!.longitude,
                        )
                      : null,
                  initialLocationLabel: _userPosition != null
                      ? 'My Live Location'
                      : null,
                  onTrailStarted: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _showMapSearchBar = false);
                    final firstStop =
                        trailService.activeTrail?.currentTargetPandal;
                    if (firstStop != null) {
                      _animatedMapMove(
                        LatLng(firstStop.lat, firstStop.lng),
                        15.5,
                      );
                    }
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: hasActive
                          ? Colors.black87
                          : PujaColors.festivalGold,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasActive
                          ? 'Trail (${trail!.visitedCount}/${trail.totalStops})'
                          : 'Plan Trail ⏱️',
                      style: TextStyle(
                        color: hasActive
                            ? Colors.black87
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontSize: 11.5,
                        fontWeight: hasActive
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetroToggleChip(bool isDark) {
    final isSelected = _showMetroStations;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Material(
        elevation: isSelected ? 3 : 0,
        color: isSelected
            ? PujaColors.metroBlue
            : (isDark ? PujaColors.nightSurface : Colors.grey.shade100),
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected
                ? Colors.white
                : PujaColors.metroBlue.withValues(alpha: 0.4),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _showMetroStations = !_showMetroStations);
            _showStatusPill(
              _showMetroStations
                  ? '🚇 Showing 40+ Kolkata Metro stations on map'
                  : 'Metro stations hidden',
              icon: Icons.subway_rounded,
              color: _showMetroStations ? PujaColors.metroBlue : null,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.subway_rounded,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : PujaColors.metroBlue,
                ),
                const SizedBox(width: 5),
                Text(
                  'Metro (${MetroRepository.allStations.length})',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontSize: 11.5,
                    fontWeight: isSelected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodToggleChip(bool isDark) {
    final isSelected = _showFoodSpots;
    final count = _foodSpots.length;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Material(
        elevation: isSelected ? 3 : 0,
        color: isSelected
            ? const Color(0xFFE65100)
            : (isDark ? PujaColors.nightSurface : Colors.grey.shade100),
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected
                ? Colors.white
                : const Color(0xFFE65100).withValues(alpha: 0.4),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _showFoodSpots = !_showFoodSpots);
            _showStatusPill(
              _showFoodSpots
                  ? '🍲 Showing $count iconic Food spots on map'
                  : 'Food spots hidden',
              icon: Icons.restaurant_rounded,
              color: _showFoodSpots ? const Color(0xFFFF9100) : null,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.restaurant_rounded,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFFE65100),
                ),
                const SizedBox(width: 5),
                Text(
                  'Food ($count)',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontSize: 11.5,
                    fontWeight: isSelected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatarButton(BuildContext context, bool isDark) {
    final user = context.select<AuthService?, AppUser?>((a) => a?.currentUserModel);
    final photoUrl = user?.photoUrl;
    final isGoogle = user != null && !user.isGuest;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            UserProfileSheet.show(context);
          },
          child: Tooltip(
            message: isGoogle ? 'Profile: ${user.displayName}' : 'Guest Profile',
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isGoogle
                      ? PujaColors.festivalGold
                      : (isDark ? Colors.white30 : Colors.black26),
                  width: 1.6,
                ),
                boxShadow: isGoogle
                    ? [
                        BoxShadow(
                          color: PujaColors.festivalGold.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: CircleAvatar(
                radius: 13,
                backgroundColor: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFE0E0E0),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Icon(
                        Icons.person_rounded,
                        size: 15,
                        color: isDark ? Colors.white70 : Colors.black87,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggleChip(BuildContext context, bool isDark) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final isDarkActive = themeService.isDarkMode;
        return Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.lightImpact();
              themeService.toggleTheme();
            },
            child: Tooltip(
              message:
                  isDarkActive ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              child: Container(
                padding: const EdgeInsets.all(5.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkActive
                      ? const Color(0xFF24242A)
                      : const Color(0xFFF1F5F9),
                  border: Border.all(
                    color: isDarkActive
                        ? PujaColors.goldBright.withValues(alpha: 0.5)
                        : Colors.black12,
                    width: 1.2,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    isDarkActive
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    key: ValueKey<bool>(isDarkActive),
                    size: 17,
                    color: isDarkActive
                        ? PujaColors.goldBright
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSquadFriendsAtAGlance(bool isDark, SquadService squadService) {
    final companions = squadService.companionMembers;
    final userPos = _userPosition;

    return AnimatedFadeSlide(
      duration: const Duration(milliseconds: 240),
      offset: const Offset(0, -0.1),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF161618) : Colors.white).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: PujaColors.festivalGold.withValues(alpha: 0.4),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Squad Code Badge
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                MainNavigationScreen.switchTab(context, 3);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: PujaColors.durgaRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: PujaColors.durgaRed.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_rounded, size: 14, color: PujaColors.durgaRed),
                    const SizedBox(width: 4),
                    Text(
                      squadService.squadCode ?? 'SQUAD',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: PujaColors.durgaRed,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Divider
            Container(
              width: 1,
              height: 22,
              color: isDark ? Colors.white12 : Colors.black12,
            ),

            const SizedBox(width: 6),

            // Companions list or Waiting for friends state
            if (companions.isEmpty)
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Squad active • Waiting for friends...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.person_add_rounded, size: 14, color: PujaColors.festivalGold),
                      label: const Text(
                        'Demo Hopper',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PujaColors.festivalGold),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        squadService.addDemoCompanions();
                      },
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: companions.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final member = companions[idx];
                    final isFocused = _selectedSquadMember?.id == member.id;
                    final distStr = userPos != null
                        ? '${(haversineMeters(userPos.latitude, userPos.longitude, member.latitude, member.longitude)).round()}m'
                        : 'Live';

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _animatedMapMove(
                          LatLng(member.latitude, member.longitude),
                          (_mapController.camera.zoom < 15.5 ? 15.5 : _mapController.camera.zoom),
                        );
                        _highlightRouteToMember(member);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isFocused
                              ? PujaColors.festivalGold.withValues(alpha: 0.2)
                              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFocused ? PujaColors.festivalGold : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Friend Google DP with online dot
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: member.avatarColor,
                                  backgroundImage: (member.photoUrl != null && member.photoUrl!.isNotEmpty)
                                      ? NetworkImage(member.photoUrl!)
                                      : null,
                                  child: (member.photoUrl == null || member.photoUrl!.isEmpty)
                                      ? Text(
                                          member.initials,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 5),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name.split(' ')[0],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  distStr,
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00E676),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.travel_explore,
                      color: PujaColors.durgaRed,
                    ),
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
                              color: isDark
                                  ? Colors.white
                                  : PujaColors.crimsonVelvet,
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: PujaColors.durgaRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    _buildRegionCategoryHeader('Kolkata Metro Zones', isDark),
                    _buildRegionTile(
                      KolkataZone.northKolkata,
                      'উত্তর কলকাতা',
                      Icons.location_city,
                      isDark,
                      ctx,
                    ),
                    _buildRegionTile(
                      KolkataZone.centralKolkata,
                      'মধ্য কলকাতা',
                      Icons.account_balance,
                      isDark,
                      ctx,
                    ),
                    _buildRegionTile(
                      KolkataZone.southKolkata,
                      'দক্ষিণ কলকাতা',
                      Icons.festival,
                      isDark,
                      ctx,
                    ),
                    const SizedBox(height: 12),
                    _buildRegionCategoryHeader(
                      'Greater Bengal Suburbs (Nadia & Hooghly)',
                      isDark,
                    ),
                    _buildRegionTile(
                      KolkataZone.nadiaKalyani,
                      'কল্যাণী (নদিয়া)',
                      Icons.temple_hindu,
                      isDark,
                      ctx,
                    ),
                    _buildRegionTile(
                      KolkataZone.hooghlyChinsurah,
                      'চুঁচুড়া (হুগলি)',
                      Icons.water,
                      isDark,
                      ctx,
                    ),
                    _buildRegionTile(
                      KolkataZone.hooghlyBandel,
                      'ব্যান্ডেল (হুগলি)',
                      Icons.church,
                      isDark,
                      ctx,
                    ),
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
            color: isSelected
                ? PujaColors.festivalGold
                : (isDark ? Colors.white12 : Colors.black12),
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
                        : (isDark
                              ? PujaColors.nightSurface
                              : PujaColors.goldSoft),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? PujaColors.goldBright
                        : PujaColors.crimsonVelvet,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PujaColors.crimsonVelvet
                        : PujaColors.goldSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count Pandals',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? PujaColors.goldBright
                          : PujaColors.crimsonVelvet,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: isSelected
                      ? PujaColors.crimsonVelvet
                      : (isDark ? Colors.white38 : Colors.black26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFoodSpotSheet(FoodSpot f, bool isDark) {
    if (_selectedPandal != null || _selectedSquadMember != null) {
      setState(() {
        _selectedPandal = null;
        _selectedSquadMember = null;
      });
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final distanceStr = _userPosition != null
            ? formatDistance(
                haversineMeters(
                  _userPosition!.latitude,
                  _userPosition!.longitude,
                  f.lat,
                  f.lng,
                ),
              )
            : null;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? PujaColors.nightCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? PujaColors.nightBorder
                    : PujaColors.festivalGold.withValues(alpha: 0.5),
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
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
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
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade800.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.orange.shade800.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  f.type,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFFFFAB40)
                                        : Colors.orange.shade900,
                                  ),
                                ),
                              ),
                              if (f.rating != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C853)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF00C853)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 13,
                                        color: Color(0xFF00C853),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        f.rating!.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF00C853),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (f.priceRange != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isDark
                                        ? Colors.white10
                                        : Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    f.priceRange!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (f.mustTry != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF332014), const Color(0xFF22160F)]
                            : [
                                const Color(0xFFFFF3E0),
                                const Color(0xFFFFE0B2),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🍲 ', style: TextStyle(fontSize: 13)),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.black87,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Must Try: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                                TextSpan(
                                  text: f.mustTry!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
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
                      const DurgaFaceIcon(
                        size: 18,
                        color: PujaColors.festivalGold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nearby Pandal: ${f.nearbyPandal}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            if (f.source != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  f.source!,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (distanceStr != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: PujaColors.crimsonVelvet.withValues(
                              alpha: 0.1,
                            ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _selectFoodSpot(f);
                        },
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('Center on Map'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(ctx).pop();
                          _highlightRouteToFoodSpot(f);
                        },
                        icon: const Icon(
                          Icons.directions_walk_rounded,
                          size: 18,
                        ),
                        label: const Text('Trace Path'),
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


  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required bool isDark,
    Color? iconColor,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
      decoration: BoxDecoration(
        color: highlight
            ? PujaColors.durgaRed.withValues(alpha: isDark ? 0.20 : 0.09)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlight
              ? PujaColors.durgaRed.withValues(alpha: 0.35)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06)),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: iconColor ?? (isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight
                  ? PujaColors.durgaRed
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.88)
                        : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClusteredPandalLayer extends StatelessWidget {
  const _ClusteredPandalLayer({
    required this.visiblePandals,
    required this.selectedPandal,
    required this.pulseController,
    required this.onSelectPandal,
    required this.onZoomToCluster,
  });

  final List<Pandal> visiblePandals;
  final Pandal? selectedPandal;
  final AnimationController pulseController;
  final ValueChanged<Pandal> onSelectPandal;
  final void Function(LatLng point, double targetZoom) onZoomToCluster;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final trailService = Provider.of<CustomHoppingTrailService>(
      context,
      listen: false,
    );
    final activeTrail = trailService.activeTrail;
    final activeTrailIds = activeTrail?.stops.map((s) => s.id).toSet();

    final clusterItems = PandalSpatialClusterer.cluster(
      allPandals: visiblePandals,
      zoom: camera.zoom,
      visibleBounds: camera.visibleBounds,
      selectedPandal: selectedPandal,
      priorityPandalIds: activeTrailIds,
    );

    return RepaintBoundary(
      child: MarkerLayer(
        markers: clusterItems.map((item) {
        if (item.isCluster) {
          final count = item.count;
          final isLarge = count > 99;
          final visualSize = isLarge ? 44.0 : 38.0;

          return Marker(
            point: item.point,
            width: 52,
            height: 52,
            alignment: Alignment.center,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                final nextZoom = (camera.zoom + 1.8).clamp(11.0, 16.5);
                onZoomToCluster(item.point, nextZoom);
              },
              child: RepaintBoundary(
                child: Center(
                  child: Container(
                    width: visualSize,
                    height: visualSize,
                    decoration: BoxDecoration(
                      color: PujaColors.crimsonVelvet,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: PujaColors.festivalGold,
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: PujaColors.festivalGold.withValues(alpha: 0.45),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                        const BoxShadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        count > 999
                            ? '${(count / 1000).toStringAsFixed(1)}k'
                            : '$count',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: isLarge ? 12.5 : 12.0,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final p = item.primaryPandal ?? item.pandals.first;
        final isSelected = selectedPandal?.id == p.id;

        return Marker(
          point: LatLng(p.lat, p.lng),
          width: isSelected ? 58 : 48,
          height: isSelected ? 58 : 48,
          alignment: Alignment.center,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelectPandal(p);
            },
            child: isSelected
                ? RepaintBoundary(
                    child: Center(
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: PujaColors.crimsonVelvet,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PujaColors.goldBright,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: PujaColors.festivalGold.withValues(alpha: 0.85),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: PujaColors.goldBright,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : RepaintBoundary(
                    child: Builder(
                      builder: (context) {
                        int trailIndex = -1;
                        if (activeTrail != null) {
                          trailIndex = activeTrail.stops.indexWhere(
                            (s) => s.id == p.id,
                          );
                        }

                        if (trailIndex != -1 && activeTrail != null) {
                          final isVisited = activeTrail.visitedPandalIds
                              .contains(p.id);
                          final isCurrent =
                              trailIndex == activeTrail.currentStopIndex;

                          return Center(
                            child: Container(
                              width: isCurrent ? 36 : 30,
                              height: isCurrent ? 36 : 30,
                              decoration: BoxDecoration(
                                color: isVisited
                                    ? const Color(0xFF00C853)
                                    : (isCurrent
                                           ? const Color(0xFFFF1744)
                                           : PujaColors.festivalGold),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.0,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isVisited
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                    : Text(
                                        '${trailIndex + 1}',
                                        style: TextStyle(
                                          color: isCurrent
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }

                        return Center(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: PujaColors.crimsonVelvet,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: PujaColors.festivalGold,
                                width: 2.0,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 4,
                                  offset: Offset(0, 1.5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        );
      }).toList(),
      ),
    );
  }
}
