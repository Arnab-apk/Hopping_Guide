import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/constants.dart';

/// Firestore collection: `pandals`
/// Matches the application schema (architecture doc section 3 and data/schema/):
/// id, name, lat, lng, zone, area, region, rating, theme, crowd_level,
/// timings, image_url, description, transport, nearest_metro, nearest_railway
class Pandal {
  Pandal({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.zone,
    required this.theme,
    required this.timings,
    required this.imageUrl,
    required this.description,
    this.area,
    this.region,
    this.rating,
    this.crowdLevel,
    this.nearestMetro,
    this.nearestMetroList = const [],
    this.nearestRailway,
    this.nearestRailwayList = const [],
    this.transport = const [],
    this.specialFeatures = const [],
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  final KolkataZone zone;
  final String? area;
  final String? region;
  final double? rating;
  final String theme;
  final String? crowdLevel;
  final String timings;
  final String imageUrl;
  final String description;
  final String? nearestMetro;
  final List<String> nearestMetroList;
  final String? nearestRailway;
  final List<String> nearestRailwayList;
  final List<String> transport;
  final List<String> specialFeatures;

  factory Pandal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Pandal.fromMap(doc.id, doc.data() ?? {});
  }

  factory Pandal.fromMap(String id, Map<String, dynamic> d) {
    return Pandal(
      id: id,
      name: d['name'] as String? ?? '',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      zone: _parseZone(d['zone'] as String?),
      area: d['area'] as String?,
      region: d['region'] as String?,
      rating: (d['rating'] as num?)?.toDouble(),
      theme: d['theme'] as String? ?? '',
      crowdLevel: d['crowd_level'] as String? ?? d['crowdLevel'] as String?,
      timings: d['timings'] as String? ?? '',
      imageUrl: d['image_url'] as String? ?? d['imageUrl'] as String? ?? '',
      description: d['description'] as String? ?? '',
      nearestMetro: d['nearest_metro'] as String? ?? d['nearestMetro'] as String?,
      nearestMetroList: _parseStringList(d['nearest_metro_list'] ?? d['nearestMetro']),
      nearestRailway: d['nearest_railway'] as String? ?? d['nearestRailway'] as String?,
      nearestRailwayList: _parseStringList(d['nearest_railway_list'] ?? d['nearestRailway']),
      transport: _parseStringList(d['transport']),
      specialFeatures: _parseStringList(d['special_features'] ?? d['specialFeatures']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'lat': lat,
        'lng': lng,
        'zone': zone.name,
        'area': area,
        'region': region,
        'rating': rating,
        'theme': theme,
        'crowd_level': crowdLevel,
        'timings': timings,
        'image_url': imageUrl,
        'description': description,
        'nearest_metro': nearestMetro,
        'nearest_metro_list': nearestMetroList,
        'nearest_railway': nearestRailway,
        'nearest_railway_list': nearestRailwayList,
        'transport': transport,
        'special_features': specialFeatures,
      };

  static KolkataZone _parseZone(String? raw) {
    if (raw == null) return KolkataZone.centralKolkata;
    return KolkataZone.values.firstWhere(
      (z) => z.name.toLowerCase() == raw.toLowerCase(),
      orElse: () => KolkataZone.centralKolkata,
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }
}
