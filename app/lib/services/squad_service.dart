import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/squad_member.dart';
import 'auth_service.dart';

/// Centralized state manager for Durga Puja hopping squads.
/// Syncs squad members' real-time coordinates, designated meetup point,
/// and live location streams between the Squad screen and Map screen.
class SquadService extends ChangeNotifier {
  SquadService._({this._prefs});

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
  String _meetupPointName = 'Hatibagan Crossing Gate';
  LatLng _meetupPointCoords = const LatLng(22.5995, 88.3725); // Central North Kolkata landmark
  bool _isSharingLocation = true;
  bool _batterySaver = false;
  bool _showSquadOnMap = true;
  String? _focusedMemberId;

  final List<SquadMember> _members = [];
  Timer? _simulationTimer;
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

  /// Companion members that are not the user
  List<SquadMember> get companionMembers =>
      _members.where((m) => !m.isUser).toList();

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
      _startLiveSimulation();
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

  void _initMembers({required bool isHost, double userLat = 22.5958, double userLng = 88.3725}) {
    _members.clear();
    final user = AuthService.instance.currentUserModel;
    final userName = user?.displayName ?? 'You';

    // Local user member
    _members.add(
      SquadMember(
        id: user?.uid ?? 'user_self',
        name: '$userName (You)',
        latitude: userLat,
        longitude: userLng,
        status: isHost ? 'Squad Host • Active' : 'Joined • Active',
        lastSeen: DateTime.now(),
        isHost: isHost,
        isUser: true,
        batteryLevel: 92,
        avatarColorHex: 0xFFD32F2F, // Durga crimson
      ),
    );

    // Realistic companions hopping nearby pandals in North/Central Kolkata
    _members.addAll([
      SquadMember(
        id: 'member_priya',
        name: 'Priya Sen',
        latitude: userLat + 0.0042, // ~450m North near Bagbazar
        longitude: userLng - 0.0035,
        status: 'Near Bagbazar Sarbojanin',
        lastSeen: DateTime.now().subtract(const Duration(seconds: 14)),
        isHost: !isHost,
        batteryLevel: 84,
        avatarColorHex: 0xFFFFB300, // Amber Gold
      ),
      SquadMember(
        id: 'member_rohan',
        name: 'Rohan Das',
        latitude: userLat - 0.0031, // ~340m South towards Hatibagan
        longitude: userLng + 0.0022,
        status: 'In Hatibagan Bhog Queue',
        lastSeen: DateTime.now().subtract(const Duration(seconds: 4)),
        batteryLevel: 68,
        avatarColorHex: 0xFF00E676, // Emerald Green
      ),
      SquadMember(
        id: 'member_anirban',
        name: 'Anirban M.',
        latitude: userLat + 0.0018, // ~220m West towards Kumartuli
        longitude: userLng - 0.0048,
        status: 'Walking along Kumartuli Lane',
        lastSeen: DateTime.now().subtract(const Duration(seconds: 28)),
        batteryLevel: 95,
        avatarColorHex: 0xFF00E5FF, // Electric Cyan
      ),
    ]);
  }

  /// Create a brand new hopping squad
  void createSquad(String name, String meetup, [LatLng? meetupCoords]) {
    final code = 'PUJA${100 + _random.nextInt(900)}';
    _squadCode = code;
    _squadName = name.trim().isEmpty ? 'My Puja Squad' : name.trim();
    _meetupPointName = meetup.trim().isEmpty ? 'Main Entrance Gate' : meetup.trim();
    if (meetupCoords != null) {
      _meetupPointCoords = meetupCoords;
    }
    _initMembers(isHost: true);
    _persistState();
    _startLiveSimulation();
    notifyListeners();
  }

  /// Join an existing squad by invite code
  void joinSquad(String code, [LatLng? initialCoords]) {
    final cleanCode = code.trim().toUpperCase();
    _squadCode = cleanCode;
    _squadName = 'Squad $cleanCode';
    _meetupPointName = 'Designated Meet-up Landmark';
    final lat = initialCoords?.latitude ?? 22.5958;
    final lng = initialCoords?.longitude ?? 88.3725;
    _initMembers(isHost: false, userLat: lat, userLng: lng);
    _persistState();
    _startLiveSimulation();
    notifyListeners();
  }

  /// Leave the current squad and clear members
  void leaveSquad() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _squadCode = null;
    _squadName = null;
    _focusedMemberId = null;
    _members.clear();
    _persistState();
    notifyListeners();
  }

  /// Update the current user's GPS coordinates
  void updateUserLocation(double lat, double lng) {
    if (!_isSharingLocation) return;
    final idx = _members.indexWhere((m) => m.isUser);
    if (idx != -1) {
      _members[idx] = _members[idx].copyWith(
        latitude: lat,
        longitude: lng,
        lastSeen: DateTime.now(),
      );
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
    notifyListeners();
  }

  /// Toggle battery saver mode
  void toggleBatterySaver(bool val) {
    _batterySaver = val;
    _restartSimulationTimer();
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

  void _restartSimulationTimer() {
    _simulationTimer?.cancel();
    _startLiveSimulation();
  }

  /// Simulates realistic companion movements along Kolkata streets
  void _startLiveSimulation() {
    if (_simulationTimer != null) return;
    final interval = _batterySaver
        ? const Duration(seconds: 12)
        : const Duration(seconds: 5);

    _simulationTimer = Timer.periodic(interval, (_) {
      if (_members.isEmpty) return;

      bool changed = false;
      for (int i = 0; i < _members.length; i++) {
        if (!_members[i].isUser) {
          // Micro pedestrian step: ±0.00010 to ±0.00018 degrees (~10-18m)
          final dLat = (_random.nextDouble() - 0.5) * 0.0003;
          final dLng = (_random.nextDouble() - 0.5) * 0.0003;
          _members[i] = _members[i].copyWith(
            latitude: _members[i].latitude + dLat,
            longitude: _members[i].longitude + dLng,
            lastSeen: DateTime.now(),
          );
          changed = true;
        }
      }

      if (changed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
