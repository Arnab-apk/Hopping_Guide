import 'package:latlong2/latlong.dart';

/// Represents a Railway or Metro Station entity in the Greater Kolkata region.
class Station {
  const Station({
    required this.id,
    required this.name,
    this.nameBn,
    this.code,
    required this.kind,
    required this.lat,
    required this.lon,
    this.network,
    this.lines = const [],
    this.entrances = const [],
  });

  final String id;
  final String name;
  final String? nameBn;
  final String? code;
  final String kind; // 'rail' | 'metro'
  final double lat;
  final double lon;
  final String? network;
  final List<String> lines;
  final List<Map<String, dynamic>> entrances;

  bool get isRail => kind == 'rail';
  bool get isMetro => kind == 'metro';

  String get displayName => (code != null && code!.isNotEmpty && isRail) ? '$name ($code)' : name;
  String get fullDisplayName => (nameBn != null && nameBn!.isNotEmpty) ? '$displayName • $nameBn' : displayName;

  LatLng toLatLng() => LatLng(lat, lon);

  factory Station.fromFeature(Map<String, dynamic> f) {
    final p = (f['properties'] as Map<String, dynamic>?) ?? {};
    final geom = (f['geometry'] as Map<String, dynamic>?) ?? {};
    final c = (geom['coordinates'] as List?) ?? [0.0, 0.0];

    final linesRaw = p['lines'];
    final linesList = linesRaw is List ? linesRaw.map((e) => e.toString()).toList() : <String>[];

    final entrancesRaw = p['entrances'];
    final entrancesList = entrancesRaw is List
        ? entrancesRaw.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    return Station(
      id: f['id']?.toString() ?? p['id']?.toString() ?? '',
      name: p['name']?.toString() ?? '',
      nameBn: p['name_bn']?.toString(),
      code: p['code']?.toString(),
      kind: p['kind']?.toString() ?? 'rail',
      lat: (c.length > 1 ? (c[1] as num).toDouble() : (p['lat'] as num?)?.toDouble() ?? 0.0),
      lon: (c.isNotEmpty ? (c[0] as num).toDouble() : (p['lon'] as num?)?.toDouble() ?? 0.0),
      network: p['network']?.toString(),
      lines: linesList,
      entrances: entrancesList,
    );
  }

  Map<String, dynamic> toFeature() => {
        'type': 'Feature',
        'id': id,
        'geometry': {
          'type': 'Point',
          'coordinates': [lon, lat],
        },
        'properties': {
          'id': id,
          'name': name,
          'name_bn': nameBn,
          'code': code,
          'kind': kind,
          'lat': lat,
          'lon': lon,
          'network': network,
          'lines': lines,
          'entrances': entrances,
        },
      };
}

/// Lightweight reference embedded into Pandal records for nearest station walks
class NearestStationInfo {
  const NearestStationInfo({
    required this.id,
    required this.name,
    this.nameBn,
    this.code,
    required this.kind,
    required this.distanceM,
  });

  final String id;
  final String name;
  final String? nameBn;
  final String? code;
  final String kind;
  final int distanceM;

  bool get isRail => kind == 'rail';
  bool get isMetro => kind == 'metro';

  factory NearestStationInfo.fromMap(Map<String, dynamic> m) {
    return NearestStationInfo(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      nameBn: m['name_bn']?.toString(),
      code: m['code']?.toString(),
      kind: m['kind']?.toString() ?? 'rail',
      distanceM: (m['distance_m'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'name_bn': nameBn,
        'code': code,
        'kind': kind,
        'distance_m': distanceM,
      };
}
