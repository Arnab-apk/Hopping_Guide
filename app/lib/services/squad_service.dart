import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/pandal.dart';
import '../models/squad_member.dart';
import '../models/squad_pandal_stop.dart';
import '../models/squad_group.dart';
import '../repositories/squad_firestore_repository.dart';
import '../utils/haversine.dart';
import 'auth_service.dart';
import 'custom_hopping_trail_service.dart';
import 'location_service.dart';
import 'queue_wait_service.dart';
import 'squad_neon_api.dart';
import 'trail_optimizer.dart';
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

/// Whether the current squad snapshot has been confirmed by Firestore's server.
enum SquadSyncState { unavailable, connecting, live, cached, error }

/// Centralized state manager for Durga Puja hopping squads.
/// Grounded in real device GPS coordinates from [LocationService].
/// Backed natively by Google Cloud Firestore (serverless, cloud real-time sync).
/// Supports anonymous guest hoppers, Google upgrade, presence, live GPS updates,
/// and client-side Haversine separation alerts.
class SquadService extends ChangeNotifier with WidgetsBindingObserver {
  SquadService._({this._prefs, SquadFirestoreRepository? repo})
      : _repo = repo ?? SquadFirestoreRepository() {
    _listenToLocationService();
    _listenToAuthService();
    _listenToBattery();
    WidgetsBinding.instance.addObserver(this);
  }

  final SharedPreferences? _prefs;
  final SquadFirestoreRepository _repo;
  static SquadService? _instance;
  static bool enableTestMode = false;
  bool _locationTrackingStarted = false; // Guard against duplicate startLiveTracking calls
  Position? _lastObservedPosition;
  DateTime? _lastCloudLocationAt;
  double? _lastCloudLat;
  double? _lastCloudLng;
  SquadSyncState _syncState = SquadSyncState.unavailable;

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
  StreamSubscription? _groupsSub;
  String? _groupsOwner;
  final Map<String, Map<String, dynamic>> _groups = {};
  bool _groupOperationPending = false;
  Future<void>? _saveQueue;

  Future<void> _savePreferences(Map<String, Object?> values) {
    Future<void> write() async {
      try {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        for (final entry in values.entries) {
          final value = entry.value;
          if (value == null) { await prefs.remove(entry.key); }
          else if (value is String) { await prefs.setString(entry.key, value); }
          else if (value is bool) { await prefs.setBool(entry.key, value); }
          else if (value is int) { await prefs.setInt(entry.key, value); }
        }
      } catch (error) { debugPrint('[SquadService] preference save error: $error'); }
    }
    final pending = _saveQueue;
    return _saveQueue = pending == null ? write() : pending.then((_) => write());
  }
  bool get isGroupOperationPending => _groupOperationPending;
  List<SquadGroup> get groups => List.unmodifiable(_groups.entries.map((entry) =>
    SquadGroup(id: entry.key, code: entry.value['squadCode'] as String,
      name: entry.value['name'] as String? ?? 'Hopping Group',
      isHost: entry.value['hostId'] == AuthService.instance.currentUserModel?.uid)));

  Map<String, dynamic> _savedGroupData(Map<String, dynamic> data) => {
    for (final key in ['squadId', 'squadCode', 'name', 'hostId',
      'meetupPointName', 'meetupLat', 'meetupLng', 'separationThresholdMeters',
      'chosenPandals', 'isHoppingActive', 'activeStopIndex', 'planRevision'])
      if (data[key] != null) key: data[key],
  };

  void _rememberActiveGroup() {
    if (_squadId == null || _squadCode == null) return;
    _groups[_squadId!] = {
      'squadId': _squadId, 'squadCode': _squadCode, 'name': _squadName,
      'hostId': _members.where((m) => m.isHost).firstOrNull?.id,
      'meetupPointName': _meetupPointName, 'meetupLat': _meetupPointCoords.latitude,
      'meetupLng': _meetupPointCoords.longitude,
      'separationThresholdMeters': _separationThresholdMeters,
      'chosenPandals': _chosenPandals.map((s) => s.toJson()).toList(),
      'isHoppingActive': _isHoppingActive, 'activeStopIndex': _activeHoppingStopIndex,
      'planRevision': _planRevision, 'shareLocation': _isSharingLocation,
    };
  }

  Future<void> _loadMemberships() async {
    final uid = AuthService.instance.currentUserModel?.uid;
    _groupsSub?.cancel();
    _groupsOwner = uid;
    _groups.clear();
    if (uid == null) { notifyListeners(); return; }
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (_groupsOwner != uid) return;
    final saved = prefs.getString('saved_groups_$uid');
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final data = Map<String, dynamic>.from(entry.value as Map);
          if (data['squadCode'] is String) _groups[entry.key] = data;
        }
      } catch (_) { /* Old or incomplete local cache; cloud remains authoritative. */ }
    }
    _rememberActiveGroup();
    _groupsSub = _repo.streamUserSquads(uid).listen((snapshot) {
      if (_groupsOwner != uid) return;
      final items = snapshot.groups;
      final ids = <String>{};
      for (final data in items) {
        final id = data['squadId'] as String;
        ids.add(id);
        _groups[id] = {...?_groups[id], ..._savedGroupData(data)};
      }
      // Only authoritative snapshots may remove cached memberships.
      if (!snapshot.fromCache) {
        _groups.removeWhere((id, _) => !ids.contains(id));
        if (_squadId != null && !ids.contains(_squadId) && !_groupOperationPending) {
          _deactivateGroup();
          _lastError = 'You are no longer a member of the selected group.';
          _persistState();
        }
      }
      _persistMemberships();
      notifyListeners();
    }, onError: (Object error) {
      debugPrint('[SquadService] membership list error: $error');
    });
    notifyListeners();
  }

  Future<void> _persistMemberships() {
    final uid = _groupsOwner ?? AuthService.instance.currentUserModel?.uid;
    if (uid == null) return Future.value();
    return _savePreferences({'saved_groups_$uid': jsonEncode(_groups)});
  }

  void _deactivateGroup() {
    if (_isHoppingActive && CustomHoppingTrailService.instance.hasActiveTrail) {
      CustomHoppingTrailService.instance.endTrail();
    }
    _membersSub?.cancel(); _membersSub = null;
    _squadSub?.cancel(); _squadSub = null;
    _squadId = null; _squadCode = null; _squadName = null;
    _members.clear(); _chosenPandals.clear();
    _isHoppingActive = false; _activeHoppingStopIndex = 0; _planRevision = 0;
    _focusedMemberId = null; _activeSeparationAlert = null;
    _syncState = SquadSyncState.unavailable;
    _lastCloudLocationAt = null; _lastCloudLat = null; _lastCloudLng = null;
    _lastObservedPosition = null;
    if (_locationTrackingStarted) LocationService.instance.stopLiveTracking(callbackKey: this);
    _locationTrackingStarted = false;
  }

  Future<void> _pauseActiveGroup() async {
    _rememberActiveGroup();
    if (_squadId != null && _repo.isAvailable) {
      final user = await _ensureUser();
      await _repo.pauseMemberSharing(_squadId!, user.uid);
    }
    _deactivateGroup();
  }

  void _activateGroup(Map<String, dynamic> data) {
    _squadId = data['squadId'] as String;
    _squadCode = data['squadCode'] as String;
    _squadName = data['name'] as String? ?? 'Hopping Group';
    _meetupPointName = data['meetupPointName'] as String? ?? 'Meet-up Landmark';
    _meetupPointCoords = LatLng((data['meetupLat'] as num?)?.toDouble() ?? 22.5697,
      (data['meetupLng'] as num?)?.toDouble() ?? 88.3533);
    _separationThresholdMeters = (data['separationThresholdMeters'] as num?)?.toInt() ?? 500;
    _isSharingLocation = data['shareLocation'] as bool? ?? true;
    _initMembers(isHost: data['hostId'] == AuthService.instance.currentUserModel?.uid);
    _applyPlanSnapshot(data);
    _listenToCloud(); _startSquadLocationTracking();
    _syncUserLocationToCloud(force: true);
  }

  Future<bool> switchGroup(String id) async {
    if (id == _squadId) return true;
    if (_groupOperationPending || _isPlanMutationPending || !_groups.containsKey(id)) return false;
    _groupOperationPending = true; _lastError = null; notifyListeners();
    try {
      final user = await _ensureUser();
      final data = _repo.isAvailable
        ? await _repo.getSquadForMember(id, user.uid) : _groups[id];
      if (data == null) {
        _groups.remove(id); await _persistMemberships();
        throw StateError('You are no longer a member of this group.');
      }
      final target = {...?_groups[id], ..._savedGroupData(data)};
      await _pauseActiveGroup();
      _activateGroup(target);
      await _persistState();
      return true;
    } catch (error) {
      _lastError = 'Could not switch groups. Check your connection and membership.';
      return false;
    } finally { _groupOperationPending = false; notifyListeners(); }
  }

  Future<bool> leaveGroup(String id) async {
    if (id == _squadId) return leaveSquad();
    if (_groupOperationPending || !_groups.containsKey(id)) return false;
    _groupOperationPending = true; _lastError = null; notifyListeners();
    try {
      final user = await _ensureUser();
      await _repo.leaveSquad(squadId: id, memberId: user.uid, memberName: user.displayName);
      _groups.remove(id); await _persistMemberships();
      return true;
    } catch (_) { _lastError = 'Could not leave the group. Please try again.'; return false; }
    finally { _groupOperationPending = false; notifyListeners(); }
  }

  // Getters
  SquadFirestoreRepository get repository => _repo;
  // Kept for existing callers; Firestore is not a WebSocket connection.
  WebSocketConnectionState get wsConnectionState =>
      _syncState == SquadSyncState.live ? WebSocketConnectionState.connected : WebSocketConnectionState.disconnected;
  bool get isWsConnected => _syncState == SquadSyncState.live;
  SquadSyncState get syncState => _syncState;
  String? get squadId => _squadId;
  String? get squadCode => _squadCode;
  String? get squadName => _squadName;
  String get meetupPointName => _meetupPointName;
  LatLng get meetupPointCoords => _meetupPointCoords;
  bool get hasActiveSquad => _squadCode != null;
  bool get isSharingLocation => _isSharingLocation;
  bool get isLocationTracking => _locationTrackingStarted &&
      LocationService.instance.isLiveTracking && !LocationService.instance.isPaused;
  bool get isBatterySaver => _batterySaver;
  bool get showSquadOnMap => _showSquadOnMap;
  int get separationThresholdMeters => _separationThresholdMeters;
  String? get focusedMemberId => _focusedMemberId;
  String? get lastError => _lastError;
  SquadSeparationAlert? get activeSeparationAlert => _activeSeparationAlert;
  List<SquadMember> get members => List.unmodifiable(_members);

  // --- Collaborative Hopping Plan & Live Hopping ---
  List<SquadPandalStop> _chosenPandals = [];
  bool _isHoppingActive = false;
  int _activeHoppingStopIndex = 0;
  int _planRevision = 0;
  bool _isPlanMutationPending = false;

  List<SquadPandalStop> get chosenPandals => List.unmodifiable(_chosenPandals);
  bool get isHoppingActive => _isHoppingActive;
  int get activeHoppingStopIndex => _activeHoppingStopIndex;
  bool get isPlanMutationPending => _isPlanMutationPending;
  int get visitedPandalsCount => _chosenPandals.where((p) => p.isVisited).length;
  SquadPandalStop? get currentHoppingTarget =>
      (_isHoppingActive && _chosenPandals.isNotEmpty && _activeHoppingStopIndex < _chosenPandals.length)
          ? _chosenPandals[_activeHoppingStopIndex]
          : null;
  double get hoppingProgress =>
      _chosenPandals.isEmpty ? 0.0 : (visitedPandalsCount / _chosenPandals.length);

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

  /// Current user's ID for queue reports and other features
  String? get currentUserId {
    final user = AuthService.instance.currentUserModel;
    return user?.uid;
  }

  /// Broadcast a queue report to squad members via Firestore
  Future<void> broadcastQueueReport(QueueReport report) async {
    if (_squadId == null) return;
    try {
      await _repo.addQueueReport(squadId: _squadId!, report: report);
    } catch (e) {
      debugPrint('[SquadService] broadcastQueueReport error: $e');
    }
  }

  void _listenToLocationService() {
    LocationService.instance.addListener(_onLocationServiceChange);
  }

  void _startSquadLocationTracking() {
    if (_locationTrackingStarted) return;
    _locationTrackingStarted = true;
    LocationService.instance.startLiveTracking(callbackKey: this).then((started) {
      if (!started) {
        _locationTrackingStarted = false;
        notifyListeners();
      }
    }).catchError((e) {
      _locationTrackingStarted = false;
      debugPrint('[SquadService] location tracking error: $e');
      notifyListeners();
    });
  }

  void _listenToAuthService() {
    AuthService.instance.addListener(_onAuthServiceChange);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      LocationService.instance.pauseLiveTracking();
    } else if (state == AppLifecycleState.resumed) {
      LocationService.instance.resumeLiveTracking();
      if (hasActiveSquad && !_locationTrackingStarted) _startSquadLocationTracking();
    }
  }

  void _onLocationServiceChange() {
    final pos = LocationService.instance.currentPositionSync;
    if (pos != null && hasActiveSquad && _isSharingLocation) {
      if (identical(pos, _lastObservedPosition)) return;
      _lastObservedPosition = pos;
      updateUserLocation(pos.latitude, pos.longitude);
    }
  }

  void _onAuthServiceChange() {
    final user = AuthService.instance.currentUserModel;
    if (user?.uid != _groupsOwner) {
      if (_groupsOwner != null) _deactivateGroup();
      unawaited(_loadMemberships());
    }
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
          _syncUserLocationToCloud(force: true);
          notifyListeners();
        }
      }
    }
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
    if (enableTestMode || (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'))) {
      return _currentBatteryLevel;
    }
    try {
      final lvl = await _battery.batteryLevel;
      _currentBatteryLevel = lvl;
      _lastBatteryPoll = DateTime.now();
      final idx = _members.indexWhere((m) => m.isUser);
      if (idx != -1 && _members[idx].batteryLevel != lvl) {
        _members[idx] = _members[idx].copyWith(batteryLevel: lvl);
        _syncUserLocationToCloud(force: true);
        notifyListeners();
      }
      return lvl;
    } catch (e) {
      debugPrint('[SquadService] refreshBatteryLevel note: $e');
      return _currentBatteryLevel;
    }
  }

  Future<AppUser> _ensureUser() async {
    if (_repo.isAvailable && !enableTestMode &&
        (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST'))) {
      return AuthService.instance.ensureCloudUser();
    }
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
      final owner = prefs.getString('saved_group_owner');
      if (owner != null && owner != AuthService.instance.currentUserModel?.uid) {
        await _loadMemberships();
        return;
      }
      final id = prefs.getString('saved_group_id');
      final code = prefs.getString('saved_group_code');
      final name = prefs.getString('saved_group_name');
      final meetup = prefs.getString('saved_meetup_point');
      final thresh = prefs.getInt('saved_separation_threshold');
      _isSharingLocation = prefs.getBool('saved_group_share_location') ?? true;

      if (thresh != null && thresh > 0) {
        _separationThresholdMeters = thresh;
      }

      final pandalsJson = prefs.getString('saved_squad_pandals');
      if (pandalsJson != null && pandalsJson.isNotEmpty) {
        try {
          final list = jsonDecode(pandalsJson) as List<dynamic>;
          _chosenPandals = list
              .map((e) => SquadPandalStop.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
      _isHoppingActive = prefs.getBool('saved_squad_is_hopping') ?? false;
      _activeHoppingStopIndex = prefs.getInt('saved_squad_hopping_stop') ?? 0;

      if (code != null && name != null) {
        _squadId = id;
        _squadCode = code;
        _squadName = name.replaceAll(RegExp(r',\s*s\b'), "'s");
        if (meetup != null) _meetupPointName = meetup;
        _initMembers(isHost: prefs.getString('saved_group_host_id') == AuthService.instance.currentUserModel?.uid);
        _listenToCloud();
        _syncUserLocationToCloud();
        _startSquadLocationTracking();
      }
    } catch (e) {
      debugPrint('[SquadService] _loadSavedState error: $e');
    }
    await _loadMemberships();
  }

  Future<void> _persistState() {
    // Snapshot before awaiting storage: sign-out or switching can change fields.
    _rememberActiveGroup();
    final owner = AuthService.instance.currentUserModel?.uid;
    final active = _squadCode != null;
    return _savePreferences({
      'saved_group_owner': owner,
      if (owner != null) 'saved_groups_$owner': jsonEncode(_groups),
      'saved_separation_threshold': _separationThresholdMeters,
      'saved_group_id': _squadId,
      'saved_group_code': _squadCode,
      'saved_group_name': _squadName,
      'saved_group_host_id': active ? _members.where((m) => m.isHost).firstOrNull?.id : null,
      'saved_group_share_location': active ? _isSharingLocation : null,
      'saved_meetup_point': active ? _meetupPointName : null,
      'saved_squad_pandals': active ? jsonEncode(_chosenPandals.map((e) => e.toJson()).toList()) : null,
      'saved_squad_is_hopping': active ? _isHoppingActive : null,
      'saved_squad_hopping_stop': active ? _activeHoppingStopIndex : null,
    });
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
        shareLocation: _isSharingLocation,
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
    await _runGroupChange(() async { await _createSquad(name, meetup, meetupCoords); });
  }

  Future<bool> _runGroupChange(Future<void> Function() action) async {
    if (_groupOperationPending || _isPlanMutationPending) return false;
    _groupOperationPending = true;
    final previousId = _squadId;
    _lastError = null;
    notifyListeners();
    try {
      await _ensureUser();
      if (_groupsOwner != AuthService.instance.currentUserModel?.uid) await _loadMemberships();
      await _pauseActiveGroup();
      await action();
      if (!hasActiveSquad) {
        if (previousId != null && _groups[previousId] != null) _activateGroup(_groups[previousId]!);
        await _persistState();
        return false;
      }
      await _persistState();
      return true;
    } catch (error) {
      if (_squadId == null && previousId != null && _groups[previousId] != null) {
        _activateGroup(_groups[previousId]!);
      }
      _lastError ??= 'Could not update your groups. Check your connection and try again.';
      await _persistState();
      return false;
    } finally { _groupOperationPending = false; notifyListeners(); }
  }

  Future<void> _createSquad(String name, String meetup, [LatLng? meetupCoords]) async {
    _lastError = null;
    try {
      await _ensureUser();
    } catch (e) {
      _lastError = 'Could not sign in for group sync. Check your connection and try again.';
      notifyListeners();
      return;
    }

    final cleanName = name.trim().replaceAll(RegExp(r',\s*s\b'), "'s");
    _squadName = cleanName.isEmpty ? 'My Puja Squad' : cleanName;
    _meetupPointName = meetup.trim().isEmpty ? 'Main Entrance Landmark' : meetup.trim();

    final isTest = enableTestMode || (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
    if (!_repo.isAvailable && !isTest) {
      _lastError = 'Group sync is unavailable. Firebase must be configured before inviting friends.';
      notifyListeners();
      return;
    }

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
      _startSquadLocationTracking();
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
      debugPrint('[SquadService] Firestore createSquad error: $e');
      _lastError = 'Could not create the group online. Check your connection and try again.';
      _squadId = null;
      _squadCode = null;
      _squadName = null;
      _members.clear();
      if (_locationTrackingStarted) {
        LocationService.instance.stopLiveTracking(callbackKey: this);
        _locationTrackingStarted = false;
      }
      notifyListeners();
      return;
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
    final cleanCode = code.trim().toUpperCase();
    if (_squadCode == cleanCode) return true;
    for (final group in groups) {
      if (group.code == cleanCode) return switchGroup(group.id);
    }
    return _runGroupChange(() async { await _joinSquad(cleanCode, initialCoords); });
  }

  Future<bool> _joinSquad(String code, [LatLng? initialCoords]) async {
    _lastError = null;
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      _lastError = 'Please enter a valid squad code.';
      return false;
    }
    if (hasActiveSquad) {
      if (_squadCode == cleanCode) return true;
      _lastError = 'Leave your current group before joining another one.';
      notifyListeners();
      return false;
    }

    try {
      await _ensureUser();
    } catch (e) {
      _lastError = 'Could not sign in for group sync. Check your connection and try again.';
      notifyListeners();
      return false;
    }
    final isTest = enableTestMode || (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
    if (!_repo.isAvailable && !isTest) {
      _lastError = 'Group sync is unavailable. Firebase must be configured before joining friends.';
      notifyListeners();
      return false;
    }

    // 1. Lookup squad in Firestore by 6-character code
    Map<String, dynamic>? squadData;
    try {
      squadData = await _repo.findSquadByCode(cleanCode);
    } catch (e) {
      debugPrint('[SquadService] findSquadByCode error: $e');
      _lastError = 'Could not look up that group online. Check your connection and try again.';
      notifyListeners();
      return false;
    }

    if (squadData == null) {
      // In offline / test mode without Firebase configured, allow joining for testing
      if (!_repo.isAvailable && isTest) {
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
    _startSquadLocationTracking();

    if (_squadId != null) {
      final joined = await _repo.joinSquad(squadId: _squadId!, member: member);
      if (!joined) {
        _lastError = 'Could not join the group online. Check your connection and try again.';
        _squadId = null;
        _squadCode = null;
        _squadName = null;
        _members.clear();
        if (_locationTrackingStarted) {
          LocationService.instance.stopLiveTracking(callbackKey: this);
          _locationTrackingStarted = false;
        }
        notifyListeners();
        return false;
      }
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
  Future<bool> leaveSquad() async {
    if (_groupOperationPending || _isPlanMutationPending) return false;
    _groupOperationPending = true;
    notifyListeners();
    try { return await _leaveSquad(); }
    finally { _groupOperationPending = false; notifyListeners(); }
  }

  Future<bool> _leaveSquad() async {
    _lastError = null;
    final oldSquadId = _squadId;
    if (oldSquadId != null && _repo.isAvailable) {
      try {
        final user = await _ensureUser();
        await _repo.leaveSquad(
          squadId: oldSquadId,
          memberId: user.uid,
          memberName: user.displayName,
        );
      } catch (e) {
        debugPrint('[SquadService] leaveSquad error: $e');
        _lastError = switch (e) {
          FirebaseException(code: 'permission-denied') =>
            'The server denied permission to leave this group. Please try signing in again.',
          FirebaseException(code: 'unauthenticated') =>
            'Your sign-in session has expired. Please sign in again to leave the group.',
          FirebaseException(code: 'unavailable' || 'deadline-exceeded') =>
            'Could not reach the group server. Check your connection and try again.',
          _ => 'Could not leave the group. Please try again.',
        };
        notifyListeners();
        return false;
      }
    }

    _membersSub?.cancel();
    _membersSub = null;
    _squadSub?.cancel();
    _squadSub = null;

    if (oldSquadId != null) _groups.remove(oldSquadId);
    _squadId = null;
    _squadCode = null;
    _squadName = null;
    _focusedMemberId = null;
    _activeSeparationAlert = null;
    _chosenPandals.clear();
    _isHoppingActive = false;
    _activeHoppingStopIndex = 0;
    _planRevision = 0;
    _isPlanMutationPending = false;
    _locationTrackingStarted = false; // Reset tracking flag
    _syncState = SquadSyncState.unavailable;
    _lastCloudLocationAt = null;
    _lastCloudLat = null;
    _lastCloudLng = null;
    _lastObservedPosition = null;
    LocationService.instance.stopLiveTracking(callbackKey: this);
    _members.clear();
    await _persistState();
    notifyListeners();
    return true;
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

  void _syncUserLocationToCloud({bool force = false}) {
    if (_squadId == null || !_isSharingLocation) return;
    final user = AuthService.instance.currentUserModel;
    if (user == null) return;
    final idx = _members.indexWhere((m) => m.isUser);
    if (idx == -1) return;
    final self = _members[idx];
    final now = DateTime.now();
    if (!force && _lastCloudLocationAt != null && _lastCloudLat != null && _lastCloudLng != null &&
        now.difference(_lastCloudLocationAt!) < const Duration(seconds: 15) &&
        haversineMeters(_lastCloudLat!, _lastCloudLng!, self.latitude, self.longitude) < 10) {
      return;
    }
    _lastCloudLocationAt = now;
    _lastCloudLat = self.latitude;
    _lastCloudLng = self.longitude;

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
    _persistState();
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
    if (val) _syncUserLocationToCloud(force: true);
    notifyListeners();
  }

  void retryLocationTracking() {
    if (hasActiveSquad && _isSharingLocation) _startSquadLocationTracking();
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
      if (companion.markerState != MemberMarkerState.fresh &&
          companion.markerState != MemberMarkerState.stale) {
        continue;
      }
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
    _saveQueue = null;
    _groupsSub?.cancel(); _groupsSub = null;
    _groups.clear(); _groupsOwner = null; _groupOperationPending = false;
    enableTestMode = true;
    _batteryPollTimer?.cancel();
    _batterySub?.cancel();
    _membersSub?.cancel();
    _squadSub?.cancel();
    _squadId = null;
    _squadCode = null;
    _squadName = null;
    _activeSeparationAlert = null;
    _chosenPandals.clear();
    _isHoppingActive = false;
    _activeHoppingStopIndex = 0;
    _planRevision = 0;
    _isPlanMutationPending = false;
    _members.clear();
    _separationThresholdMeters = 500;
    _lastCloudLocationAt = null;
    _lastCloudLat = null;
    _lastCloudLng = null;
    _lastObservedPosition = null;
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
    if (_squadId == null) {
      _syncState = SquadSyncState.unavailable;
      return;
    }
    _syncState = _repo.isAvailable ? SquadSyncState.connecting : SquadSyncState.unavailable;

    final currentUserId = AuthService.instance.currentUserModel?.uid ?? 'user_self';
    final listeningGroupId = _squadId;

    // 1. Listen to real-time member roster and live locations
    _membersSub = _repo.streamMembers(_squadId!, currentUserId: currentUserId).listen(
      (cloudMembers) {
        if (_squadId != listeningGroupId) return;
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
        if (_squadId != listeningGroupId) return;
        if (squadData == null) return;
        if (squadData['_exists'] == false) {
          if (squadData['_fromCache'] == true) return;
          _membersSub?.cancel();
          _groups.remove(listeningGroupId);
          _squadId = null;
          _squadCode = null;
          _squadName = null;
          _members.clear();
          _chosenPandals.clear();
          _isHoppingActive = false;
          _activeHoppingStopIndex = 0;
          _planRevision = 0;
          _syncState = SquadSyncState.error;
          _lastError = 'This group is no longer available.';
          if (_locationTrackingStarted) {
            LocationService.instance.stopLiveTracking(callbackKey: this);
            _locationTrackingStarted = false;
          }
          _persistState();
          notifyListeners();
          return;
        }
        bool changed = false;

        final nextSyncState = squadData['_fromCache'] == true
            ? SquadSyncState.cached
            : SquadSyncState.live;
        if (nextSyncState != _syncState) {
          _syncState = nextSyncState;
          changed = true;
        }

        final newName = squadData['name'] as String?;
        final selfIndex = _members.indexWhere((member) => member.isUser);
        if (selfIndex >= 0 && squadData['hostId'] is String) {
          final isHost = squadData['hostId'] == currentUserId;
          if (_members[selfIndex].isHost != isHost) {
            _members[selfIndex] = _members[selfIndex].copyWith(isHost: isHost);
            changed = true;
          }
        }
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

        if (_applyPlanSnapshot(squadData)) changed = true;

        if (changed) {
          _persistState();
          _checkSeparationDistances();
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint('[SquadService] streamSquad error: $err');
        _syncState = SquadSyncState.error;
        notifyListeners();
      },
    );
  }

  // --- Collaborative Squad Pandal & Live Hopping Actions ---

  bool _applyPlanSnapshot(Map<String, dynamic> data) {
    final revision = (data['planRevision'] as num?)?.toInt() ?? 0;
    if (revision < _planRevision) return false;
    final raw = data['chosenPandals'];
    if (raw is! List) return false;
    final stops = raw
        .whereType<Map>()
        .map((item) => SquadPandalStop.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final active = data['isHoppingActive'] == true;
    final index = ((data['activeStopIndex'] as num?)?.toInt() ?? 0)
        .clamp(0, stops.length);
    final changed = revision != _planRevision ||
        jsonEncode(stops.map((e) => e.toJson()).toList()) !=
            jsonEncode(_chosenPandals.map((e) => e.toJson()).toList()) ||
        active != _isHoppingActive || index != _activeHoppingStopIndex;
    if (!changed) return false;
    final trailChanged = active != _isHoppingActive ||
        index != _activeHoppingStopIndex ||
        stops.length != _chosenPandals.length ||
        List.generate(stops.length, (i) => i).any((i) =>
            i >= _chosenPandals.length ||
            stops[i].id != _chosenPandals[i].id ||
            stops[i].isVisited != _chosenPandals[i].isVisited);
    _planRevision = revision;
    _chosenPandals = stops;
    _isHoppingActive = active && index < stops.length;
    _activeHoppingStopIndex = index;
    if (_isHoppingActive && trailChanged) {
      _syncActiveTrailWithHoppingService();
    } else if (!_isHoppingActive && CustomHoppingTrailService.instance.hasActiveTrail) {
      CustomHoppingTrailService.instance.endTrail();
    }
    return true;
  }

  Future<bool> _changePlan(
    Map<String, dynamic> Function(Map<String, dynamic>) change,
  ) async {
    if (_squadId == null) return false;
    if (_isPlanMutationPending || _groupOperationPending) return false;
    if (!_repo.isAvailable && !enableTestMode &&
        (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST'))) {
      _lastError = 'Group plan cannot sync right now. Try again when cloud sync is available.';
      notifyListeners();
      return false;
    }
    final hadError = _lastError != null;
    _lastError = null;
    _isPlanMutationPending = true;
    notifyListeners();
    try {
      Map<String, dynamic> next;
      if (_repo.isAvailable) {
        next = await _repo.mutateSquadPlan(squadId: _squadId!, change: change);
      } else {
        final current = <String, dynamic>{
          'chosenPandals': _chosenPandals.map((e) => e.toJson()).toList(),
          'isHoppingActive': _isHoppingActive,
          'activeStopIndex': _activeHoppingStopIndex,
        };
        next = {...change(current), 'planRevision': _planRevision + 1};
      }
      final changed = _applyPlanSnapshot(next);
      if (changed) {
        await _persistState();
      }
      if (changed || hadError) notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Could not sync the group plan. Please try again.';
      debugPrint('[SquadService] plan change error: $e');
      notifyListeners();
      return false;
    } finally {
      _isPlanMutationPending = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _stopsFrom(Map<String, dynamic> plan) =>
      (plan['chosenPandals'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

  /// Add a pandal to the squad's shared hopping itinerary.
  Future<bool> addPandalToSquad(Pandal pandal) async {
    if (_chosenPandals.any((p) => p.id == pandal.id)) return false;
    final user = await _ensureUser();
    final stop = SquadPandalStop.fromPandal(
      pandal,
      suggestedBy: user.uid,
      suggestedByName: user.displayName ?? 'Companion',
    );
    return _changePlan((plan) {
      final stops = _stopsFrom(plan);
      if (!stops.any((item) => item['id'] == pandal.id)) {
        stops.add(stop.toJson());
      }
      return {...plan, 'chosenPandals': stops};
    });
  }

  /// Remove a pandal from the squad's shared list.
  Future<void> removePandalFromSquad(String pandalId) async {
    await _changePlan((plan) {
      final stops = _stopsFrom(plan);
      final removedIndex = stops.indexWhere((item) => item['id'] == pandalId);
      if (removedIndex == -1) return plan;
      stops.removeAt(removedIndex);
      var index = (plan['activeStopIndex'] as num?)?.toInt() ?? 0;
      if (removedIndex < index) index--;
      index = index.clamp(0, stops.length);
      return {
        ...plan,
        'chosenPandals': stops,
        'activeStopIndex': index,
        'isHoppingActive': stops.isNotEmpty && plan['isHoppingActive'] == true,
      };
    });
  }

  /// Upvote or remove upvote for a chosen pandal stop.
  Future<void> toggleVotePandal(String pandalId) async {
    final user = await _ensureUser();
    await _changePlan((plan) {
      final stops = _stopsFrom(plan);
      final idx = stops.indexWhere((item) => item['id'] == pandalId);
      if (idx != -1) {
        final currentVotes = List<String>.from(stops[idx]['votes'] as List? ?? const []);
        if (currentVotes.contains(user.uid)) {
          currentVotes.remove(user.uid);
        } else {
          currentVotes.add(user.uid);
        }
        stops[idx]['votes'] = currentVotes;
      }
      return {...plan, 'chosenPandals': stops};
    });
  }

  /// Optimize the route between chosen pandals using on-device Held-Karp algorithm.
  Future<bool> optimizeSquadRoute() async {
    if (_chosenPandals.length < 2) return false;
    final userPos = LocationService.instance.currentPositionSync;
    final startPos = userPos != null
        ? LatLng(userPos.latitude, userPos.longitude)
        : LatLng(_chosenPandals.first.lat, _chosenPandals.first.lng);

    return _changePlan((plan) {
      final stops = _stopsFrom(plan);
      if (stops.length < 2) return plan;
      final models = stops.map(SquadPandalStop.fromJson).toList();
      final result = TrailOptimizer.optimizePandalStops(
        start: startPos,
        stops: models.map((s) => s.toPandal()).toList(),
        allowMetro: true,
      );
      final byId = {for (final stop in stops) stop['id']: stop};
      final ordered = result.orderedStops.map((p) => byId[p.id]!).toList();
      final targetId = (plan['activeStopIndex'] as num?)?.toInt() ?? 0;
      final oldTarget = targetId < stops.length ? stops[targetId]['id'] : null;
      final newIndex = oldTarget == null ? ordered.length : ordered.indexWhere((s) => s['id'] == oldTarget);
      return {...plan, 'chosenPandals': ordered, 'activeStopIndex': newIndex < 0 ? 0 : newIndex};
    });
  }

  /// Manually reorder a pandal stop within the chosen stops list.
  Future<void> reorderSquadPandals(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _chosenPandals.length) return;
    if (newIndex < 0 || newIndex > _chosenPandals.length) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final movedId = _chosenPandals[oldIndex].id;
    final desiredOrder = _chosenPandals.map((s) => s.id).toList();
    desiredOrder.removeAt(oldIndex);
    desiredOrder.insert(newIndex, movedId);
    final beforeId = newIndex + 1 < desiredOrder.length
        ? desiredOrder[newIndex + 1]
        : null;
    await _changePlan((plan) {
      final stops = _stopsFrom(plan);
      final from = stops.indexWhere((s) => s['id'] == movedId);
      if (from < 0) return plan;
      final active = (plan['activeStopIndex'] as num?)?.toInt() ?? 0;
      final currentId = active < stops.length ? stops[active]['id'] : null;
      final moved = stops.removeAt(from);
      final to = beforeId == null ? stops.length : stops.indexWhere((s) => s['id'] == beforeId);
      stops.insert(to < 0 ? stops.length : to, moved);
      final nextIndex = currentId == null ? stops.length : stops.indexWhere((s) => s['id'] == currentId);
      return {...plan, 'chosenPandals': stops, 'activeStopIndex': nextIndex < 0 ? 0 : nextIndex};
    });
  }

  /// Start hopping together with the squad along the chosen pandal list.
  /// Activates the live street trail, auto-visit proximity detection,
  /// background navigation, and live companions tracking.
  Future<bool> startSquadHopping({LatLng? startLocation}) async {
    if (_chosenPandals.isEmpty) return false;
    return _changePlan((plan) {
      final stops = _stopsFrom(plan);
      if (stops.isEmpty) return plan;
      final firstUnvisited = stops.indexWhere((stop) => stop['isVisited'] != true);
      if (firstUnvisited < 0) {
        for (final stop in stops) {
          stop['isVisited'] = false;
        }
      }
      return {
        ...plan,
        'chosenPandals': stops,
        'isHoppingActive': true,
        'activeStopIndex': firstUnvisited < 0 ? 0 : firstUnvisited,
      };
    });
  }

  /// Mark the current pandal visited and advance to the next stop.
  Future<void> advanceToNextPandalStop() async {
    await _moveToNextStop(markVisited: true);
  }

  /// Move on without counting this stop as visited.
  Future<void> skipCurrentPandalStop() async {
    await _moveToNextStop(markVisited: false);
  }

  Future<void> _moveToNextStop({required bool markVisited}) async {
    final expectedStopId = currentHoppingTarget?.id;
    if (expectedStopId == null) return;
    await _changePlan((plan) {
      final stops = _stopsFrom(plan);
      final current = (plan['activeStopIndex'] as num?)?.toInt() ?? 0;
      if (plan['isHoppingActive'] != true || current >= stops.length) return plan;
      if (stops[current]['id'] != expectedStopId) return plan;
      if (markVisited) stops[current]['isVisited'] = true;
      final next = current + 1;
      return {
        ...plan,
        'chosenPandals': stops,
        'activeStopIndex': next,
        'isHoppingActive': next < stops.length,
      };
    });
  }

  /// End the live hopping session for the squad.
  Future<void> endSquadHopping() async {
    await _changePlan((plan) => {...plan, 'isHoppingActive': false});
  }

  void _syncActiveTrailWithHoppingService({LatLng? startPos}) {
    if (_chosenPandals.isEmpty) return;
    final userPos = LocationService.instance.currentPositionSync;
    final effectiveStart = startPos ??
        (userPos != null
            ? LatLng(userPos.latitude, userPos.longitude)
            : LatLng(_chosenPandals.first.lat, _chosenPandals.first.lng));

    final pandalStops = _chosenPandals.map((s) => s.toPandal()).toList();
    // Preserve the shared order. Optimization is an explicit group action.
    final orderedPoints = [
      effectiveStart,
      ...pandalStops.map((p) => LatLng(p.lat, p.lng)),
    ];
    final legs = buildLegBreakdown(
      orderedPoints,
      allowMetro: true,
      allowTrain: true,
      walkingSpeedKmH: TrailOptimizer.defaultWalkingSpeedKmH,
    );
    final distanceKm = legs.fold<double>(0, (sum, leg) => sum + leg.distanceKm);
    final travelMinutes = legs.fold<double>(0, (sum, leg) {
      if (leg.isMetro) return sum + (leg.metroDetail?.totalMinutes ?? 0);
      if (leg.isTrain) return sum + (leg.trainDetail?.totalMinutes ?? 0);
      return sum + leg.distanceKm / TrailOptimizer.defaultWalkingSpeedKmH * 60;
    });

    final trail = ActiveCustomTrail.custom(
      id: 'squad_trail_${_squadCode ?? "live"}',
      startingLocation: effectiveStart,
      startingAddress: _squadName ?? 'Squad Hopping',
      stops: pandalStops,
      totalDistanceKm: distanceKm,
      totalEstimatedMinutes: (travelMinutes + (pandalStops.length * 15)).round(),
      allowMetro: true,
      allowTrain: true,
      legs: legs,
    );

    for (final stop in _chosenPandals.where((stop) => stop.isVisited)) {
      trail.visitedPandalIds.add(stop.id);
    }
    trail.currentStopIndex = _activeHoppingStopIndex.clamp(0, trail.stops.length - 1);

    CustomHoppingTrailService.instance.startTrail(trail);
  }

  @override
  void dispose() {
    _groupsSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    LocationService.instance.removeListener(_onLocationServiceChange);
    AuthService.instance.removeListener(_onAuthServiceChange);
    _batteryPollTimer?.cancel();
    _batterySub?.cancel();
    _membersSub?.cancel();
    _squadSub?.cancel();
    super.dispose();
  }
}
