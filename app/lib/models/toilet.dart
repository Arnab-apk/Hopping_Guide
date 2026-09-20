/// A single public toilet entry from toilets.json
class ToiletEntry {
  const ToiletEntry({
    required this.id,
    required this.lat,
    required this.lng,
    required this.male,
    required this.female,
    required this.fee,
    required this.distM,
    this.name,
    this.access = 'public',
    this.source = 'osm',
  });

  final String id;
  final double lat;
  final double lng;
  final bool male;
  final bool female;
  final bool fee;
  final int distM;
  final String? name;
  final String access;
  final String source;

  String get displayName => name ?? 'Public Toilet';

  String get distLabel =>
      distM < 1000 ? '${distM}m away' : '${(distM / 1000).toStringAsFixed(1)}km away';

  String get genderLabel {
    if (male && female) return 'Male & Female';
    if (male) return 'Male only';
    if (female) return 'Female only';
    return 'Unspecified';
  }

  factory ToiletEntry.fromJson(Map<String, dynamic> json) => ToiletEntry(
        id: json['id'] as String? ?? '${json['lat']}_${json['lng']}',
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        male: json['male'] as bool? ?? true,
        female: json['female'] as bool? ?? true,
        fee: json['fee'] as bool? ?? false,
        distM: (json['distM'] as num?)?.toInt() ?? 0,
        name: json['name'] as String?,
        access: json['access'] as String? ?? 'public',
        source: json['source'] as String? ?? 'osm',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lng': lng,
        'male': male,
        'female': female,
        'fee': fee,
        'distM': distM,
        if (name != null) 'name': name,
        'access': access,
        'source': source,
      };
}

/// Toilet lookup result for one pandal
class PandalToilets {
  const PandalToilets({
    required this.pandalId,
    this.pandalName,
    this.nearestMale,
    this.nearestFemale,
    this.allNearby = const [],
  });

  final String pandalId;
  final String? pandalName;
  final ToiletEntry? nearestMale;
  final ToiletEntry? nearestFemale;
  final List<ToiletEntry> allNearby;

  bool get hasData => allNearby.isNotEmpty || nearestMale != null || nearestFemale != null;

  factory PandalToilets.fromJson(Map<String, dynamic> json) => PandalToilets(
        pandalId: json['pandalId'] as String,
        pandalName: json['pandalName'] as String?,
        nearestMale: json['nearestMale'] == null
            ? null
            : ToiletEntry.fromJson(json['nearestMale'] as Map<String, dynamic>),
        nearestFemale: json['nearestFemale'] == null
            ? null
            : ToiletEntry.fromJson(json['nearestFemale'] as Map<String, dynamic>),
        allNearby: ((json['allNearby'] as List<dynamic>?) ?? [])
            .map((e) => ToiletEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'pandalId': pandalId,
        if (pandalName != null) 'pandalName': pandalName,
        if (nearestMale != null) 'nearestMale': nearestMale!.toJson(),
        if (nearestFemale != null) 'nearestFemale': nearestFemale!.toJson(),
        'allNearby': allNearby.map((e) => e.toJson()).toList(),
      };
}
