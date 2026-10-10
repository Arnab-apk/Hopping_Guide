import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// Bundled OSM track sections; missing mapping stays an explicit estimate.
class TransitGeometry {
  static Future<Map<String, List<LatLng>>>? _data;
  static Future<Map<String, List<LatLng>>> _load() => _data ??= () async {
    try {
      final json = jsonDecode(
        await rootBundle.loadString('assets/data/transit_track_shapes.json'),
      ) as Map<String, dynamic>;
      return (json['shapes'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map(
                (p) =>
                    LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()),
              )
              .toList(),
        ),
      );
    } catch (_) {
      return <String, List<LatLng>>{};
    }
  }();

  static Future<List<LatLng>?> section(
    String service,
    String from,
    String to,
  ) async {
    final data = await _load();
    final forward = data['$service|$from|$to'];
    if (forward != null) return forward;
    return data['$service|$to|$from']?.reversed.toList();
  }
}
