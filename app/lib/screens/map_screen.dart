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

import 'package:flutter_tts/flutter_tts.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../models/app_user.dart';
import '../models/pandal.dart';
import '../models/squad_member.dart';
import '../models/toilet.dart';
import '../models/trail_leg.dart';
import '../repositories/local_pandal_repository.dart';
import '../repositories/metro_repository.dart';
import '../repositories/pandal_repository.dart';
import '../repositories/supplementary_repository.dart';
import '../services/auth_service.dart';
import '../services/custom_hopping_trail_service.dart';
import '../services/location_service.dart';
import '../services/position_interpolator.dart';
import '../services/routing_service.dart';
import '../services/squad_service.dart';
import '../services/theme_service.dart';
import '../services/pandal_user_state_service.dart';
import '../utils/constants.dart';
import '../utils/haversine.dart';
import '../utils/pandal_spatial_cluster.dart';
import '../utils/responsive.dart';
import '../widgets/custom_trail_planner_dialog.dart';
import '../widgets/pandal_detail_sheet.dart';
import '../widgets/pandal_search_autocomplete.dart';
import '../widgets/app_tutorial_dialog.dart';
import '../widgets/animated_fade_slide.dart';
import '../widgets/durga_face_icon.dart';
import '../widgets/puja_icons.dart';
import '../widgets/user_profile_sheet.dart';
import '../widgets/leaflet_map_components.dart';
import 'main_navigation_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.repository, this.onMapReady});

  final PandalRepository? repository;
  final VoidCallback? onMapReady;

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

  /// Global notifier to request an in-app walking route or centering on a target public toilet.
  static final ValueNotifier<({ToiletEntry toilet, bool traceRoute})?>
  pendingToiletAction = ValueNotifier<({ToiletEntry toilet, bool traceRoute})?>(
    null,
  );

  /// Helper to route to a toilet from any screen without external apps
  static void routeToToilet(BuildContext context, ToiletEntry toilet) {
    pendingToiletAction.value = (toilet: toilet, traceRoute: true);
    MainNavigationScreen.switchTab(context, 0);
  }

  /// Helper to center on a toilet from any screen
  static void centerOnToilet(BuildContext context, ToiletEntry toilet) {
    pendingToiletAction.value = (toilet: toilet, traceRoute: false);
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
  List<PandalToilets> _allToilets = [];
  bool _showFoodSpots = false;
  bool _showMetroStations = false;
  bool _showToilets = false;
  bool _filterNearby10Km = false;
  bool _isLoading = true;

  KolkataZone? _selectedZone;
  Pandal? _selectedPandal;
  SquadMember? _selectedSquadMember;
  FoodSpot? _selectedFoodSpot;
  MetroStation? _selectedMetroStation;
  ToiletEntry? _selectedToilet;
  Position? _userPosition;

  List<ToiletEntry> get _uniqueToilets {
    final map = <String, ToiletEntry>{};
    for (final pt in _allToilets) {
      for (final t in pt.allNearby) {
        map[t.id] = t;
      }
      if (pt.nearestMale != null) {
        map[pt.nearestMale!.id] = pt.nearestMale!;
      }
      if (pt.nearestFemale != null) {
        map[pt.nearestFemale!.id] = pt.nearestFemale!;
      }
    }
    return map.values.toList();
  }

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
  double _mapRotation = 0.0;
  String? _lastFramedTrailId;
  late final PositionInterpolator _positionInterpolator;

  // Turn-by-turn Navigation State
  bool _isNavigating = false;
  WalkingRoute? _navigationRoute;
  int _currentStepIndex = 0;
  Timer? _navigationInstructionTimer;
  FlutterTts? _tts;
  bool _ttsInitialized = false;

  // Trail Polyline Memoization Cache (prevents frame drops and blank tile lag on GPS updates)
  List<Polyline>? _cachedTrailCorePolylines;
  String? _cachedTrailCoreKey;

  // Floating Status Pill State (Minimal Negative Feedback)
  OverlayEntry? _statusOverlayEntry;
  Timer? _statusOverlayTimer;

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
        _statusOverlayTimer?.cancel();
        _statusOverlayEntry?.remove();
        _statusOverlayEntry = null;
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

  void _showStatusPill(
    String message, {
    IconData? icon,
    Color? color,
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    _statusOverlayTimer?.cancel();
    _statusOverlayEntry?.remove();
    _statusOverlayEntry = null;

    if (!mounted || _isSearchActive) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final overlayState = Overlay.of(context, rootOverlay: true);

      _statusOverlayEntry = OverlayEntry(
        builder: (ctx) {
          final topPadding = MediaQuery.of(ctx).padding.top;
          return Positioned(
            top: topPadding + kToolbarHeight + 8,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: AnimatedFadeSlide(
                  duration: const Duration(milliseconds: 220),
                  offset: const Offset(0, -0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF1E1E24) : Colors.white)
                          .withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: color ?? PujaColors.festivalGold.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.14,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon ?? Icons.info_outline_rounded,
                          size: 16,
                          color: color ?? PujaColors.festivalGold,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1E1E24),
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
        },
      );

      overlayState.insert(_statusOverlayEntry!);

      _statusOverlayTimer = Timer(duration, () {
        if (mounted) {
          _statusOverlayEntry?.remove();
          _statusOverlayEntry = null;
        }
      });
    } catch (_) {
      // Fallback silently if overlay is unavailable
    }
  }

  @override
  void initState() {
    super.initState();
    _positionInterpolator = PositionInterpolator();
    _mapSearchController = TextEditingController();
    _mapSearchFocusNode = FocusNode();
    _mapSearchFocusNode.addListener(_handleSearchFocusOrTextChange);
    _mapSearchController.addListener(_handleSearchFocusOrTextChange);
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
    MapScreen.pendingToiletAction.addListener(
      _onPendingToiletAction,
    );
    if (MapScreen.pendingToiletAction.value != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onPendingToiletAction(),
      );
    }
    _loadData();
    _startContinuousTracking();
    _initTts();
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    await _tts!.setLanguage('en-IN');
    await _tts!.setSpeechRate(0.5);
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);
    _ttsInitialized = true;
    debugPrint('[MapScreen] TTS initialized');
  }

  @override
  void dispose() {
    MapScreen.pendingFoodSpotAction.removeListener(_onPendingFoodSpotAction);
    MapScreen.pendingPandalAction.removeListener(_onPendingPandalAction);
    MapScreen.pendingMetroStationAction.removeListener(
      _onPendingMetroStationAction,
    );
    MapScreen.pendingToiletAction.removeListener(
      _onPendingToiletAction,
    );
    _statusOverlayTimer?.cancel();
    _statusOverlayEntry?.remove();
    _statusOverlayEntry = null;
    _mapSearchFocusNode.removeListener(_handleSearchFocusOrTextChange);
    _mapSearchController.removeListener(_handleSearchFocusOrTextChange);
    _mapSearchFocusNode.dispose();
    _mapSearchController.dispose();
    LocationService.instance.stopLiveTracking();
    _cameraMoveController?.stop();
    _cameraMoveController?.dispose();
    _cameraMoveController = null;
    _pulseController.dispose();
    _positionInterpolator.dispose();
    _navigationInstructionTimer?.cancel();
    _tts?.stop();
    _tts = null;
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
      _selectedToilet = null;
    });
  }

  void _onPendingToiletAction() {
    final action = MapScreen.pendingToiletAction.value;
    if (action != null) {
      MapScreen.pendingToiletAction.value = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (action.traceRoute) {
          _highlightRouteToToilet(action.toilet);
        } else {
          _selectToilet(action.toilet);
        }
      });
    }
  }

  void _selectToilet(ToiletEntry toilet) {
    HapticFeedback.selectionClick();
    _animatedMapMove(
      LatLng(toilet.lat, toilet.lng),
      (_mapController.camera.zoom < 16.0 ? 16.0 : _mapController.camera.zoom),
    );
    setState(() {
      _selectedToilet = toilet;
      _selectedPandal = null;
      _selectedSquadMember = null;
      _selectedFoodSpot = null;
      _selectedMetroStation = null;
      _showToilets = true;
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
    final results = await Future.wait([
      _repo.all(),
      _suppRepo.getFoodSpots(),
      _suppRepo.getToilets(),
    ]);

    if (!mounted) return;
    setState(() {
      _pandals = results[0] as List<Pandal>;
      _foodSpots = results[1] as List<FoodSpot>;
      _allToilets = results[2] as List<PandalToilets>;
      _isLoading = false;
    });
    widget.onMapReady?.call();
  }

  void _startContinuousTracking() {
    LocationService.instance.startLiveTracking(
      onLocationChanged: (pos) {
        if (!mounted) return;
        setState(() => _userPosition = pos);
        _positionInterpolator.updatePosition(LatLng(pos.latitude, pos.longitude));
        SquadService.instance.updateUserLocation(pos.latitude, pos.longitude);
        if (_followUser) {
          _animatedMapMove(
            LatLng(pos.latitude, pos.longitude),
            _mapController.camera.zoom < 15.0
                ? 15.5
                : _mapController.camera.zoom,
          );
        }
        // Check for turn-by-turn navigation updates
        if (_isNavigating && _navigationRoute != null) {
          _checkNavigationProgress(pos.latitude, pos.longitude);
        }
      },
    );
  }

  /// Speak a navigation instruction
  Future<void> _speakInstruction(String instruction) async {
    if (!_ttsInitialized || _tts == null) return;
    try {
      await _tts!.speak(instruction);
    } catch (e) {
      debugPrint('[MapScreen] TTS error: $e');
    }
  }

  /// Stop turn-by-turn navigation
  Future<void> _stopNavigation() async {
    _isNavigating = false;
    _navigationRoute = null;
    _currentStepIndex = 0;
    _navigationInstructionTimer?.cancel();
    _navigationInstructionTimer = null;

    await _speakInstruction('Navigation stopped.');

    _showStatusPill(
      'Navigation stopped',
      icon: Icons.stop_rounded,
    );

    setState(() {});
  }

  /// Check navigation progress and speak next instruction when needed
  void _checkNavigationProgress(double lat, double lng) {
    if (_navigationRoute == null || _currentStepIndex >= _navigationRoute!.points.length) return;

    final currentPoint = _navigationRoute!.points[_currentStepIndex];
    final distanceToNext = Geolocator.distanceBetween(
      lat,
      lng,
      currentPoint.latitude,
      currentPoint.longitude,
    );

    // If within 15m of next waypoint, advance to next step
    if (distanceToNext < 15.0) {
      _currentStepIndex++;

      // If reached destination
      if (_currentStepIndex >= _navigationRoute!.points.length) {
        _speakInstruction('You have arrived at ${_navigationRoute!.destinationTitle}.');
        _stopNavigation();
        return;
      }

      // Speak next direction (simplified - just distance to next point)
      final nextPoint = _navigationRoute!.points[_currentStepIndex];
      final dist = Geolocator.distanceBetween(
        lat,
        lng,
        nextPoint.latitude,
        nextPoint.longitude,
      );

      if (dist < 50) {
        _speakInstruction('Continue straight for ${dist.round()} meters.');
      } else if (dist < 200) {
        _speakInstruction('In ${dist.round()} meters, continue toward ${_navigationRoute!.destinationTitle}.');
      }
    }
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
    _mapSearchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedPandal = pandal;
      _selectedSquadMember = null;
      _selectedFoodSpot = null;
      _selectedMetroStation = null;
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
    _mapSearchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedMetroStation = station;
      _selectedPandal = null;
      _selectedSquadMember = null;
      _selectedFoodSpot = null;
      _highlightedRoute = null;
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
    _mapSearchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedFoodSpot = spot;
      _showFoodSpots = true;
      _selectedPandal = null;
      _selectedSquadMember = null;
      _selectedMetroStation = null;
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
      _selectedMetroStation = null;
      _followUser = false;
      _showFoodSpots = true;
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

    _showStatusPill(
      '🚶 Path to ${spot.name} (${route.formattedDistance} · ${route.formattedDuration})',
      icon: Icons.restaurant_rounded,
      color: Colors.orange.shade800,
    );
  }

  Future<void> _highlightRouteToToilet(ToiletEntry toilet) async {
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
    final dest = LatLng(toilet.lat, toilet.lng);

    setState(() {
      if (userPos != null) _userPosition = userPos;
      _isCalculatingRoute = true;
      _selectedToilet = toilet;
      _selectedPandal = null;
      _selectedSquadMember = null;
      _selectedMetroStation = null;
      _selectedFoodSpot = null;
      _followUser = false;
      _showToilets = true;
    });

    final route = await RoutingService.instance.getWalkingRouteToPoint(
      start: start,
      destination: dest,
      destinationName: toilet.displayName,
    );

    if (!mounted) return;

    setState(() {
      _highlightedRoute = route;
      _isCalculatingRoute = false;
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

    _showStatusPill(
      '🚶 Path to ${toilet.displayName} (${route.formattedDistance} · ${route.formattedDuration})',
      icon: Icons.wc_rounded,
      color: const Color(0xFF00695C),
    );
  }

  void _clearRoute() {
    HapticFeedback.selectionClick();
    setState(() {
      _highlightedRoute = null;
      _selectedSquadMember = null;
      _selectedFoodSpot = null;
      _selectedMetroStation = null;
      _selectedToilet = null;
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
      _setContextualBanner(
        'Showing all ${_pandals.length} pandals across Kolkata & Suburbs',
        icon: Icons.auto_awesome_rounded,
      );
    } else {
      final center = _getZoneCenter(zone);
      final zoom = _getZoneZoom(zone);
      _animatedMapMove(center, zoom);

      final count = _pandals.where((p) => p.zone == zone).length;
      _setContextualBanner(
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
    final squadService = Provider.of<SquadService>(context);
    final trailService = Provider.of<CustomHoppingTrailService>(context);
    final bool isTrailActive = trailService.hasActiveTrail;
    final activeTrail = trailService.activeTrail;
    final visible = _visiblePandals;

    // Automatic Trail Mode camera framing when entering a trail
    if (isTrailActive && activeTrail != null && activeTrail.stops.isNotEmpty) {
      if (_lastFramedTrailId != activeTrail.id) {
        _lastFramedTrailId = activeTrail.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fitTrailBounds(activeTrail);
        });
      }
    } else if (!isTrailActive) {
      _lastFramedTrailId = null;
    }

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
        title: const Text('Uma Map'),
        actions: [
          // Map Marker Legend (Explains cluster numbers and marker types)
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Map Legend',
            onPressed: () => _showMapLegendSheet(context, isDark),
          ),
          // Pinned User Profile Avatar
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
                flags: InteractiveFlag.all,
                enableMultiFingerGestureRace: true,
                rotationThreshold: 15.0,
              ),
              onTap: (_, _) {
                if (_isSearchActive) {
                  _mapSearchController.clear();
                  _mapSearchFocusNode.unfocus();
                }
                if (_selectedPandal != null ||
                    _selectedSquadMember != null ||
                    _selectedFoodSpot != null ||
                    _selectedMetroStation != null) {
                  setState(() {
                    _selectedPandal = null;
                    _selectedSquadMember = null;
                    _selectedFoodSpot = null;
                    _selectedMetroStation = null;
                  });
                }
              },
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && _followUser) {
                  setState(() => _followUser = false);
                }
                if (camera.rotation != _mapRotation) {
                  setState(() => _mapRotation = camera.rotation);
                }
              },
              onMapReady: () {
                widget.onMapReady?.call();
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

              // Dual-Segment Trail Path Layer (Trail Mode)
              if (isTrailActive && activeTrail != null && activeTrail.stops.isNotEmpty)
                RepaintBoundary(
                  child: PolylineLayer(
                    polylines: _buildTrailPolylines(
                      activeTrail,
                      _effectiveUserLocation,
                      isDark,
                    ),
                  ),
                ),

              // Food / Bhog Spot Markers (Leaflet Restaurant Pins)
              if (_showFoodSpots && !isTrailActive)
                RepaintBoundary(
                  child: MarkerLayer(
                    markers: _visibleFoodSpots.map((f) {
                      final isSelected = _selectedFoodSpot?.id == f.id;
                      return Marker(
                        rotate: true,
                        point: LatLng(f.lat, f.lng),
                        width: isSelected ? 44 : 34,
                        height: isSelected ? 56 : 44,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedFoodSpot = f;
                              _selectedPandal = null;
                              _selectedMetroStation = null;
                              _highlightedRoute = null;
                            });
                            _animatedMapMove(
                              LatLng(f.lat, f.lng),
                              (_mapController.camera.zoom < 15.5
                                  ? 15.5
                                  : _mapController.camera.zoom),
                            );
                          },
                          child: LeafletMarkerPin.restaurant(
                            isSelected: isSelected,
                            pulseAnimation: isSelected ? _pulseController : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),


              // Full Kolkata Metro & Railway Stations Network Layer (Leaflet Metro Pins)
              if (_showMetroStations && !isTrailActive)
                RepaintBoundary(
                  child: MarkerLayer(
                    markers: MetroRepository.allStations.map((stn) {
                      final isStationSelected = _selectedMetroStation?.id == stn.id;
                      final isRailway = stn.name.toLowerCase().contains('railway');
                      final lineColor = isRailway ? PujaColors.railwayPurple : stn.line.color;
                      return Marker(
                        rotate: true,
                        point: LatLng(stn.latitude, stn.longitude),
                        width: isStationSelected ? 44 : 34,
                        height: isStationSelected ? 56 : 44,
                        alignment: Alignment.topCenter,
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
                          child: LeafletMarkerPin.metro(
                            isSelected: isStationSelected,
                            lineColor: lineColor,
                            isRailway: isRailway,
                            pulseAnimation: isStationSelected ? _pulseController : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Public Toilets Layer (Leaflet Toilet Pins)
              if (_showToilets && !isTrailActive)
                RepaintBoundary(
                  child: MarkerLayer(
                    markers: _uniqueToilets.map((t) {
                      final isSelected = _selectedToilet?.id == t.id;
                      return Marker(
                        rotate: true,
                        point: LatLng(t.lat, t.lng),
                        width: isSelected ? 44 : 32,
                        height: isSelected ? 56 : 40,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedToilet = t;
                              _selectedPandal = null;
                              _selectedFoodSpot = null;
                              _selectedMetroStation = null;
                              _highlightedRoute = null;
                            });
                            _animatedMapMove(
                              LatLng(t.lat, t.lng),
                              (_mapController.camera.zoom < 16.0
                                  ? 16.0
                                  : _mapController.camera.zoom),
                            );
                          },
                          child: LeafletMarkerPin.toilet(
                            isMale: t.male,
                            isFemale: t.female,
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Clustered Pandal Markers Layer in Browse Mode vs Trail Stop Markers in Trail Mode
              if (!isTrailActive)
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
                )
              else if (activeTrail != null && activeTrail.stops.isNotEmpty)
                // Active Trail Stop Markers (Numbered Pins ①②③... with Visit Progress)
                RepaintBoundary(
                  child: MarkerLayer(
                    markers: _buildTrailMarkers(context, activeTrail, isDark),
                  ),
                ),

              // Designated Squad Meet-up Landmark Flag Marker (Enlarged)
              if (squadService.hasActiveSquad && squadService.showSquadOnMap && !isTrailActive)
                RepaintBoundary(
                  child: MarkerLayer(
                    markers: [
                      Marker(
                        rotate: true,
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
              if (squadService.hasActiveSquad && squadService.showSquadOnMap && !isTrailActive)
                RepaintBoundary(
                  child: MarkerLayer(
                    markers: squadService.companionMembers.map((member) {
                      final isSelected = _selectedSquadMember?.id == member.id;
                      final avatarColor = member.avatarColor;
                      final size = isSelected ? 46.0 : 40.0;
                      return Marker(
                        rotate: true,
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
                      rotate: true,
                      point: _effectiveUserLocation!,
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
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
                                    angle: ((arrowBearing - _mapRotation) * math.pi / 180),
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
                                        AuthService? auth;
                                        try {
                                          auth = context.watch<AuthService>();
                                        } catch (_) {
                                          auth = null;
                                        }
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

              // Leaflet Map Speech-Bubble Popups for Puja Pandals, Restaurants, Metro Stations, and Toilets
              if (_selectedPandal != null ||
                  _selectedFoodSpot != null ||
                  _selectedMetroStation != null ||
                  _selectedToilet != null)
                MarkerLayer(
                  markers: [
                    if (_selectedPandal != null)
                      Marker(
                        rotate: true,
                        point: LatLng(_selectedPandal!.lat, _selectedPandal!.lng),
                        width: 290,
                        height: 220,
                        alignment: const Alignment(0.0, -1.24),
                        child: LeafletMapPopup.pandal(
                          pandal: _selectedPandal!,
                          isDark: isDark,
                          isHopped: context
                                  .watch<PandalUserStateService?>()
                                  ?.isVisited(_selectedPandal!.id) ??
                              false,
                          onClose: () {
                            setState(() {
                              _selectedPandal = null;
                            });
                          },
                          onDirections: () {
                            _highlightRouteTo(_selectedPandal!);
                          },
                          onDetails: () {
                            PandalDetailSheet.show(context, _selectedPandal!);
                          },
                          onToggleHopped: () {
                            context
                                .read<PandalUserStateService?>()
                                ?.toggleVisited(_selectedPandal!.id);
                          },
                        ),
                      )
                    else if (_selectedFoodSpot != null)
                      Marker(
                        rotate: true,
                        point: LatLng(_selectedFoodSpot!.lat, _selectedFoodSpot!.lng),
                        width: 290,
                        height: 200,
                        alignment: const Alignment(0.0, -1.24),
                        child: LeafletMapPopup.restaurant(
                          spot: _selectedFoodSpot!,
                          isDark: isDark,
                          onClose: () {
                            setState(() {
                              _selectedFoodSpot = null;
                            });
                          },
                          onDirections: () {
                            _highlightRouteToFoodSpot(_selectedFoodSpot!);
                          },
                          onDetails: () {
                            _showFoodSpotSheet(_selectedFoodSpot!, isDark);
                          },
                        ),
                      )
                    else if (_selectedMetroStation != null)
                      Marker(
                        rotate: true,
                        point: LatLng(
                          _selectedMetroStation!.latitude,
                          _selectedMetroStation!.longitude,
                        ),
                        width: 300,
                        height: 215,
                        alignment: const Alignment(0.0, -1.24),
                        child: LeafletMapPopup.metro(
                          station: _selectedMetroStation!,
                          isDark: isDark,
                          onClose: () {
                            setState(() {
                              _selectedMetroStation = null;
                            });
                          },
                          onDirections: () {
                            _highlightRouteToMetroStation(_selectedMetroStation!);
                          },
                        ),
                      )
                    else if (_selectedToilet != null)
                      Marker(
                        rotate: true,
                        point: LatLng(
                          _selectedToilet!.lat,
                          _selectedToilet!.lng,
                        ),
                        width: 290,
                        height: 180,
                        alignment: const Alignment(0.0, -1.24),
                        child: LeafletMapPopup.toilet(
                          toilet: _selectedToilet!,
                          isDark: isDark,
                          onClose: () {
                            setState(() {
                              _selectedToilet = null;
                            });
                          },
                          onDirections: () {
                            _highlightRouteToToilet(_selectedToilet!);
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PandalSearchAutocomplete(
                  controller: _mapSearchController,
                  focusNode: _mapSearchFocusNode,
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
                  },
                ),
                const SizedBox(height: 8),
                if (!_isSearchActive) ...[
                  // Trail-active: keep in a single summary bar
                  if (isTrailActive && activeTrail != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? PujaColors.nightCard : Colors.white)
                            .withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: PujaColors.festivalGold.withValues(alpha: 0.45),
                          width: 1.3,
                        ),
                      ),
                      child: _buildTrailSummaryBar(
                        context,
                        activeTrail,
                        trailService,
                        isDark,
                      ),
                    )
                  else
                    // Individual floating chips — no outer bar container
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildRegionMenuButton(isDark),
                          _buildNearbyChip(isDark),
                          _buildCustomTrailChip(isDark),
                          _buildMetroToggleChip(isDark),
                          _buildFoodToggleChip(isDark),
                          _buildToiletToggleChip(isDark),
                          if (squadService.hasActiveSquad)
                            _buildSquadStatusChip(isDark, squadService),
                          _buildThemeToggleChip(context, isDark),
                        ],
                      ),
                    ),
                  if (_contextualMessage != null) ...[
                    const SizedBox(height: 6),
                    _buildContextualBanner(isDark),
                  ],
                ],
              ],
            ),
          ),

          // Top Floating Route HUD Banner
          if (_highlightedRoute != null)
            Positioned(
              top: 122,
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

          // (Active Trail HUD is now docked in the top bar as Trail Summary Bar)

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

          // Leaflet Map Attribution Watermark (Classic "Leaflet | © OpenStreetMap contributors")
          Positioned(
            left: 8,
            bottom: 8,
            child: LeafletAttributionControl(
              isDark: isDark,
            ),
          ),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: PujaColors.durgaRed),
            ),

          // Floating Action Toolbar (Zoom In/Out, Quick Tools, GPS Follow, Compass)
          // Unified vertical stack on the right edge with matching 46x46 dimensions and smooth squircle styling
          Positioned(
            right: 16,
            bottom: 24,
            child: AnimatedSlide(
              offset: _selectedSquadMember == null
                  ? Offset.zero
                  : const Offset(0, 0.04),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _selectedSquadMember == null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: IgnorePointer(
                  ignoring: _selectedSquadMember != null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Leaflet Zoom Control (Stacked + / −)
                      LeafletZoomControl(
                        width: 46.0,
                        buttonHeight: 44.0,
                        borderRadius: 16.0,
                        iconSize: 22.0,
                        isDark: isDark,
                        onZoomIn: () {
                          final currentZoom = _mapController.camera.zoom;
                          _animatedMapMove(
                            _mapController.camera.center,
                            (currentZoom + 1.0).clamp(10.0, 18.0),
                          );
                        },
                        onZoomOut: () {
                          final currentZoom = _mapController.camera.zoom;
                          _animatedMapMove(
                            _mapController.camera.center,
                            (currentZoom - 1.0).clamp(10.0, 18.0),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Secondary Quick Map Tools (Nearest radar, Theme toggle, App guide)
                      _buildMapActionButton(
                        icon: Icon(
                          Icons.tune_rounded,
                          color: isDark
                              ? PujaColors.goldBright
                              : const Color(0xFF1E293B),
                          size: 20,
                        ),
                        onTap: () => _showMapQuickTools(context, isDark),
                        tooltip: 'Map Tools & Settings',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Center & Follow My GPS Button
                      _buildMapActionButton(
                        icon: Icon(
                          _followUser
                              ? Icons.navigation_rounded
                              : Icons.my_location,
                          color: _followUser
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          size: 22,
                        ),
                        onTap: _toggleFollowUser,
                        tooltip: _followUser
                            ? 'Live Tracking Active (Tap for free-roam)'
                            : 'Center & Follow My GPS',
                        isDark: isDark,
                        isActive: _followUser,
                        activeColor: const Color(0xFF2979FF),
                      ),

                      // Compass Reset-North Button (only shown when map is rotated)
                      if (_mapRotation.abs() > 2.0) ...[
                        const SizedBox(height: 10),
                        _buildMapActionButton(
                          icon: Transform.rotate(
                            angle: -_mapRotation * math.pi / 180,
                            child: Icon(
                              Icons.explore_rounded,
                              color: isDark
                                  ? const Color(0xFF00E5FF)
                                  : PujaColors.durgaRed,
                              size: 22,
                            ),
                          ),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _mapController.rotate(0.0);
                            _showStatusPill(
                              'Map re-oriented to North',
                              icon: Icons.explore_rounded,
                            );
                          },
                          tooltip: 'Reset to North',
                          isDark: isDark,
                        ),
                      ],
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

  /// Compact, tactile map floating action button with consistent 46x46 dimensions,
  /// squircle corners, theme borders, and smooth haptic feedback.
  Widget _buildMapActionButton({
    required Widget icon,
    required VoidCallback onTap,
    required String tooltip,
    required bool isDark,
    bool isActive = false,
    Color? activeColor,
    Color? activeBorderColor,
    double size = 46.0,
  }) {
    final bgColor = isActive
        ? (activeColor ?? const Color(0xFF2979FF))
        : (isDark ? const Color(0xFF22232A) : Colors.white);
    final borderColor = isActive
        ? (activeBorderColor ?? const Color(0xFF2979FF))
        : (isDark ? const Color(0xFF4A4B56) : const Color(0xFFCFD1DC));

    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? (activeColor ?? const Color(0xFF2979FF))
                      .withValues(alpha: 0.38)
                  : Colors.black.withValues(alpha: isDark ? 0.25 : 0.14),
              blurRadius: isActive ? 10 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }

  // ─── Shared minimal-Material floating pill helper ────────────────────────
  Widget _buildFilterPill({
    required bool isActive,
    required bool isDark,
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    Widget? customIcon,
    // trailing widget (e.g. close × or dropdown ▾)
    Widget? trailing,
  }) {
    // Light mode  – unselected: white surface   selected: onSurface dark fill
    // Dark mode   – unselected: #1E1E1E surface  selected: white fill
    final Color bg = isActive
        ? (isDark ? Colors.white : const Color(0xFF1C1C1E))
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final Color fg = isActive
        ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
        : (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF374151));

    final Color iconFg = isActive
        ? fg
        : (isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280));

    final Color border = isActive
        ? Colors.transparent
        : (isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.08));

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        elevation: isActive ? 3 : 2,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
        color: bg,
        shape: StadiumBorder(side: BorderSide(color: border, width: 1)),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          splashColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (customIcon != null)
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(iconFg, BlendMode.srcIn),
                    child: customIcon,
                  )
                else if (icon != null)
                  Icon(icon, size: 15, color: iconFg),
                if (icon != null || customIcon != null)
                  const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                    letterSpacing: -0.1,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 4),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Region menu (special: has dropdown arrow / close × / label) ─────────
  Widget _buildRegionMenuButton(bool isDark) {
    final hasFilter = _selectedZone != null;
    final Color fg = hasFilter
        ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
        : (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF374151));
    final Color iconFg = hasFilter
        ? fg
        : (isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280));

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        elevation: hasFilter ? 3 : 2,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
        color: hasFilter
            ? (isDark ? Colors.white : const Color(0xFF1C1C1E))
            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        shape: StadiumBorder(
          side: BorderSide(
            color: hasFilter
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.08)),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          splashColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          onTap: () {
            HapticFeedback.lightImpact();
            _showRegionPickerSheet(context, isDark);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_outlined, size: 15, color: iconFg),
                const SizedBox(width: 6),
                Text(
                  hasFilter ? _selectedZone!.shortLabel : 'Regions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: hasFilter ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                    letterSpacing: -0.1,
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
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Icon(Icons.close_rounded, size: 14, color: fg),
                    ),
                  )
                else
                  Icon(Icons.expand_more_rounded, size: 16, color: iconFg),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildNearbyChip(bool isDark) {
    final isSelected = _filterNearby10Km;
    return _buildFilterPill(
      isActive: isSelected,
      isDark: isDark,
      icon: Icons.near_me_outlined,
      label: 'All Nearby',
      onTap: () {
        if (_filterNearby10Km) {
          setState(() {
            _filterNearby10Km = false;
            _highlightedRoute = null;
          });
          _clearContextualBanner();
        } else {
          setState(() {
            _selectedZone = null;
            _followUser = false;
          });
          _setContextualBanner(
            '📍 Showing all nearby pandals within 10 km',
            icon: Icons.near_me_rounded,
            color: const Color(0xFF374151),
          );
          _findAndHighlightNearestPandal();
        }
      },
    );
  }

  Widget _buildCustomTrailChip(bool isDark) {
    return Consumer<CustomHoppingTrailService>(
      builder: (context, trailService, _) {
        final hasActive = trailService.hasActiveTrail;
        final trail = trailService.activeTrail;
        return _buildFilterPill(
          isActive: hasActive,
          isDark: isDark,
          icon: Icons.route_outlined,
          label: hasActive
              ? 'Trail (${trail!.visitedCount}/${trail.totalStops})'
              : 'Custom Trail',
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
              initialLocationLabel:
                  _userPosition != null ? 'My Live Location' : null,
              pandals: _pandals,
              onTrailStarted: () {
                FocusScope.of(context).unfocus();
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
        );
      },
    );
  }




  Widget _buildTrailSummaryBar(
    BuildContext context,
    ActiveCustomTrail trail,
    CustomHoppingTrailService trailService,
    bool isDark,
  ) {
    // Calculate remaining distance and time (unified with OSRM street route calculation)
    double remainingDistKm = trail.remainingRoutedDistanceKm ?? 0.0;
    int remainingMin = trail.remainingRoutedDurationMinutes ?? 0;
    final unvisitedStops = trail.stops
        .where((s) => !trail.visitedPandalIds.contains(s.id))
        .toList();

    if (trail.remainingRoutedDistanceKm == null) {
      if (unvisitedStops.isNotEmpty) {
        // Only include user location if within close walking range (<= 2000m) of the first unvisited stop.
        // If user is remote (e.g. 38.5 km away), calculate distance between the pandal stops only!
        final userLoc = _effectiveUserLocation;
        final firstStop = unvisitedStops.first;
        final bool userIsClose = userLoc != null &&
            haversineMeters(userLoc.latitude, userLoc.longitude, firstStop.lat, firstStop.lng) <= 2000.0;

        LatLng prev = userIsClose ? userLoc : LatLng(firstStop.lat, firstStop.lng);
        final startIndex = userIsClose ? 0 : 1;

        for (int i = startIndex; i < unvisitedStops.length; i++) {
          final s = unvisitedStops[i];
          final dMeters = haversineMeters(
            prev.latitude,
            prev.longitude,
            s.lat,
            s.lng,
          );
          remainingDistKm += dMeters / 1000.0;
          prev = LatLng(s.lat, s.lng);
        }
      }

      remainingMin =
          ((remainingDistKm / 4.2) * 60 + (unvisitedStops.length * 15)).round();
    }

    final String distStr = remainingDistKm < 1.0
        ? '${(remainingDistKm * 1000).round()}m'
        : '${remainingDistKm.toStringAsFixed(1)} km';

    final target = trail.currentTargetPandal;

    // Check if user is remotely located from the current target pandal (> 2.5 km)
    final userLoc = _effectiveUserLocation;
    final double? distToTargetKm = (userLoc != null && target != null)
        ? haversineMeters(userLoc.latitude, userLoc.longitude, target.lat, target.lng) / 1000.0
        : null;
    final bool isUserRemote = distToTargetKm != null && distToTargetKm > 2.5;

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
                _animatedMapMove(LatLng(target.lat, target.lng), 15.5);
                setState(() => _selectedPandal = target);
              } else {
                _fitTrailBounds(trail);
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
                    isUserRemote
                        ? 'Next: ${target.name} · ${distToTargetKm.toStringAsFixed(0)} km away (take Metro/cab)'
                        : 'Next: ${target.name}',
                    style: TextStyle(
                      color: isUserRemote
                          ? PujaColors.festivalGold
                          : (isDark ? Colors.white60 : Colors.black54),
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
              _lastFramedTrailId = null;
              _cachedTrailCorePolylines = null;
              _cachedTrailCoreKey = null;
              setState(() {
                _selectedPandal = null;
                _highlightedRoute = null;
              });
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

  List<Polyline> _buildTrailPolylines(
    ActiveCustomTrail trail,
    LatLng? liveLoc,
    bool isDark,
  ) {
    if (trail.stops.isEmpty) return const [];

    final startCoord = trail.startPoint;

    // 1. Memoized Core Trail Polylines (Glow + Brand Gold Primary Line)
    // Only reconstructed when the trail ID, routed polyline geometry, or theme changes,
    // completely eliminating map stutter and tile-loading lag caused by continuous GPS ticks.
    final String coreKey =
        '${trail.id}_${trail.routedPolyline?.length ?? 0}_${trail.hasMetroLegs}_$isDark';
    if (_cachedTrailCoreKey != coreKey || _cachedTrailCorePolylines == null) {
      final corePolylines = <Polyline>[];

      if (trail.hasMetroLegs) {
        // Multi-modal rendering: individual walk segments and authentic metro lines
        for (final leg in trail.legs) {
          if (leg.mode == LegMode.walk) {
            // Walking segment between consecutive pandals
            corePolylines.add(
              Polyline(
                points: [leg.from, leg.to],
                strokeWidth: 8.0,
                color: PujaColors.festivalGold.withValues(alpha: 0.3),
              ),
            );
            corePolylines.add(
              Polyline(
                points: [leg.from, leg.to],
                strokeWidth: 5.0,
                color: PujaColors.festivalGold,
              ),
            );
          } else if (leg.mode == LegMode.metro && leg.metroDetail != null) {
            final detail = leg.metroDetail!;
            final boardPos = detail.boardingStation.toLatLng();
            final alightPos = detail.alightingStation.toLatLng();
            final metroColor = detail.boardingStation.line.color;

            // 1. Pedestrian connection: pandal to boarding station (dashed)
            corePolylines.add(
              Polyline(
                points: [leg.from, boardPos],
                strokeWidth: 3.5,
                color: isDark ? const Color(0xFF90A4AE) : const Color(0xFF546E7A),
                pattern: StrokePattern.dashed(segments: const [6, 4]),
              ),
            );

            // 2. Metro rail track: boarding -> [interchange] -> alighting
            final metroPoints = [
              boardPos,
              if (detail.requiresInterchange && detail.interchangeStation != null)
                detail.interchangeStation!.toLatLng(),
              alightPos,
            ];
            // Glowing underlay
            corePolylines.add(
              Polyline(
                points: metroPoints,
                strokeWidth: 9.0,
                color: metroColor.withValues(alpha: 0.35),
              ),
            );
            // Solid brand transit line
            corePolylines.add(
              Polyline(
                points: metroPoints,
                strokeWidth: 5.5,
                color: metroColor,
              ),
            );

            // 3. Pedestrian connection: alighting station to pandal (dashed)
            corePolylines.add(
              Polyline(
                points: [alightPos, leg.to],
                strokeWidth: 3.5,
                color: isDark ? const Color(0xFF90A4AE) : const Color(0xFF546E7A),
                pattern: StrokePattern.dashed(segments: const [6, 4]),
              ),
            );
          }
        }
      } else {
        final List<LatLng> trailCoords;
        if (trail.routedPolyline != null && trail.routedPolyline!.length >= 2) {
          trailCoords = trail.routedPolyline!;
        } else {
          final coords = <LatLng>[];
          final firstStop = trail.stops.first;
          final double distToFirst = haversineMeters(
            startCoord.latitude,
            startCoord.longitude,
            firstStop.lat,
            firstStop.lng,
          );
          // Only include startCoord if within reasonable walking reach (<= 2000m)
          if (distToFirst > 15.0 && distToFirst <= 2000.0) {
            coords.add(startCoord);
          }
          for (final s in trail.stops) {
            coords.add(LatLng(s.lat, s.lng));
          }
          trailCoords = coords;
        }

        if (trailCoords.length >= 2) {
          // Glow/underglow line
          corePolylines.add(
            Polyline(
              points: trailCoords,
              strokeWidth: 8.5,
              color: PujaColors.festivalGold.withValues(alpha: 0.3),
            ),
          );
          // Solid brand gold primary line
          corePolylines.add(
            Polyline(
              points: trailCoords,
              strokeWidth: 5.0,
              color: PujaColors.festivalGold,
            ),
          );
        }
      }

      _cachedTrailCorePolylines = corePolylines;
      _cachedTrailCoreKey = coreKey;
    }

    final polylines = <Polyline>[];

    // 2. Segment 1: "Getting there" (Live location -> Trail's start point)
    // Thin, dashed, muted color (blueGrey). Only drawn if liveLoc is within walking reach (<= 2500m) and separated by > 60m.
    if (liveLoc != null) {
      final double distMeters = haversineMeters(
        liveLoc.latitude,
        liveLoc.longitude,
        startCoord.latitude,
        startCoord.longitude,
      );
      if (distMeters > 60.0 && distMeters <= 2500.0) {
        polylines.add(
          Polyline(
            points: [liveLoc, startCoord],
            strokeWidth: 2.8,
            color: isDark ? const Color(0xFF90A4AE) : const Color(0xFF546E7A),
            pattern: StrokePattern.dashed(segments: const [8, 6]),
          ),
        );
      }
    }

    // Add cached core lines
    if (_cachedTrailCorePolylines != null) {
      polylines.addAll(_cachedTrailCorePolylines!);
    }

    return polylines;
  }

  List<Marker> _buildTrailMarkers(
    BuildContext context,
    ActiveCustomTrail trail,
    bool isDark,
  ) {
    final markers = <Marker>[];
    final startCoord = trail.startPoint;

    // Flag start marker if distinct from Stop 1
    if (trail.stops.isNotEmpty) {
      final firstStop = trail.stops.first;
      final distToFirst = haversineMeters(
        startCoord.latitude,
        startCoord.longitude,
        firstStop.lat,
        firstStop.lng,
      );
      if (distToFirst > 60.0 && distToFirst <= 2500.0) {
        markers.add(
          Marker(
            rotate: true,
            point: startCoord,
            width: 38,
            height: 48,
            alignment: Alignment.topCenter,
            child: const LeafletMarkerPin(
              category: LeafletPinCategory.custom,
              pinColor: Color(0xFF455A64),
              customIcon: Icons.flag_rounded,
              size: 36,
            ),
          ),
        );
      }
    }

    // Numbered stop pins (①, ②, ③...) in resolved visit order
    for (int i = 0; i < trail.stops.length; i++) {
      final stop = trail.stops[i];
      final isVisited = trail.visitedPandalIds.contains(stop.id);
      final isCurrent = trail.currentTargetPandal?.id == stop.id;
      final isSelected = _selectedPandal?.id == stop.id;

      markers.add(
        Marker(
          rotate: true,
          point: LatLng(stop.lat, stop.lng),
          width: (isCurrent || isSelected) ? 48 : 38,
          height: (isCurrent || isSelected) ? 60 : 48,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedPandal = stop;
                _selectedSquadMember = null;
                _selectedMetroStation = null;
                _selectedFoodSpot = null;
              });
              _animatedMapMove(
                LatLng(stop.lat, stop.lng),
                _mapController.camera.zoom < 15.0
                    ? 15.0
                    : _mapController.camera.zoom,
              );
            },
            child: LeafletMarkerPin.pandal(
              isSelected: isSelected || isCurrent,
              isVisited: isVisited,
              trailIndex: i,
              size: (isCurrent || isSelected) ? 46 : 36,
              pulseAnimation: (isCurrent || isSelected) ? _pulseController : null,
            ),
          ),
        ),
      );
    }

    // Station badges for metro-assisted legs
    if (trail.hasMetroLegs) {
      final addedStationIds = <String>{};
      for (final leg in trail.legs) {
        if (leg.mode == LegMode.metro && leg.metroDetail != null) {
          final detail = leg.metroDetail!;
          final stationsToMark = <MetroStation>[
            detail.boardingStation,
            if (detail.requiresInterchange && detail.interchangeStation != null)
              detail.interchangeStation!,
            detail.alightingStation,
          ];

          for (final stn in stationsToMark) {
            if (addedStationIds.contains(stn.id)) continue;
            addedStationIds.add(stn.id);

            final bool isInterchange = stn.id == detail.interchangeStation?.id;
            markers.add(
              Marker(
                rotate: true,
                point: stn.toLatLng(),
                width: 36,
                height: 46,
                alignment: Alignment.topCenter,
                child: Tooltip(
                  message: '${isInterchange ? "Interchange" : "Metro"}: ${stn.name}',
                  child: LeafletMarkerPin(
                    category: LeafletPinCategory.custom,
                    pinColor: isInterchange ? const Color(0xFFE65100) : stn.line.color,
                    customIcon: isInterchange
                        ? Icons.transfer_within_a_station_rounded
                        : Icons.subway_rounded,
                    size: 32,
                  ),
                ),
              ),
            );
          }
        }
      }
    }

    return markers;
  }

  void _fitTrailBounds(ActiveCustomTrail trail) {
    if (trail.stops.isEmpty) return;

    final stopPoints = trail.stops.map((s) => LatLng(s.lat, s.lng)).toList();
    final points = <LatLng>[...stopPoints];

    // Only include startPoint if within walking proximity (<= 2500m) of Stop 1
    final firstStop = stopPoints.first;
    final distStartToFirst = haversineMeters(
      trail.startPoint.latitude,
      trail.startPoint.longitude,
      firstStop.latitude,
      firstStop.longitude,
    );
    if (distStartToFirst <= 2500.0) {
      points.add(trail.startPoint);
    }

    // Only include live user position if within walking proximity (<= 2500m) of Stop 1
    if (_effectiveUserLocation != null) {
      final distUserToFirst = haversineMeters(
        _effectiveUserLocation!.latitude,
        _effectiveUserLocation!.longitude,
        firstStop.latitude,
        firstStop.longitude,
      );
      if (distUserToFirst <= 2500.0) {
        points.add(_effectiveUserLocation!);
      }
    }

    final bounds = LatLngBounds.fromPoints(points);
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
        ),
      );
    } catch (_) {}
  }

  Widget _buildMetroToggleChip(bool isDark) {
    return _buildFilterPill(
      isActive: _showMetroStations,
      isDark: isDark,
      icon: Icons.subway_rounded,
      label: 'Metro',
      onTap: () {
        setState(() => _showMetroStations = !_showMetroStations);
        if (_showMetroStations) {
          _setContextualBanner(
            '🚇 Showing 55 Kolkata Metro stations across 5 lines on map',
            icon: Icons.subway_rounded,
            color: PujaColors.metroBlue,
          );
        } else {
          _clearContextualBanner();
        }
      },
    );
  }

  Widget _buildFoodToggleChip(bool isDark) {
    return _buildFilterPill(
      isActive: _showFoodSpots,
      isDark: isDark,
      icon: Icons.restaurant_outlined,
      label: 'Food',
      onTap: () {
        setState(() => _showFoodSpots = !_showFoodSpots);
        if (_showFoodSpots) {
          _setContextualBanner(
            '🍛 Showing famous food spots & sweet shops on map',
            icon: Icons.restaurant_rounded,
            color: const Color(0xFFE65100),
          );
        } else {
          _clearContextualBanner();
        }
      },
    );
  }

  Widget _buildToiletToggleChip(bool isDark) {
    return _buildFilterPill(
      isActive: _showToilets,
      isDark: isDark,
      icon: Icons.wc_outlined,
      label: 'Toilets',
      onTap: () {
        setState(() => _showToilets = !_showToilets);
        if (_showToilets) {
          _setContextualBanner(
            '🚻 Showing ${_uniqueToilets.length} public toilets & Sulabh complexes on map',
            icon: Icons.wc_rounded,
            color: const Color(0xFF00695C),
          );
        } else {
          _clearContextualBanner();
        }
      },
    );
  }

  Widget _buildContextualBanner(bool isDark) {
    if (_contextualMessage == null) return const SizedBox.shrink();
    return AnimatedFadeSlide(
      duration: const Duration(milliseconds: 220),
      offset: const Offset(0, -0.15),
      child: Center(
        child: Container(
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
        ),
      ),
    );
  }

  void _showMapQuickTools(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    final themeService = context.read<ThemeService>();
    final isDarkActive = themeService.isDarkMode;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1B070B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),
                Text(
                  'Map Tools & Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1744).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PujaIcon.durgaEyes(color: const Color(0xFFFF1744), size: 28),
                  ),
                  title: Text(
                    'Nearest Pandal Radar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Locate & highlight closest pandal within 10km',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _findAndHighlightNearestPandal();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PujaColors.festivalGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDarkActive ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: PujaColors.festivalGold,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    isDarkActive ? 'Switch to Light Theme' : 'Switch to Dark Theme',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Adjust display for daytime or night hopping',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    themeService.toggleTheme();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: Color(0xFF2979FF), size: 22),
                  ),
                  title: Text(
                    'App Walkthrough & Guide',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Learn map features, squad tracking, and shortcuts',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    AppTutorialDialog.show(context);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMapLegendSheet(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1B070B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.82,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 16),
                  Text(
                    'Map Markers Legend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Understand pins, badges and landmarks on Kolkata map',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 1. Puja Pandal Pin (Trinayana / Trishul emblem)
                  _buildLegendRow(
                    iconWidget: SizedBox(
                      width: 30,
                      height: 40,
                      child: LeafletMarkerPin.pandal(size: 28),
                    ),
                    title: 'Puja Pandal Pin',
                    subtitle: 'Individual pandal landmark (unclustered browsing mode)',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),

                  // 2. Pandal Cluster
                  _buildLegendRow(
                    iconWidget: const SizedBox(
                      width: 30,
                      height: 40,
                      child: LeafletMarkerPin(
                        category: LeafletPinCategory.cluster,
                        clusterCount: 12,
                        size: 28,
                      ),
                    ),
                    title: 'Pandal Cluster (e.g. 12)',
                    subtitle: 'Multiple pandals in dense vicinity — tap or zoom in to expand',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),

                  // 3. Route Stop Sequence
                  _buildLegendRow(
                    iconWidget: SizedBox(
                      width: 30,
                      height: 40,
                      child: LeafletMarkerPin.pandal(
                        trailIndex: 0,
                        size: 28,
                      ),
                    ),
                    title: 'Route Stop Sequence (e.g. ①)',
                    subtitle: 'Numbered stop when navigating an active curated circuit',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),

                  // 4. Squad Meet-up Landmark (Gold Flag)
                  _buildLegendRow(
                    iconWidget: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD54F),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.flag_rounded, color: Color(0xFF5D4037), size: 18),
                      ),
                    ),
                    title: 'Group Meet-up Landmark',
                    subtitle: 'Designated group rendezvous point or circuit start',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),

                  // 5. Live Group Member
                  _buildLegendRow(
                    iconWidget: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: PujaIcon.dhaki(color: Colors.black87, size: 20)),
                    ),
                    title: 'Live Group Member',
                    subtitle: 'Real-time GPS location of active group companions',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),

                  // 6. Metro Station
                  _buildLegendRow(
                    iconWidget: SizedBox(
                      width: 30,
                      height: 40,
                      child: LeafletMarkerPin.metro(width: 28, height: 38),
                    ),
                    title: 'Metro Station',
                    subtitle: 'Kolkata Metro transit hub for rapid commute between zones',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),

                  // 7. Food Spot / Street Food
                  _buildLegendRow(
                    iconWidget: SizedBox(
                      width: 30,
                      height: 40,
                      child: LeafletMarkerPin.restaurant(width: 28, height: 38),
                    ),
                    title: 'Food Spot / Street Food',
                    subtitle: 'Authentic festival food stops, stalls & iconic sweet shops',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),

                  // 8. Public Toilet / Washroom
                  _buildLegendRow(
                    iconWidget: SizedBox(
                      width: 30,
                      height: 40,
                      child: LeafletMarkerPin.toilet(width: 24, height: 32),
                    ),
                    title: 'Public Toilet / Washroom',
                    subtitle: 'Sulabh complexes & verified sanitation facilities',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendRow({
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        iconWidget,
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
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
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.20),
          color: isDarkActive
              ? const Color(0xFF2A2A2A)
              : Colors.white,
          shape: const StadiumBorder(),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              HapticFeedback.lightImpact();
              themeService.toggleTheme();
            },
            child: Tooltip(
              message:
                  isDarkActive ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
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
                        size: 15,
                        color: isDarkActive
                            ? PujaColors.goldBright
                            : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isDarkActive ? 'Light' : 'Dark',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDarkActive
                            ? PujaColors.goldBright
                            : Colors.black87,
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

  Widget _buildSquadStatusChip(bool isDark, SquadService squadService) {
    final companions = squadService.companionMembers;
    final count = companions.length + 1; // You + companions
    final label = companions.isEmpty ? 'Group' : 'Group ($count)';

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Material(
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
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 6,
            ),
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
      ),
    );
  }

  void _showSquadDetailsSheet(BuildContext context, SquadService squadService, bool isDark) {
    final companions = squadService.companionMembers;
    final squadCode = squadService.squadCode ?? 'SQUAD';
    final userPos = _userPosition;

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
              // Top drag pill
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

              // Header: Squad status with live dot & close button
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
                    'Hopping Group Active',
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

              // Squad Invite Code Card
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
                        _showStatusPill(
                          'Invite code $squadCode copied to clipboard!',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF00E676),
                        );
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

              // Companions or Waiting state
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
                      final dist = userPos != null
                          ? haversineMeters(
                              userPos.latitude,
                              userPos.longitude,
                              member.latitude,
                              member.longitude,
                            )
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
                                _animatedMapMove(
                                  LatLng(member.latitude, member.longitude),
                                  (_mapController.camera.zoom < 15.5 ? 15.5 : _mapController.camera.zoom),
                                );
                                _highlightRouteToMember(member);
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

              // Action button to open full Squad tab
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
                    'Open Hopping Group Hub',
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
                      child: Center(
                        child: PujaIcon.bhogSweets(
                          color: Colors.white,
                          size: 30,
                        ),
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

          return Marker(
            rotate: true,
            point: item.point,
            width: isLarge ? 50 : 44,
            height: isLarge ? 62 : 54,
            alignment: Alignment.topCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                final nextZoom = (camera.zoom + 1.8).clamp(11.0, 16.5);
                onZoomToCluster(item.point, nextZoom);
              },
              child: LeafletMarkerPin(
                category: LeafletPinCategory.cluster,
                clusterCount: count,
                size: isLarge ? 48 : 42,
              ),
            ),
          );
        }

        final p = item.primaryPandal ?? item.pandals.first;
        final isSelected = selectedPandal?.id == p.id;

        int trailIndex = -1;
        bool isVisited = false;
        if (activeTrail != null) {
          trailIndex = activeTrail.stops.indexWhere(
            (s) => s.id == p.id,
          );
          if (trailIndex != -1) {
            isVisited = activeTrail.visitedPandalIds.contains(p.id);
          }
        }

        return Marker(
          rotate: true,
          point: LatLng(p.lat, p.lng),
          width: isSelected ? 48 : 38,
          height: isSelected ? 60 : 48,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelectPandal(p);
            },
            child: LeafletMarkerPin.pandal(
              isSelected: isSelected,
              isVisited: isVisited,
              trailIndex: trailIndex != -1 ? trailIndex : null,
              size: isSelected ? 46 : 36,
              pulseAnimation: isSelected ? pulseController : null,
            ),
          ),
        );
      }).toList(),
      ),
    );
  }
}
