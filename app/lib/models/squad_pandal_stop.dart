import '../models/pandal.dart';
import '../models/squad_member.dart';
import '../utils/constants.dart';

/// Represents a pandal chosen by squad/group members to visit together.
/// Supports member attribution, collaborative voting/likes, ordering,
/// and live hopping visit tracking.
class SquadPandalStop {
  const SquadPandalStop({
    required this.id,
    required this.name,
    required this.zone,
    required this.lat,
    required this.lng,
    this.area,
    this.theme = 'Durga Puja',
    this.imageUrl = '',
    this.rating,
    required this.suggestedBy,
    required this.suggestedByName,
    required this.addedAt,
    this.votes = const [],
    this.isVisited = false,
  });

  final String id;
  final String name;
  final String zone;
  final double lat;
  final double lng;
  final String? area;
  final String theme;
  final String imageUrl;
  final double? rating;
  final String suggestedBy;
  final String suggestedByName;
  final DateTime addedAt;
  final List<String> votes;
  final bool isVisited;

  String get pandalName => name;
  int get voteCount => votes.length;
  bool isVotedBy(String userId) => votes.contains(userId);

  /// Returns true if the current user (from auth) has voted for this pandal.
  bool get currentUserVoted {
    final currentUserId = SquadPandalStop._currentUserId;
    return currentUserId != null && votes.contains(currentUserId);
  }

  /// Static holder for current user ID (set by UI when needed)
  static String? _currentUserId;

  /// Set the current user ID for vote checking (call from UI)
  static void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  /// Get voter display names from squad members list
  List<String> getVoterNames(List<SquadMember> members) {
    return votes
        .map((voterId) => members.firstWhere(
              (m) => m.id == voterId,
              orElse: () => SquadMember(
                    id: voterId,
                    name: 'Unknown',
                    latitude: 0,
                    longitude: 0,
                    status: '',
                    lastSeen: DateTime.now(),
                    isUser: false,
                  ))
            .name
            .replaceAll(' (You)', ''))
        .toList();
  }

  /// Get voter member objects for avatar display
  List<SquadMember> getVoterMembers(List<SquadMember> members) {
    return votes
        .map((voterId) => members.cast<SquadMember?>().firstWhere(
              (m) => m?.id == voterId,
              orElse: () => null,
            ))
        .whereType<SquadMember>()
        .toList();
  }

  /// Check if suggested by current user
  bool get isSuggestedByCurrentUser {
    final currentUserId = SquadPandalStop._currentUserId;
    return currentUserId != null && suggestedBy == currentUserId;
  }

  SquadPandalStop copyWith({
    String? id,
    String? name,
    String? zone,
    double? lat,
    double? lng,
    String? area,
    String? theme,
    String? imageUrl,
    double? rating,
    String? suggestedBy,
    String? suggestedByName,
    DateTime? addedAt,
    List<String>? votes,
    bool? isVisited,
  }) {
    return SquadPandalStop(
      id: id ?? this.id,
      name: name ?? this.name,
      zone: zone ?? this.zone,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      area: area ?? this.area,
      theme: theme ?? this.theme,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      suggestedBy: suggestedBy ?? this.suggestedBy,
      suggestedByName: suggestedByName ?? this.suggestedByName,
      addedAt: addedAt ?? this.addedAt,
      votes: votes ?? this.votes,
      isVisited: isVisited ?? this.isVisited,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'zone': zone,
      'lat': lat,
      'lng': lng,
      'area': area,
      'theme': theme,
      'imageUrl': imageUrl,
      'rating': rating,
      'suggestedBy': suggestedBy,
      'suggestedByName': suggestedByName,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'votes': votes,
      'isVisited': isVisited,
    };
  }

  factory SquadPandalStop.fromJson(Map<String, dynamic> json) {
    return SquadPandalStop(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Pandal',
      zone: json['zone'] as String? ?? 'North Kolkata',
      lat: (json['lat'] as num?)?.toDouble() ?? 22.5726,
      lng: (json['lng'] as num?)?.toDouble() ?? 88.3639,
      area: json['area'] as String?,
      theme: json['theme'] as String? ?? 'Traditional',
      imageUrl: json['imageUrl'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble(),
      suggestedBy: json['suggestedBy'] as String? ?? '',
      suggestedByName: json['suggestedByName'] as String? ?? 'Companion',
      addedAt: json['addedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['addedAt'] as num).toInt())
          : DateTime.now(),
      votes: (json['votes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      isVisited: json['isVisited'] as bool? ?? false,
    );
  }

  factory SquadPandalStop.fromPandal(
    Pandal pandal, {
    required String suggestedBy,
    required String suggestedByName,
  }) {
    return SquadPandalStop(
      id: pandal.id,
      name: pandal.name,
      zone: pandal.zone.label,
      lat: pandal.lat,
      lng: pandal.lng,
      area: pandal.area,
      theme: pandal.theme,
      imageUrl: pandal.imageUrl,
      rating: pandal.rating,
      suggestedBy: suggestedBy,
      suggestedByName: suggestedByName,
      addedAt: DateTime.now(),
      votes: [suggestedBy],
      isVisited: false,
    );
  }

  Pandal toPandal() {
    KolkataZone kZone = KolkataZone.northKolkata;
    for (final z in KolkataZone.values) {
      if (z.label.toLowerCase() == zone.toLowerCase() ||
          z.shortLabel.toLowerCase() == zone.toLowerCase() ||
          z.name.toLowerCase() == zone.toLowerCase()) {
        kZone = z;
        break;
      }
    }
    return Pandal(
      id: id,
      name: name,
      lat: lat,
      lng: lng,
      zone: kZone,
      area: area,
      theme: theme,
      timings: 'Open 24 Hours',
      imageUrl: imageUrl,
      description: 'Squad chosen pandal for hopping',
      rating: rating,
    );
  }
}
