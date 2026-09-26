import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/squad_member.dart';
import '../repositories/squad_firestore_repository.dart';
import '../utils/haversine.dart';
import 'auth_service.dart';
import 'location_service.dart';
import 'squad_neon_api.dart';
import 'websocket_client.dart';

/// Active separation alert when a companion strays outside designated radius
class SquadSeparationAlert {
  const SquadSeparationAlert({
    required this.memberId,
    required this.memberName,
    required this.distanceMeters,
    required this.thresholdMeters,
    this.isCleared = false,
  });

  final String memberId;
  final String memberName;
  final int distanceMeters;
  final int thresholdMeters;
  final bool isCleared;
}

/// Centralized state manager for Durga Puja hopping squads.
/// Grounded in real device GPS coordinates from [LocationService].
/// Backed natively by Google Cloud Firestore (serverless, cloud real-time sync).
/// Supports anonymous guest hoppers, Google upgrade, presence, live GPS updates,
/// and client-side Haversine separation alerts.
class SquadService extends ChangeNotifier {
  SquadService._({this._prefs, SquadFirestoreRepository? repo})
      : _repo = repo ?? SquadFirestoreRepository() {
    _listenToLocationService();
    _listenToAuthService();
    _listenToBattery();
  }

  final SharedPreferences? _prefs;
  final SquadFirestoreRepository _repo;
  static SquadService? _instance;
  static bool enableTestMode = false;
  bool _locationTrackingStarted = false; // Guard against duplicate startLiveTracking calls

  static SquadService get instance {
    _instance ??= SquadService._();
    return _instance!;
  }

  static Future<SquadService> create({SquadFirestoreRepository? repo}) async {
    final prefs = await SharedPreferences.getInstance();
    final service = SquadService._(prefs: prefs, repo: repo);
    await service._loadSavedState();
    _instance = service;
    return service;
  }

  // Active squad metadata
  String? _squadId;
  String? _squadCode;
  String? _squadName;
  String _meetupPointName = 'Designated Meet-up Landmark';
  LatLng _meetupPointCoords = LocationService.defaultKolkataCenter;
  bool _isSharingLocation = true;
  bool _batterySaver = false;
  bool _showSquadOnMap = true;
  int _separationThresholdMeters = 500;
  String? _focusedMemberId;
  String? _lastError;
  SquadSeparationAlert? _activeSeparationAlert;

  final Battery _battery = Battery();
  int _currentBatteryLevel = 85;
  StreamSubscription? _batterySub;
  Timer? _batteryPollTimer;
  DateTime? _lastBatteryPoll;

  final List<SquadMember> _members = [];
  StreamSubscription? _membersSub;
  StreamSubscription? _squadSub;

  // Getters
  SquadFirestoreRepository get repository => _repo;
  WebSocketConnectionState get wsConnectionState =>
      _repo.isAvailable ? WebSocketConnectionState.connected : WebSocketConnectionState.disconnected;
  bool get isWsConnected => _repo.isAvailable;
  String? get squadId => _squadId;
  String? get squadCode => _squadCode;
  String? get squadName => _squadName;
  String get meetupPointName => _meetupPointName;
  LatLng get meetupPointCoords => _meetupPointCoords;
  bool get hasActiveSquad => _squadCode != null;
  bool get isSharingLocation => _isSharingLocation;
  bool get isBatterySaver => _batterySaver;
  bool get showSquadOnMap => _showSquadOnMap;
  int get separationThresholdMeters => _separationThresholdMeters;
  String? get focusedMemberId => _focusedMemberId;
  String? get lastError => _lastError;
  SquadSeparationAlert? get activeSeparationAlert => _activeSeparationAlert;
  List<SquadMember> get members => List.unmodifiable(_members);

  /// Deprecated accessor retained for test backward compatibility
  SquadNeonApi get neonApi => SquadNeonApi();

  void dismissSeparationAlert() {
    _activeSeparationAlert = null;
    notifyListeners();
  }

  /// Companion members that are not the local user.
  /// When a squad is newly created, this is strictly empty.
  List<SquadMember> get companionMembers =>
      _members.where((m) => !m.isUser).toList();

  void _listenToLocationService() {
    LocationService.instance.addListener(() {
      final pos = LocationService.instance.currentPositionSync;
      if (pos != null && hasActiveSquad && _isSharingLocation) {
        updateUserLocation(pos.latitude, pos.longitude);
      }
    });
  }

  void _listenToAuthService() {
    AuthService.instance.addListener(() {
      final user = AuthService.instance.currentUserModel;
      if (user != null && hasActiveSquad) {
        final idx = _members.indexWhere((m) => m.isUser);
        if (idx != -1) {
          final old = _members[idx];
          final displayName = user.displayName ?? 'You';
          if (old.id != user.uid || !old.name.startsWith(displayName)) {
            final updated = old.copyWith(
              id: user.uid,
              name: '$displayName (You)',
              photoUrl: user.photoUrl,
            );
            _members[idx] = updated;
            _syncUserLocationToCloud();
            notifyListeners();
          }
        }
      }
    });
  }

  void _listenToBattery() {
    if (enableTestMode) return;
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return;
    refreshBatteryLevel();

    // Re-check battery every 30 seconds so percentage stays accurate even without plug state changes
    _batteryPollTimer?.cancel();
    _batteryPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshBatteryLevel();
    });

    _batterySub?.cancel();
    try {
      _batterySub = _battery.onBatteryStateChanged.listen(
        (_) => refreshBatteryLevel(),
        onError: (e) => debugPrint('[SquadService] batteryStateChanged note: $e'),
      );
    } catch (e) {
      debugPrint('[SquadService] onBatteryStateChanged listen note: $e');
    }
  }

  /// Explicitly query the real hardware battery level and broadcast if changed
  Future<int> refreshBatteryLevel() async {
    try {
      final lvl = await _battery.batteryLevel;
      _currentBatteryLevel = lvl;
      _lastBatteryPoll = DateTime.now();
      final idx = _members.indexWhere((m) => m.isUser);
      if (idx != -1 && _members[idx].batteryLevel != lvl) {
        _members[idx] = _members[idx].copyWith(batteryLevel: lvl);
        _syncUserLocationToCloud();
        notifyListeners();
      }
      return lvl;
    } catch (e) {
      debugPrint('[SquadService] refreshBatteryLevel note: $e');
      return _currentBatteryLevel;
    }
  }

  Future<AppUser> _ensureUser() async {
    var user = AuthService.instance.currentUserModel;
    if (user == null) {
      debugPrint('[SquadService] No active user session, initializing guest profile...');
      user = await AuthService.instance.signInAsGuest();
    }
    return user;
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final id = prefs.getString('saved_group_id');
      final code = prefs.getString('saved_group_code');
      final name = prefs.getString('saved_group_name');
      final meetup = prefs.getString('saved_meetup_point');
      final thresh = prefs.getInt('saved_separation_threshold');

      if (thresh != null && thresh > 0) {
        _separationThresholdMeters = thresh;
      }

      if (code != null && name != null) {
        _squadId = id;
        _squadCode = code;
        _squadName = name.replaceAll(RegExp(r',\s*s\b'), "'s");
        if (meetup != null) _meetupPointName = meetup;
        _initMembers(isHost: true);
        _listenToCloud();
        _syncUserLocationToCloud();
        if (!_locationTrackingStarted) {
          _locationTrackingStarted = true;
          LocationService.instance.startLiveTracking().catchError((e) {
            debugPrint('[SquadService] startLiveTracking on load error: $e');
            return false;
          });
        }
      }
    } catch (e) {
      debugPrint('[SquadService] _loadSavedState error: $e');
    }
  }

  Future<void> _persistState() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setInt('saved_separation_threshold', _separationThresholdMeters);
      if (_squadCode != null) {
        if (_squadId != null) {
          await prefs.setString('saved_group_id', _squadId!);
        }
        await prefs.setString('saved_group_code', _squadCode!);
        await prefs.setString('saved_group_name', _squadName ?? 'My Squad');
        await prefs.setString('saved_meetup_point', _meetupPointName);
      } else {
        await prefs.remove('saved_group_id');
        await prefs.remove('saved_group_code');
        await prefs.remove('saved_group_name');
        await prefs.remove('saved_meetup_point');
      }
    } catch (e) {
      debugPrint('[SquadService] _persistState error: $e');
    }
  }

  /// Initialize members for the squad.
  /// ONLY the local user is added. ZERO hardcoded dummy companions.
  void _initMembers({required bool isHost, double? userLat, double? userLng}) {
    _members.clear();
    final user = AuthService.instance.currentUserModel;
    final userName = user?.displayName ?? 'You';

    // Derive accurate real GPS coordinates from LocationService
    final currentPos = LocationService.instance.currentPositionSync;
    final lat = userLat ?? currentPos?.latitude ?? LocationService.instance.currentCoordinates.latitude;
    final lng = userLng ?? currentPos?.longitude ?? LocationService.instance.currentCoordinates.longitude;

    // Local user member ONLY
    _members.add(
      SquadMember(
        id: user?.uid ?? 'user_self',
        name: '$userName (You)',
        latitude: lat,
        longitude: lng,
        status: isHost ? 'Squad Host • GPS Live' : 'Joined • GPS Live',
        lastSeen: DateTime.now(),
        photoUrl: user?.photoUrl,
        phoneNumber: user?.phoneNumber,
        isHost: isHost,
        isUser: true,
        batteryLevel: _currentBatteryLevel,
        avatarColorHex: 0xFFD32F2F, // Durga crimson
      ),
    );

    // Refresh real battery in background if not already updated
    _battery.batteryLevel.then((lvl) {
      _currentBatteryLevel = lvl;
      final idx = _members.indexWhere((m) => m.isUser);
      if (idx != -1 && _members[idx].batteryLevel != lvl) {
        _members[idx] = _members[idx].copyWith(batteryLevel: lvl);
        notifyListeners();
      }
    }).catchError((_) {});
  }

  /// Update squad name
  Future<void> updateSquadName(String newName) async {
    final clean = newName.trim().replaceAll(RegExp(r',\s*s\b'), "'s");
    if (clean.isEmpty) return;
    _squadName = clean;
    await _persistState();
    if (_squadId != null) {
      _repo.updateSquadSettings(squadId: _squadId!, name: clean).catchError((e) {
        debugPrint('[SquadService] updateSquadName error: $e');
      });
    }
    notifyListeners();
  }

  /// Set the crowd separation alert threshold in meters
  Future<void> setSeparationThreshold(int meters) async {
    if (meters <= 0) return;
    _separationThresholdMeters = meters;
    await _persistState();
    if (_squadId != null) {
      _repo.updateSquadSettings(
        squadId: _squadId!,
        separationThresholdMeters: meters,
      ).catchError((e) {
        debugPrint('[SquadService] setSeparationThreshold error: $e');
      });
    }
    _checkSeparationDistances();
    notifyListeners();
  }

  static String generateSquadCode([Random? random]) {
    return SquadFirestoreRepository.generateSquadCode();
  }

  /// Create a brand new hopping squad with real device GPS coordinates
  /// and sync directly to Google Cloud Firestore.
  Future<void> createSquad(String name, String meetup, [LatLng? meetupCoords]) async {
    _lastError = null;
    await _ensureUser();

    final cleanName = name.trim().replaceAll(RegExp(r',\s*s\b'), "'s");
    _squadName = cleanName.isEmpty ? 'My Puja Squad' : cleanName;
    _meetupPointName = meetup.trim().isEmpty ? 'Main Entrance Landmark' : meetup.trim();

    final isTest = enableTestMode || (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));

    // Try to get fresh real GPS coordinate before writing to Firestore
    Position? currentPos = LocationService.instance.currentPositionSync;
    if (currentPos == null && !isTest) {
      try {
        currentPos = await LocationService.instance.currentPosition().timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('[SquadService] initial GPS fix timeout/error: $e');
      }
    }

    final realLat = currentPos?.latitude ?? LocationService.instance.currentCoordinates.latitude;
    final realLng = currentPos?.longitude ?? LocationService.instance.currentCoordinates.longitude;
    _meetupPointCoords = meetupCoords ?? LatLng(realLat, realLng);
    if (!isTest) {
      try {
        _currentBatteryLevel = await _battery.batteryLevel.timeout(const Duration(seconds: 2));
      } catch (_) {}
    }

    _initMembers(isHost: true, userLat: realLat, userLng: realLng);
    final hostMember = _members.first;

    // Start live tracking immediately so GPS updates continuously stream
    if (!_locationTrackingStarted && !isTest) {
      _locationTrackingStarted = true;
      LocationService.instance.startLiveTracking().catchError((e) {
        debugPrint('[SquadService] startLiveTracking on create error: $e');
        return false;
      });
    }

    // 1. Create squad in Cloud Firestore
    try {
      final res = await _repo.createSquad(
        name: _squadName!,
        meetupPointName: _meetupPointName,
        meetupLat: _meetupPointCoords.latitude,
        meetupLng: _meetupPointCoords.longitude,
        separationThresholdMeters: _separationThresholdMeters,
        host: hostMember,
      );

      _squadId = res['squadId'] as String?;
      _squadCode = res['squadCode'] as String?;
    } catch (e) {
      debugPrint('[SquadService] Firestore createSquad note: $e');
      _squadCode ??= SquadFirestoreRepository.generateSquadCode();
      _squadId ??= 'sq_${DateTime.now().millisecondsSinceEpoch}';
    }

    await _persistState();
    _listenToCloud();
    _syncUserLocationToCloud();
    notifyListeners();

    // If location fix was still settling, refresh asynchronously
    if (currentPos == null) {
      LocationService.instance.currentPosition().then((pos) {
        if (pos != null && hasActiveSquad) {
          updateUserLocation(pos.latitude, pos.longitude);
          if (meetupCoords == null) {
            _meetupPointCoords = LatLng(pos.latitude, pos.longitude);
            _persistState();
            if (_squadId != null) {
              _repo.updateSquadSettings(
                squadId: _squadId!,
                meetupLat: pos.latitude,
                meetupLng: pos.longitude,
              );
            }
            notifyListeners();
          }
        }
      }).catchError((_) {});
    }
  }

  /// Join an existing squad by invite code from Cloud Firestore
  Future<bool> joinSquad(String code, [LatLng? initialCoords]) async {
    _lastError = null;
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      _lastError = 'Please enter a valid squad code.';
      return false;
    }

    await _ensureUser();

    // 1. Lookup squad in Firestore by 6-character code
    Map<String, dynamic>? squadData;
    try {
      squadData = await _repo.findSquadByCode(cleanCode);
    } catch (e) {
      debugPrint('[SquadService] findSquadByCode error: $e');
    }

    if (squadData == null) {
      // In offline / test mode without Firebase configured, allow joining for testing
      if (!_repo.isAvailable) {
        squadData = {
          'squadId': 'sq_local_$cleanCode',
          'squadCode': cleanCode,
          'name': 'Squad $cleanCode',
          'meetupPointName': 'Designated Meet-up Landmark',
          'meetupLat': LocationService.defaultKolkataCenter.latitude,
          'meetupLng': LocationService.defaultKolkataCenter.longitude,
          'separationThresholdMeters': 500,
        };
      } else {
        _lastError = 'Squad "$cleanCode" not found. Please verify the invite code.';
        notifyListeners();
        return false;
      }
    }

    _squadId = squadData['squadId'] as String?;
    _squadCode = cleanCode;
    _squadName = squadData['name'] as String? ?? 'Squad $cleanCode';
    _meetupPointName = squadData['meetupPointName'] as String? ?? 'Designated Meet-up Landmark';
    final mLat = (squadData['meetupLat'] as num?)?.toDouble() ?? LocationService.defaultKolkataCenter.latitude;
    final mLng = (squadData['meetupLng'] as num?)?.toDouble() ?? LocationService.defaultKolkataCenter.longitude;
    _meetupPointCoords = LatLng(mLat, mLng);
    final sep = (squadData['separationThresholdMeters'] as num?)?.toInt();
    if (sep != null && sep > 0) _separationThresholdMeters = sep;

    Position? currentPos = LocationService.instance.currentPositionSync;
    if (currentPos == null) {
      try {
        currentPos = await LocationService.instance.currentPosition().timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('[SquadService] join GPS fix timeout/error: $e');
      }
    }

    final lat = initialCoords?.latitude ?? currentPos?.latitude ?? LocationService.defaultKolkataCenter.latitude;
    final lng = initialCoords?.longitude ?? currentPos?.longitude ?? LocationService.defaultKolkataCenter.longitude;
    try {
      _currentBatteryLevel = await _battery.batteryLevel.timeout(const Duration(seconds: 2));
    } catch (_) {}

    _initMembers(isHost: false, userLat: lat, userLng: lng);
    final member = _members.first;

    // Start live tracking immediately so GPS updates continuously stream
    if (!_locationTrackingStarted) {
      _locationTrackingStarted = true;
      LocationService.instance.startLiveTracking().catchError((e) {
        debugPrint('[SquadService] startLiveTracking on join error: $e');
        return false;
      });
    }

    if (_squadId != null) {
      await _repo.joinSquad(squadId: _squadId!, member: member);
    }

    await _persistState();
    _listenToCloud();
    _syncUserLocationToCloud();
    notifyListeners();

    if (currentPos == null) {
      LocationService.instance.currentPosition().then((pos) {
        if (pos != null && hasActiveSquad) {
          updateUserLocation(pos.latitude, pos.longitude);
        }
      }).catchError((_) {});
    }
    return true;
  }

  /// Specialized handler for deep link entrypoints
  Future<bool> joinSquadFromDeepLink(String code) async {
    debugPrint('[SquadService] joinSquadFromDeepLink called with code: $code');
    if (_squadCode == code.trim().toUpperCase()) {
      debugPrint('[SquadService] Already in squad $code, skipping join re-execution');
      return true;
    }
    return joinSquad(code);
  }

  /// Add or update a squad member (e.g. from peer invite or external sync)
  void addMember(SquadMember member) {
    final idx = _members.indexWhere((m) => m.id == member.id);
    if (idx != -1) {
      _members[idx] = member;
    } else {
      _members.add(member);
    }
    _checkSeparationDistances();
    notifyListeners();
  }

  /// Remove a member by ID
  void removeMember(String memberId) {
    _members.removeWhere((m) => m.id == memberId && !m.isUser);
    _checkSeparationDistances();
    notifyListeners();
  }

  /// Leave the current squad and clear members
  Future<void> leaveSquad() async {
    final oldSquadId = _squadId;
    final user = AuthService.instance.currentUserModel;

    _membersSub?.cancel();
    _membersSub = null;
    _squadSub?.cancel();
    _squadSub = null;

    if (oldSquadId != null && user != null) {
      _repo.leaveSquad(
        squadId: oldSquadId,
        memberId: user.uid,
        memberName: user.displayName,
      ).catchError((e) {
        debugPrint('[SquadService] leaveSquad error: $e');
      });
    }

    _squadId = null;
    _squadCode = null;
    _squadName = null;
    _focusedMemberId = null;
    _activeSeparationAlert = null;
    _locationTrackingStarted = false; // Reset tracking flag
    _members.clear();
    await _persistState();
    notifyListeners();
  }

  /// Update the current user's real GPS coordinates
  void updateUserLocation(double lat, double lng) {
    if (!_isSharingLocation) return;
    final idx = _members.indexWhere((m) => m.isUser);
    if (idx != -1) {
      _members[idx] = _members[idx].copyWith(
        latitude: lat,
        longitude: lng,
        lastSeen: DateTime.now(),
        shareLocation: true,
        isOnline: true,
      );

      // Throttled battery check on location ping
      if (_lastBatteryPoll == null || DateTime.now().difference(_lastBatteryPoll!).inSeconds >= 20) {
        refreshBatteryLevel();
      }

      _syncUserLocationToCloud();
      _checkSeparationDistances();
      notifyListeners();
    }
  }

  void _syncUserLocationToCloud() {
    if (_squadId == null || !_isSharingLocation) return;
    final user = AuthService.instance.currentUserModel;
    if (user == null) return;
    final idx = _members.indexWhere((m) => m.isUser);
    if (idx == -1) return;
    final self = _members[idx];

    _repo.updateMemberLocation(
      squadId: _squadId!,
      memberId: user.uid,
      lat: self.latitude,
      lng: self.longitude,
      batteryLevel: _currentBatteryLevel,
      isOnline: true,
      shareLocation: true,
      status: self.status,
      name: user.displayName,
      photoUrl: user.photoUrl,
    ).catchError((e) {
      debugPrint('[SquadService] _syncUserLocationToCloud note: $e');
    });
  }

  /// Update the designated meetup landmark
  void setMeetupPoint(String name, [LatLng? coords]) {
    _meetupPointName = name.trim();
    if (coords != null) {
      _meetupPointCoords = coords;
    }
    _persistState();

    if (_squadId != null) {
      _repo.updateSquadSettings(
        squadId: _squadId!,
        meetupPointName: _meetupPointName,
        meetupLat: _meetupPointCoords.latitude,
        meetupLng: _meetupPointCoords.longitude,
      ).catchError((e) {
        debugPrint('[SquadService] setMeetupPoint error: $e');
      });
    }

    notifyListeners();
  }

  /// Toggle user's live location sharing
  void toggleLocationSharing(bool val) {
    _isSharingLocation = val;
    final idx = _members.indexWhere((m) => m.isUser);
    if (idx != -1) {
      _members[idx] = _members[idx].copyWith(shareLocation: val);
    }
    if (_squadId != null) {
      final user = AuthService.instance.currentUserModel;
      if (user != null) {
        _repo.updateMemberLocation(
          squadId: _squadId!,
          memberId: user.uid,
          lat: idx != -1 ? _members[idx].latitude : 0.0,
          lng: idx != -1 ? _members[idx].longitude : 0.0,
          shareLocation: val,
        ).catchError((e) {
          debugPrint('[SquadService] toggleLocationSharing error: $e');
        });
      }
    }
    notifyListeners();
  }

  /// Toggle battery saver mode
  void toggleBatterySaver(bool val) {
    _batterySaver = val;
    notifyListeners();
  }

  /// Toggle squad markers visibility on the map
  void toggleSquadOnMap(bool show) {
    _showSquadOnMap = show;
    notifyListeners();
  }

  /// Focus map on a specific squad member
  void focusMember(String? memberId) {
    _focusedMemberId = memberId;
    notifyListeners();
  }

  void clearFocus() {
    _focusedMemberId = null;
  }

  SquadMember? getMemberById(String id) {
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Client-side distance calculation across companions to evaluate separation alerts
  void _checkSeparationDistances() {
    final userIdx = _members.indexWhere((m) => m.isUser);
    if (userIdx == -1 || !_isSharingLocation) return;
    final user = _members[userIdx];

    SquadSeparationAlert? newAlert;

    for (final companion in companionMembers) {
      if (!companion.shareLocation || !companion.isOnline) continue;
      final dist = haversineMeters(
        user.latitude,
        user.longitude,
        companion.latitude,
        companion.longitude,
      ).round();

      if (dist > _separationThresholdMeters) {
        newAlert = SquadSeparationAlert(
          memberId: companion.id,
          memberName: companion.name.replaceAll(' (You)', ''),
          distanceMeters: dist,
          thresholdMeters: _separationThresholdMeters,
          isCleared: false,
        );
        break;
      }
    }

    _activeSeparationAlert = newAlert;
  }

  @visibleForTesting
  void addCompanionForTesting(SquadMember companion) {
    _members.removeWhere((m) => m.id == companion.id);
    _members.add(companion.copyWith(isUser: false));
    _checkSeparationDistances();
    notifyListeners();
  }

  @visibleForTesting
  void resetForTesting() {
    enableTestMode = true;
    _batteryPollTimer?.cancel();
    _batterySub?.cancel();
    _membersSub?.cancel();
    _squadSub?.cancel();
    _squadId = null;
    _squadCode = null;
    _squadName = null;
    _activeSeparationAlert = null;
    _members.clear();
    _separationThresholdMeters = 500;
  }

  @visibleForTesting
  void cancelTimersForTesting() {
    _batteryPollTimer?.cancel();
    _batterySub?.cancel();
  }

  // --- Cloud Realtime Sync via Cloud Firestore ---

  void _listenToCloud() {
    _membersSub?.cancel();
    _squadSub?.cancel();
    if (_squadId == null) return;

    final currentUserId = AuthService.instance.currentUserModel?.uid ?? 'user_self';

    // 1. Listen to real-time member roster and live locations
    _membersSub = _repo.streamMembers(_squadId!, currentUserId: currentUserId).listen(
      (cloudMembers) {
        bool changed = false;
        final currentCompanions = cloudMembers.where((m) => !m.isUser).toList();

        // Update or insert companion members
        for (final companion in currentCompanions) {
          final idx = _members.indexWhere((m) => m.id == companion.id);
          if (idx != -1) {
            final existing = _members[idx];
            if (existing.latitude != companion.latitude ||
                existing.longitude != companion.longitude ||
                existing.name != companion.name ||
                existing.status != companion.status ||
                existing.batteryLevel != companion.batteryLevel ||
                existing.photoUrl != companion.photoUrl ||
                existing.isOnline != companion.isOnline ||
                existing.shareLocation != companion.shareLocation ||
                existing.lastSeen != companion.lastSeen) {
              _members[idx] = companion;
              changed = true;
            }
          } else {
            _members.add(companion);
            changed = true;
          }
        }

        // Remove companions that left
        final activeCompanionIds = currentCompanions.map((c) => c.id).toSet();
        final before = _members.length;
        _members.removeWhere((m) => !m.isUser && !activeCompanionIds.contains(m.id));
        if (_members.length != before) changed = true;

        if (changed) {
          _checkSeparationDistances();
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint('[SquadService] streamMembers error: $err');
      },
    );

    // 2. Listen to real-time squad metadata (Meetup, name, radius)
    _squadSub = _repo.streamSquad(_squadId!).listen(
      (squadData) {
        if (squadData == null) return;
        bool changed = false;

        final newName = squadData['name'] as String?;
        if (newName != null && newName.isNotEmpty && newName != _squadName) {
          _squadName = newName;
          changed = true;
        }

        final newMeetup = squadData['meetupPointName'] as String?;
        if (newMeetup != null && newMeetup.isNotEmpty && newMeetup != _meetupPointName) {
          _meetupPointName = newMeetup;
          changed = true;
        }

        final mLat = (squadData['meetupLat'] as num?)?.toDouble();
        final mLng = (squadData['meetupLng'] as num?)?.toDouble();
        if (mLat != null && mLng != null) {
          final newCoords = LatLng(mLat, mLng);
          if ((newCoords.latitude - _meetupPointCoords.latitude).abs() > 0.00001 ||
              (newCoords.longitude - _meetupPointCoords.longitude).abs() > 0.00001) {
            _meetupPointCoords = newCoords;
            changed = true;
          }
        }

        final sep = (squadData['separationThresholdMeters'] as num?)?.toInt();
        if (sep != null && sep > 0 && sep != _separationThresholdMeters) {
          _separationThresholdMeters = sep;
          changed = true;
        }

        if (changed) {
          _persistState();
          _checkSeparationDistances();
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint('[SquadService] streamSquad error: $err');
      },
    );
  }

  @override
  void dispose() {
    _batteryPollTimer?.cancel();
    _batterySub?.cancel();
    _membersSub?.cancel();
    _squadSub?.cancel();
    super.dispose();
  }
}
