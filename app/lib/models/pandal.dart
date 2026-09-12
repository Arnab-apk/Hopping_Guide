import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/constants.dart';

/// Firestore collection: `pandals`
/// Mirrors the curated CSV schema (architecture doc section 3):
/// id, name, lat, lng, zone, theme, timings, image_url, description, nearest_metro
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
    this.nearestMetro,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  final KolkataZone zone;
  final String theme;
  final String timings;
  final String imageUrl;
  final String description;
  final String? nearestMetro;

  factory Pandal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Pandal(
      id: doc.id,
      name: d['name'] as String? ?? '',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      zone: _parseZone(d['zone'] as String?),
      theme: d['theme'] as String? ?? '',
      timings: d['timings'] as String? ?? '',
      imageUrl: d['image_url'] as String? ?? '',
      description: d['description'] as String? ?? '',
      nearestMetro: d['nearest_metro'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'lat': lat,
        'lng': lng,
        'zone': zone.name,
        'theme': theme,
        'timings': timings,
        'image_url': imageUrl,
        'description': description,
        'nearest_metro': nearestMetro,
      };

  static KolkataZone _parseZone(String? raw) {
    return KolkataZone.values.firstWhere(
      (z) => z.name == raw,
      orElse: () => KolkataZone.centralKolkata,
    );
  }
}
