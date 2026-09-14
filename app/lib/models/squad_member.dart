import 'dart:ui';

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
    this.isHost = false,
    this.isUser = false,
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
  final bool isHost;
  final bool isUser;
  final int batteryLevel;
  final int avatarColorHex;

  Color get avatarColor => Color(avatarColorHex);

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
    bool? isHost,
    bool? isUser,
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
      isHost: isHost ?? this.isHost,
      isUser: isUser ?? this.isUser,
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
        'is_host': isHost,
        'is_user': isUser,
        'battery': batteryLevel,
        'color': avatarColorHex,
        'last_seen': lastSeen.millisecondsSinceEpoch,
      };

  factory SquadMember.fromJson(Map<String, dynamic> json) {
    return SquadMember(
      id: json['id'] as String? ?? 'member',
      name: json['name'] as String? ?? 'Hopper',
      latitude: (json['lat'] as num?)?.toDouble() ?? 22.5958,
      longitude: (json['lng'] as num?)?.toDouble() ?? 88.3725,
      status: json['status'] as String? ?? 'Active • Pandal Hopping',
      photoUrl: json['photo_url'] as String? ?? json['photoUrl'] as String?,
      isHost: json['is_host'] as bool? ?? false,
      isUser: json['is_user'] as bool? ?? false,
      batteryLevel: (json['battery'] as num?)?.toInt() ?? 85,
      avatarColorHex: (json['color'] as num?)?.toInt() ?? 0xFFFFB300,
      lastSeen: json['last_seen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_seen'] as int)
          : DateTime.now(),
    );
  }
}
