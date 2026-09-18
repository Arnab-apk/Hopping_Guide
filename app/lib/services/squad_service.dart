import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/squad_member.dart';
import 'auth_service.dart';
import 'location_service.dart';
import 'websocket_client.dart';

/// Centralized state manager for Durga Puja hopping squads.
/// Grounded in real device GPS coordinates from [LocationService].
/// When a squad is created, it begins with ONLY the host (0 companion members).
/// Real companions join dynamically via invite code and sync live positions
/// and metadata via Firebase Realtime Database.
class SquadService extends ChangeNotifier {
  SquadService._({this._prefs}) {
    _listenToLocationService();
    _listenToAuthService();
  }

  final SharedPreferences? _prefs;
  static SquadService? _instance;

  static const String rtdbUrl = 'https://kolkata-puja-2026-default-rtdb.firebaseio.com';

  static SquadService get instance {
    _instance ??= SquadService._();
    return _instance!;
  }

  static Future<SquadService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final service = SquadService._(prefs: prefs);
    await service._loadSavedState();
    _instance = service;
    return service;
  }

  // Active squad metadata
  String? _squadCode;
  String? _squadName;
  String _meetupPointName = 'Designated Meet-up Landmark';
  LatLng _meetupPointCoords = LocationService.defaultKolkataCenter;
  bool _isSharingLocation = true;
  bool _batterySaver = false;
  bool _showSquadOnMap = true;
  String? _focusedMemberId;
  String? _lastError;

  final List<SquadMember> _members = [];
  final WebSocketClient _wsClient = WebSocketClient();
  StreamSubscription? _wsSub;
  StreamSubscription? _rtdbSub;
  StreamSubscription? _metaSub;
  final Random _random = Random();

  // Getters
  WebSocketConnectionState get wsConnectionState => _wsClient.currentState;
  bool get isWsConnected => _wsClient.isConnected;
  String? get squadCode => _squadCode;
  String? get squadName => _squadName;
  String get meetupPointName => _meetupPointName;
  LatLng get meetupPointCoords => _meetupPointCoords;
  bool get hasActiveSquad => _squadCode != null;
  bool get isSharingLocation => _isSharingLocation;
  bool get isBatterySaver => _batterySaver;
  bool get showSquadOnMap => _showSquadOnMap;
  String? get focusedMemberId => _focusedMemberId;
  String? get lastError => _lastError;
  List<SquadMember> get members => List.unmodifiable(_members);

  /// Companion members that are not the local user.
  /// When a squad is newly created, this is strictly empty.
  List<SquadMember> get companionMembers =>
      _members.where((m) => !m.isUser).toList();

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _sanitizeKey(String raw) => raw.replaceAll(RegExp(r'[.#$\[\]/]'), '_');

  /// Safe accessor to FirebaseDatabase with automatic URL fallback
  FirebaseDatabase? get _database {
    if (!_isFirebaseAvailable) return null;
    try {
      return FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: rtdbUrl,
      );
    } catch (_) {
      try {
        return FirebaseDatabase.instance;
      } catch (err) {
        debugPrint('[SquadService] FirebaseDatabase init error: $err');
        return null;
      }
    }
  }

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
            _pushUserToCloud();
            notifyListeners();
          }
        }
      }
    });
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
      final code = prefs.getString('saved_group_code');
      final name = prefs.getString('saved_group_name');
      final meetup = prefs.getString('saved_meetup_point');

      if (code != null && name != null) {
        _squadCode = code;
        _squadName = name;
        if (meetup != null) _meetupPointName = meetup;
        _initMembers(isHost: true);
        _listenToCloud();
        _pushUserToCloud();
        final currentPos = LocationService.instance.currentPositionSync;
        final lat = currentPos?.latitude ?? LocationService.instance.currentCoordinates.latitude;
        final lng = currentPos?.longitude ?? LocationService.instance.currentCoordinates.longitude;
        _initWebSocket(isHost: true, lat: lat, lng: lng);
      }
    } catch (e) {
      debugPrint('[SquadService] _loadSavedState error: $e');
    }
  }

  Future<void> _persistState() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      if (_squadCode != null) {
        await prefs.setString('saved_group_code', _squadCode!);
        await prefs.setString('saved_group_name', _squadName ?? 'My Squad');
        await prefs.setString('saved_meetup_point', _meetupPointName);
      } else {
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
        isHost: isHost,
        isUser: true,
        batteryLevel: 95,
        avatarColorHex: 0xFFD32F2F, // Durga crimson
      ),
    );
  }


  static const String _codeAlphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  /// Create a brand new hopping squad with real device GPS coordinates.
  /// Generates a valid, randomized 8-char squad invite code (e.g. PUJA7K9X).
  static String generateSquadCode([Random? random]) {
    final r = random ?? Random();
    final suffix = List.generate(4, (_) => _codeAlphabet[r.nextInt(_codeAlphabet.length)]).join();
    return 'PUJA$suffix';
  }

  /// Starts with 0 companions (empty companion list).
  Future<void> createSquad(String name, String meetup, [LatLng? meetupCoords]) async {
    _lastError = null;
    await _ensureUser();

    final code = generateSquadCode(_random);
    _squadCode = code;
    _squadName = name.trim().isEmpty ? 'My Puja Squad' : name.trim();
    _meetupPointName = meetup.trim().isEmpty ? 'Main Entrance Landmark' : meetup.trim();

    // Use current real GPS position immediately
    final currentPos = LocationService.instance.currentPositionSync;
    final realLat = currentPos?.latitude ?? LocationService.instance.currentCoordinates.latitude;
    final realLng = currentPos?.longitude ?? LocationService.instance.currentCoordinates.longitude;
    _meetupPointCoords = meetupCoords ?? LatLng(realLat, realLng);

    _initMembers(isHost: true, userLat: realLat, userLng: realLng);
    _initWebSocket(isHost: true, lat: realLat, lng: realLng);
    await _persistState();
    await _pushMetaToCloud();
    await _pushUserToCloud();
    _listenToCloud();
    notifyListeners();

    // If location fix is still pending, refresh asynchronously
    if (currentPos == null) {
      LocationService.instance.currentPosition().then((pos) {
        if (pos != null && hasActiveSquad) {
          updateUserLocation(pos.latitude, pos.longitude);
          if (meetupCoords == null) {
            _meetupPointCoords = LatLng(pos.latitude, pos.longitude);
            _pushMetaToCloud();
            notifyListeners();
          }
        }
      }).catchError((_) {});
    }
  }

  /// Join an existing squad by invite code
  Future<bool> joinSquad(String code, [LatLng? initialCoords]) async {
    _lastError = null;
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      _lastError = 'Please enter a valid squad code.';
      return false;
    }

    await _ensureUser();
    final db = _database;

    String squadName = 'Squad $cleanCode';
    String meetupName = 'Designated Meet-up Landmark';
    LatLng meetupCoords = LocationService.defaultKolkataCenter;
    final Map<String, dynamic> existingCloudMembers = {};

    if (db != null) {
      try {
        final metaSnap = await db.ref('squads/$cleanCode/meta').get().timeout(const Duration(seconds: 4));
        final membersSnap = await db.ref('squads/$cleanCode/members').get().timeout(const Duration(seconds: 4));

        if (!metaSnap.exists && !membersSnap.exists) {
          _lastError = 'Squad "$cleanCode" not found. Please verify the invite code.';
          debugPrint('[SquadService] Squad $cleanCode not found in RTDB');
          return false;
        }

        if (metaSnap.exists && metaSnap.value is Map) {
          final data = Map<String, dynamic>.from(metaSnap.value as Map);
          if (data['name'] is String && (data['name'] as String).isNotEmpty) {
            squadName = data['name'] as String;
          }
          if (data['meetup_name'] is String && (data['meetup_name'] as String).isNotEmpty) {
            meetupName = data['meetup_name'] as String;
          }
          final mLat = (data['meetup_lat'] as num?)?.toDouble();
          final mLng = (data['meetup_lng'] as num?)?.toDouble();
          if (mLat != null && mLng != null) {
            meetupCoords = LatLng(mLat, mLng);
          }
        }

        if (membersSnap.exists && membersSnap.value is Map) {
          final raw = Map<String, dynamic>.from(membersSnap.value as Map);
          existingCloudMembers.addAll(raw);
        }
      } catch (e) {
        debugPrint('[SquadService] Verify squad on join note: $e');
      }
    }

    _squadCode = cleanCode;
    _squadName = squadName;
    _meetupPointName = meetupName;
    _meetupPointCoords = meetupCoords;

    final currentPos = LocationService.instance.currentPositionSync;
    final lat = initialCoords?.latitude ?? currentPos?.latitude ?? LocationService.instance.currentCoordinates.latitude;
    final lng = initialCoords?.longitude ?? currentPos?.longitude ?? LocationService.instance.currentCoordinates.longitude;

    _initMembers(isHost: false, userLat: lat, userLng: lng);
    _initWebSocket(isHost: false, lat: lat, lng: lng);

    // Populate existing members immediately from cloud snapshot
    final currentUserId = AuthService.instance.currentUserModel?.uid ?? 'user_self';
    final safeUserId = _sanitizeKey(currentUserId);
    existingCloudMembers.forEach((key, val) {
      if (key == currentUserId || key == safeUserId) return;
      if (val is Map) {
        try {
          final member = SquadMember.fromJson(Map<String, dynamic>.from(val)).copyWith(isUser: false);
          final idx = _members.indexWhere((m) => m.id == member.id);
          if (idx != -1) {
            _members[idx] = member;
          } else {
            _members.add(member);
          }
        } catch (e) {
          debugPrint('[SquadService] Parse initial member error: $e');
        }
      }
    });

    await _persistState();
    await _pushUserToCloud();
    _listenToCloud();
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
    notifyListeners();
  }

  /// Remove a member by ID
  void removeMember(String memberId) {
    _members.removeWhere((m) => m.id == memberId && !m.isUser);
    notifyListeners();
  }

  /// Leave the current squad and clear members
  Future<void> leaveSquad() async {
    final oldCode = _squadCode;
    if (oldCode != null) {
      _wsClient.sendMessage({
        'type': 'leave_squad',
        'squad_code': oldCode,
      });
      _wsClient.close();
      _wsSub?.cancel();
      _wsSub = null;
    }
    if (oldCode != null && _isFirebaseAvailable) {
      try {
        final user = AuthService.instance.currentUserModel;
        final uid = user?.uid ?? 'user_self';
        final safeId = _sanitizeKey(uid);
        final db = _database;
        if (db != null) {
          await db.ref('squads/$oldCode/members/$safeId').remove();
          debugPrint('[SquadService] Removed member $safeId from squad $oldCode in RTDB');
        }
      } catch (e) {
        debugPrint('[SquadService] leaveSquad RTDB removal note: $e');
      }
    }
    _rtdbSub?.cancel();
    _rtdbSub = null;
    _metaSub?.cancel();
    _metaSub = null;
    _squadCode = null;
    _squadName = null;
    _focusedMemberId = null;
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
      );
      if (_squadCode != null) {
        _wsClient.sendMessage({
          'type': 'location_update',
          'squad_code': _squadCode,
          'latitude': lat,
          'longitude': lng,
          'status': _members[idx].status,
          'battery_level': _members[idx].batteryLevel,
          'photo_url': _members[idx].photoUrl,
        });
      }
      _pushUserToCloud();
      notifyListeners();
    }
  }

  /// Update the designated meetup landmark
  void setMeetupPoint(String name, [LatLng? coords]) {
    _meetupPointName = name.trim();
    if (coords != null) {
      _meetupPointCoords = coords;
    }
    _persistState();
    if (_squadCode != null) {
      _wsClient.sendMessage({
        'type': 'squad_meta_update',
        'squad_code': _squadCode,
        'name': _squadName,
        'meetup_name': _meetupPointName,
        'meetup_lat': _meetupPointCoords.latitude,
        'meetup_lng': _meetupPointCoords.longitude,
      });
    }
    _pushMetaToCloud();
    notifyListeners();
  }

  /// Toggle user's live location sharing
  void toggleLocationSharing(bool val) {
    _isSharingLocation = val;
    if (!val && _squadCode != null && _isFirebaseAvailable) {
      try {
        final user = AuthService.instance.currentUserModel;
        final uid = user?.uid ?? 'user_self';
        final db = _database;
        db?.ref('squads/$_squadCode/members/$uid').remove();
      } catch (e) {
        debugPrint('[SquadService] Location sharing disable remove note: $e');
      }
    } else if (val) {
      _pushUserToCloud();
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

  // --- High-Speed In-Memory WebSocket Live Sync ---

  void _initWebSocket({required bool isHost, required double lat, required double lng}) {
    _wsSub?.cancel();
    final user = AuthService.instance.currentUserModel;
    final uid = user?.uid ?? 'user_self';
    final name = user?.displayName ?? (isHost ? 'Host' : 'Member');

    _wsSub = _wsClient.messages.listen((msg) {
      _handleWebSocketMessage(msg);
    }, onError: (err) {
      debugPrint('[SquadService] WebSocket message stream error: $err');
    });

    _wsClient.connect(uid).then((_) {
      if (_squadCode != null) {
        _wsClient.sendMessage({
          'type': 'join_squad',
          'squad_code': _squadCode,
          'member_name': name,
          'is_host': isHost,
          'initial_latitude': lat,
          'initial_longitude': lng,
          'photo_url': user?.photoUrl,
        });
      }
    }).catchError((err) {
      debugPrint('[SquadService] WebSocket connect error: $err');
    });
  }

  void _handleWebSocketMessage(Map<String, dynamic> msg) {
    final type = msg['type'];
    final currentUserId = AuthService.instance.currentUserModel?.uid ?? 'user_self';
    final safeUserId = _sanitizeKey(currentUserId);

    if (type == 'squad_joined') {
      final meta = msg['metadata'];
      if (meta is Map) {
        if (meta['name'] is String && (meta['name'] as String).isNotEmpty) {
          _squadName = meta['name'];
        }
        if (meta['meetupPointName'] is String && (meta['meetupPointName'] as String).isNotEmpty) {
          _meetupPointName = meta['meetupPointName'];
        }
        final mLat = (meta['meetupLat'] as num?)?.toDouble();
        final mLng = (meta['meetupLng'] as num?)?.toDouble();
        if (mLat != null && mLng != null) {
          _meetupPointCoords = LatLng(mLat, mLng);
        }
      }
      notifyListeners();
    } else if (type == 'member_list') {
      final membersList = msg['members'];
      if (membersList is List) {
        bool changed = false;
        for (final item in membersList) {
          if (item is Map) {
            final mId = item['member_id'] as String?;
            if (mId == null || mId == currentUserId || mId == safeUserId) continue;
            final mLat = (item['latitude'] as num?)?.toDouble() ?? LocationService.defaultKolkataCenter.latitude;
            final mLng = (item['longitude'] as num?)?.toDouble() ?? LocationService.defaultKolkataCenter.longitude;
            final member = SquadMember(
              id: mId,
              name: item['member_name'] as String? ?? 'Companion',
              latitude: mLat,
              longitude: mLng,
              status: item['status'] as String? ?? 'Active',
              lastSeen: DateTime.fromMillisecondsSinceEpoch(
                (item['last_seen'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
              ),
              photoUrl: item['photo_url'] as String?,
              isHost: item['is_host'] == true,
              isUser: false,
              batteryLevel: (item['battery_level'] as num?)?.toInt() ?? 100,
            );
            final idx = _members.indexWhere((m) => m.id == member.id);
            if (idx != -1) {
              _members[idx] = member;
            } else {
              _members.add(member);
            }
            changed = true;
          }
        }
        if (changed) notifyListeners();
      }
    } else if (type == 'member_joined') {
      final mId = msg['member_id'] as String?;
      if (mId == null || mId == currentUserId || mId == safeUserId) return;
      final mLat = (msg['latitude'] as num?)?.toDouble() ?? LocationService.defaultKolkataCenter.latitude;
      final mLng = (msg['longitude'] as num?)?.toDouble() ?? LocationService.defaultKolkataCenter.longitude;
      final member = SquadMember(
        id: mId,
        name: msg['member_name'] as String? ?? 'Companion',
        latitude: mLat,
        longitude: mLng,
        status: msg['status'] as String? ?? 'Active',
        lastSeen: DateTime.now(),
        photoUrl: msg['photo_url'] as String?,
        isHost: msg['is_host'] == true,
        isUser: false,
        batteryLevel: (msg['battery_level'] as num?)?.toInt() ?? 100,
      );
      final idx = _members.indexWhere((m) => m.id == member.id);
      if (idx != -1) {
        _members[idx] = member;
      } else {
        _members.add(member);
      }
      notifyListeners();
    } else if (type == 'location_update') {
      final mId = msg['member_id'] as String?;
      if (mId == null || mId == currentUserId || mId == safeUserId) return;
      final mLat = (msg['latitude'] as num?)?.toDouble();
      final mLng = (msg['longitude'] as num?)?.toDouble();
      if (mLat == null || mLng == null) return;
      final idx = _members.indexWhere((m) => m.id == mId);
      if (idx != -1) {
        _members[idx] = _members[idx].copyWith(
          latitude: mLat,
          longitude: mLng,
          status: msg['status'] as String? ?? _members[idx].status,
          batteryLevel: (msg['battery_level'] as num?)?.toInt() ?? _members[idx].batteryLevel,
          lastSeen: DateTime.now(),
        );
        notifyListeners();
      }
    } else if (type == 'squad_meta_updated') {
      final meta = msg['metadata'];
      if (meta is Map) {
        if (meta['name'] is String && (meta['name'] as String).isNotEmpty) {
          _squadName = meta['name'];
        }
        if (meta['meetupPointName'] is String && (meta['meetupPointName'] as String).isNotEmpty) {
          _meetupPointName = meta['meetupPointName'];
        }
        final mLat = (meta['meetupLat'] as num?)?.toDouble();
        final mLng = (meta['meetupLng'] as num?)?.toDouble();
        if (mLat != null && mLng != null) {
          _meetupPointCoords = LatLng(mLat, mLng);
        }
        notifyListeners();
      }
    } else if (type == 'member_left') {
      final mId = msg['member_id'] as String?;
      if (mId != null) {
        final before = _members.length;
        _members.removeWhere((m) => m.id == mId && !m.isUser);
        if (_members.length != before) {
          notifyListeners();
        }
      }
    } else if (type == 'error') {
      _lastError = msg['message'] as String? ?? 'WebSocket error';
      notifyListeners();
    }
  }

  // --- Real-Time Cloud Sync (Firebase Realtime Database) ---

  Future<void> _pushUserToCloud() async {
    final db = _database;
    if (_squadCode == null || !_isSharingLocation || db == null) return;
    try {
      final userMember = _members.firstWhere((m) => m.isUser);
      final safeId = _sanitizeKey(userMember.id);
      final ref = db.ref('squads/$_squadCode/members/$safeId');
      await ref.set(userMember.toJson());
      debugPrint('[SquadService] Pushed user $safeId location to RTDB (${userMember.latitude}, ${userMember.longitude})');
    } catch (e) {
      _lastError = 'Cloud sync: $e';
      debugPrint('[SquadService] _pushUserToCloud error: $e');
    }
  }

  Future<void> _pushMetaToCloud() async {
    final db = _database;
    if (_squadCode == null || db == null) return;
    try {
      final ref = db.ref('squads/$_squadCode/meta');
      await ref.update({
        'name': _squadName ?? 'My Squad',
        'meetup_name': _meetupPointName,
        'meetup_lat': _meetupPointCoords.latitude,
        'meetup_lng': _meetupPointCoords.longitude,
        'updated_at': ServerValue.timestamp,
      });
      debugPrint('[SquadService] Pushed squad metadata to RTDB');
    } catch (e) {
      debugPrint('[SquadService] _pushMetaToCloud error: $e');
    }
  }

  void _listenToCloud() {
    _rtdbSub?.cancel();
    _metaSub?.cancel();
    final db = _database;
    if (_squadCode == null || db == null) return;

    // 1. Listen to companion members
    try {
      final ref = db.ref('squads/$_squadCode/members');
      _rtdbSub = ref.onValue.listen((event) {
        final snap = event.snapshot;
        if (snap.value == null) {
          final before = _members.length;
          _members.removeWhere((m) => !m.isUser);
          if (_members.length != before) {
            notifyListeners();
          }
          return;
        }
        if (snap.value is! Map) return;
        final raw = Map<String, dynamic>.from(snap.value as Map);
        final currentUserId = AuthService.instance.currentUserModel?.uid ?? 'user_self';
        final safeUserId = _sanitizeKey(currentUserId);

        bool changed = false;
        raw.forEach((key, val) {
          if (key == currentUserId || key == safeUserId) return; // Don't overwrite local user
          if (val is! Map) return;
          try {
            final memberData = Map<String, dynamic>.from(val);
            // Incoming members from cloud are companions, so isUser is forced to false
            final member = SquadMember.fromJson(memberData).copyWith(isUser: false);
            final idx = _members.indexWhere((m) => m.id == member.id);
            if (idx != -1) {
              if (_members[idx].latitude != member.latitude ||
                  _members[idx].longitude != member.longitude ||
                  _members[idx].status != member.status ||
                  _members[idx].photoUrl != member.photoUrl) {
                _members[idx] = member;
                changed = true;
              }
            } else {
              _members.add(member);
              changed = true;
            }
          } catch (e) {
            debugPrint('[SquadService] Error parsing cloud member: $e');
          }
        });

        // Remove members that left
        final before = _members.length;
        _members.removeWhere((m) =>
            !m.isUser &&
            !raw.containsKey(m.id) &&
            !raw.containsKey(_sanitizeKey(m.id)));
        if (_members.length != before) changed = true;

        if (changed) {
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('[SquadService] RTDB members stream error: $e');
      });
    } catch (e) {
      debugPrint('[SquadService] Listen to members error: $e');
    }

    // 2. Listen to squad metadata (Name, Meetup Landmark, Coordinates)
    try {
      final metaRef = db.ref('squads/$_squadCode/meta');
      _metaSub = metaRef.onValue.listen((event) {
        final snap = event.snapshot;
        if (snap.value == null) return;
        try {
          final data = Map<String, dynamic>.from(snap.value as Map);
          bool changed = false;
          if (data['name'] is String && (data['name'] as String).isNotEmpty && data['name'] != _squadName) {
            _squadName = data['name'] as String;
            changed = true;
          }
          if (data['meetup_name'] is String && (data['meetup_name'] as String).isNotEmpty && data['meetup_name'] != _meetupPointName) {
            _meetupPointName = data['meetup_name'] as String;
            changed = true;
          }
          final mLat = (data['meetup_lat'] as num?)?.toDouble();
          final mLng = (data['meetup_lng'] as num?)?.toDouble();
          if (mLat != null && mLng != null) {
            final newCoords = LatLng(mLat, mLng);
            if ((newCoords.latitude - _meetupPointCoords.latitude).abs() > 0.00001 ||
                (newCoords.longitude - _meetupPointCoords.longitude).abs() > 0.00001) {
              _meetupPointCoords = newCoords;
              changed = true;
            }
          }
          if (changed) {
            _persistState();
            notifyListeners();
          }
        } catch (e) {
          debugPrint('[SquadService] Error parsing cloud meta: $e');
        }
      }, onError: (e) {
        debugPrint('[SquadService] RTDB meta stream error: $e');
      });
    } catch (e) {
      debugPrint('[SquadService] Listen to meta error: $e');
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsClient.dispose();
    _rtdbSub?.cancel();
    _metaSub?.cancel();
    super.dispose();
  }
}
