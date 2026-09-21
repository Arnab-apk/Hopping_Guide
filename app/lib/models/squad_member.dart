import 'package:flutter/material.dart';

enum MemberMarkerState {
  fresh, // 🟢 Online + sharing (< 15s)
  stale, // 🟡 Online + location stale (15–60s)
  old, // ⚫ Stale location (> 60s)
  notSharing, // ⚫ Online + not sharing
  offline, // ⚪ Offline
}

/// Model representing a member of a Durga Puja hopping squad/group.
/// Holds real-time GPS coordinates, status, role, and battery indicators
/// for rendering on the live map and in the squad directory.
class SquadMember {
  const SquadMember({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.lastSeen,
    this.photoUrl,
    this.phoneNumber,
    this.isHost = false,
    this.isUser = false,
    this.shareLocation = true,
    this.isOnline = true,
    this.batteryLevel = 90,
    this.avatarColorHex = 0xFFFFB300, // Festival gold default
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime lastSeen;
  final String? photoUrl;
  final String? phoneNumber;
  final bool isHost;
  final bool isUser;
  final bool shareLocation;
  final bool isOnline;
  final int batteryLevel;
  final int avatarColorHex;

  Color get avatarColor => Color(avatarColorHex);

  bool get hasPhone => phoneNumber != null && phoneNumber!.trim().isNotEmpty;

  Duration get ageSinceLastSeen => DateTime.now().difference(lastSeen);

  MemberMarkerState get markerState {
    if (!isOnline) return MemberMarkerState.offline;
    if (!shareLocation) return MemberMarkerState.notSharing;
    final sec = ageSinceLastSeen.inSeconds;
    if (sec < 15) return MemberMarkerState.fresh;
    if (sec <= 60) return MemberMarkerState.stale;
    return MemberMarkerState.old;
  }

  String get markerStateDot {
    switch (markerState) {
      case MemberMarkerState.fresh:
        return '🟢';
      case MemberMarkerState.stale:
        return '🟡';
      case MemberMarkerState.notSharing:
      case MemberMarkerState.old:
        return '⚫';
      case MemberMarkerState.offline:
        return '⚪';
    }
  }

  String get lastSeenText {
    final diff = ageSinceLastSeen;
    if (diff.inSeconds < 15) return 'Live now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'M';
  }

  SquadMember copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? status,
    DateTime? lastSeen,
    String? photoUrl,
    String? phoneNumber,
    bool? isHost,
    bool? isUser,
    bool? shareLocation,
    bool? isOnline,
    int? batteryLevel,
    int? avatarColorHex,
  }) {
    return SquadMember(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isHost: isHost ?? this.isHost,
      isUser: isUser ?? this.isUser,
      shareLocation: shareLocation ?? this.shareLocation,
      isOnline: isOnline ?? this.isOnline,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      avatarColorHex: avatarColorHex ?? this.avatarColorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': latitude,
        'lng': longitude,
        'status': status,
        'photo_url': photoUrl,
        'phone_number': phoneNumber,
        'is_host': isHost,
        'is_user': isUser,
        'share_location': shareLocation,
        'is_online': isOnline,
        'battery': batteryLevel,
        'batteryLevel': batteryLevel,
        'color': avatarColorHex,
        'last_seen': lastSeen.millisecondsSinceEpoch,
      };

  factory SquadMember.fromJson(Map<String, dynamic> json) {
    return SquadMember(
      id: json['id'] as String? ?? json['user_id'] as String? ?? 'member',
      name: json['name'] as String? ?? json['display_name'] as String? ?? 'Hopper',
      latitude: (json['lat'] as num?)?.toDouble() ?? (json['latitude'] as num?)?.toDouble() ?? 22.5958,
      longitude: (json['lng'] as num?)?.toDouble() ?? (json['longitude'] as num?)?.toDouble() ?? 88.3725,
      status: json['status'] as String? ?? 'Active • Pandal Hopping',
      photoUrl: json['photo_url'] as String? ?? json['photoUrl'] as String? ?? json['avatar_url'] as String?,
      phoneNumber: json['phone_number'] as String? ?? json['phoneNumber'] as String?,
      isHost: json['is_host'] as bool? ?? (json['role'] == 'host'),
      isUser: json['is_user'] as bool? ?? false,
      shareLocation: json['share_location'] as bool? ?? true,
      isOnline: json['is_online'] as bool? ?? true,
      batteryLevel: (json['battery'] as num?)?.toInt() ??
          (json['batteryLevel'] as num?)?.toInt() ??
          (json['battery_level'] as num?)?.toInt() ??
          85,
      avatarColorHex: (json['color'] as num?)?.toInt() ?? 0xFFFFB300,
      lastSeen: json['last_seen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_seen'] as int)
          : (json['last_seen_at'] != null
              ? DateTime.tryParse(json['last_seen_at'] as String) ?? DateTime.now()
              : DateTime.now()),
    );
  }
}
