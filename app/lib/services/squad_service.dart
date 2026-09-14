import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/squad_member.dart';
import 'auth_service.dart';
import 'location_service.dart';

/// Centralized state manager for Durga Puja hopping squads.
/// Grounded in real device GPS coordinates from [LocationService].
/// When a squad is created, it begins with ONLY the host (0 companion members).
/// Real companions join dynamically via invite code and sync live positions.
class SquadService extends ChangeNotifier {
  SquadService._({this._prefs}) {
    _listenToLocationService();
  }

  final SharedPreferences? _prefs;
  static SquadService? _instance;

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

  final List<SquadMember> _members = [];
  StreamSubscription? _rtdbSub;
  final Random _random = Random();

  // Getters
  String? get squadCode => _squadCode;
  String? get squadName => _squadName;
  String get meetupPointName => _meetupPointName;
  LatLng get meetupPointCoords => _meetupPointCoords;
  bool get hasActiveSquad => _squadCode != null;
  bool get isSharingLocation => _isSharingLocation;
  bool get isBatterySaver => _batterySaver;
  bool get showSquadOnMap => _showSquadOnMap;
  String? get focusedMemberId => _focusedMemberId;
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

  void _listenToLocationService() {
    LocationService.instance.addListener(() {
      final pos = LocationService.instance.currentPositionSync;
      if (pos != null && hasActiveSquad && _isSharingLocation) {
        updateUserLocation(pos.latitude, pos.longitude);
      }
    });
  }

  Future<void> _loadSavedState() async {
    if (_prefs == null) return;
    final code = _prefs.getString('saved_group_code');
    final name = _prefs.getString('saved_group_name');
    final meetup = _prefs.getString('saved_meetup_point');

    if (code != null && name != null) {
      _squadCode = code;
      _squadName = name;
      if (meetup != null) _meetupPointName = meetup;
      _initMembers(isHost: true);
      _listenToCloud();
      _pushUserToCloud();
    }
  }

  Future<void> _persistState() async {
    if (_prefs == null) return;
    if (_squadCode != null) {
      await _prefs.setString('saved_group_code', _squadCode!);
      await _prefs.setString('saved_group_name', _squadName ?? 'My Squad');
      await _prefs.setString('saved_meetup_point', _meetupPointName);
    } else {
      await _prefs.remove('saved_group_code');
      await _prefs.remove('saved_group_name');
      await _prefs.remove('saved_meetup_point');
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

  /// Adds companion members with Google DPs near the user for demonstration / testing
  void addDemoCompanions() {
    if (!hasActiveSquad) return;
    final currentPos = LocationService.instance.currentPositionSync;
    final baseLat = currentPos?.latitude ?? LocationService.instance.currentCoordinates.latitude;
    final baseLng = currentPos?.longitude ?? LocationService.instance.currentCoordinates.longitude;

    final priya = SquadMember(
      id: 'companion_priya',
      name: 'Priya Mukherjee',
      latitude: baseLat + 0.0021,
      longitude: baseLng + 0.0018,
      status: 'At Food Stall • Active',
      lastSeen: DateTime.now(),
      photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
      isHost: false,
      isUser: false,
      batteryLevel: 88,
      avatarColorHex: 0xFFE91E63,
    );

    final rohan = SquadMember(
      id: 'companion_rohan',
      name: 'Rohan Sen',
      latitude: baseLat - 0.0032,
      longitude: baseLng + 0.0025,
      status: 'Near Metro Gate • Walking',
      lastSeen: DateTime.now(),
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
      isHost: false,
      isUser: false,
      batteryLevel: 74,
      avatarColorHex: 0xFF2196F3,
    );

    addMember(priya);
    addMember(rohan);
  }

  /// Create a brand new hopping squad with real device GPS coordinates.
  static const _codeAlphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  /// Starts with 0 companions (empty companion list).
  Future<void> createSquad(String name, String meetup, [LatLng? meetupCoords]) async {
    final suffix = List.generate(4, (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)]).join();
    final code = 'PUJA$suffix';
    _squadCode = code;
    _squadName = name.trim().isEmpty ? 'My Puja Squad' : name.trim();
    _meetupPointName = meetup.trim().isEmpty ? 'Main Entrance Gate' : meetup.trim();

    // Use current real GPS position immediately
    final currentPos = LocationService.instance.currentPositionSync;
    final realLat = currentPos?.latitude ?? LocationService.instance.currentCoordinates.latitude;
    final realLng = currentPos?.longitude ?? LocationService.instance.currentCoordinates.longitude;
    _meetupPointCoords = meetupCoords ?? LatLng(realLat, realLng);

    _initMembers(isHost: true, userLat: realLat, userLng: realLng);
    _persistState();
    _pushUserToCloud();
    _listenToCloud();
    notifyListeners();

    // If location fix is still pending, refresh asynchronously
    if (currentPos == null) {
      LocationService.instance.currentPosition().then((pos) {
        if (pos != null && hasActiveSquad) {
          updateUserLocation(pos.latitude, pos.longitude);
          if (meetupCoords == null) {
            _meetupPointCoords = LatLng(pos.latitude, pos.longitude);
            notifyListeners();
          }
        }
      }).catchError((_) {});
    }
  }

  /// Join an existing squad by invite code
  Future<void> joinSquad(String code, [LatLng? initialCoords]) async {
    final cleanCode = code.trim().toUpperCase();
    _squadCode = cleanCode;
    _squadName = 'Squad $cleanCode';
    _meetupPointName = 'Designated Meet-up Landmark';

    final currentPos = LocationService.instance.currentPositionSync;
    final lat = initialCoords?.latitude ?? currentPos?.latitude ?? LocationService.instance.currentCoordinates.latitude;
    final lng = initialCoords?.longitude ?? currentPos?.longitude ?? LocationService.instance.currentCoordinates.longitude;
    _meetupPointCoords = LatLng(lat, lng);

    _initMembers(isHost: false, userLat: lat, userLng: lng);
    _persistState();
    _pushUserToCloud();
    _listenToCloud();
    notifyListeners();

    if (currentPos == null) {
      LocationService.instance.currentPosition().then((pos) {
        if (pos != null && hasActiveSquad) {
          updateUserLocation(pos.latitude, pos.longitude);
        }
      }).catchError((_) {});
    }
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
  void leaveSquad() {
    if (_squadCode != null && _isFirebaseAvailable) {
      try {
        final user = AuthService.instance.currentUserModel;
        final uid = user?.uid ?? 'user_self';
        FirebaseDatabase.instance.ref('squads/$_squadCode/members/$uid').remove();
      } catch (_) {}
    }
    _rtdbSub?.cancel();
    _rtdbSub = null;
    _squadCode = null;
    _squadName = null;
    _focusedMemberId = null;
    _members.clear();
    _persistState();
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
    notifyListeners();
  }

  /// Toggle user's live location sharing
  void toggleLocationSharing(bool val) {
    _isSharingLocation = val;
    if (!val && _squadCode != null && _isFirebaseAvailable) {
      try {
        final user = AuthService.instance.currentUserModel;
        final uid = user?.uid ?? 'user_self';
        FirebaseDatabase.instance.ref('squads/$_squadCode/members/$uid').remove();
      } catch (_) {}
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

  // --- Real-Time Cloud Sync (Firebase Realtime Database) ---

  void _pushUserToCloud() {
    if (_squadCode == null || !_isSharingLocation || !_isFirebaseAvailable) return;
    try {
      final userMember = _members.firstWhere((m) => m.isUser);
      final ref = FirebaseDatabase.instance.ref('squads/$_squadCode/members/${userMember.id}');
      ref.set(userMember.toJson());
    } catch (_) {}
  }

  void _listenToCloud() {
    _rtdbSub?.cancel();
    if (_squadCode == null || !_isFirebaseAvailable) return;
    try {
      final ref = FirebaseDatabase.instance.ref('squads/$_squadCode/members');
      _rtdbSub = ref.onValue.listen((event) {
        final snap = event.snapshot;
        if (snap.value == null) return;
        final raw = Map<String, dynamic>.from(snap.value as Map);
        final currentUserId = AuthService.instance.currentUserModel?.uid ?? 'user_self';

        bool changed = false;
        raw.forEach((key, val) {
          if (key == currentUserId) return; // Don't overwrite local host user
          try {
            final memberData = Map<String, dynamic>.from(val as Map);
            final member = SquadMember.fromJson(memberData);
            final idx = _members.indexWhere((m) => m.id == member.id);
            if (idx != -1) {
              _members[idx] = member;
            } else {
              _members.add(member);
            }
            changed = true;
          } catch (_) {}
        });

        // Remove members that left
        _members.removeWhere((m) => !m.isUser && !raw.containsKey(m.id));

        if (changed) {
          notifyListeners();
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _rtdbSub?.cancel();
    super.dispose();
  }
}
