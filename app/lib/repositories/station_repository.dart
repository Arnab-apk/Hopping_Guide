import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../models/station.dart';
import '../utils/haversine.dart';

List<Station> _parseStationsIsolate(String jsonStr) {
  final Map<String, dynamic> root = json.decode(jsonStr) as Map<String, dynamic>;
  final features = (root['features'] as List?) ?? [];
  return features
      .whereType<Map<String, dynamic>>()
      .map((f) => Station.fromFeature(f))
      .toList();
}

/// Offline-first repository that loads railway and metro stations from bundled GeoJSON asset.
class StationRepository {
  StationRepository({this.assetPath = 'assets/data/stations.geojson'});

  static final StationRepository instance = StationRepository();

  final String assetPath;
  List<Station> _stations = [];
  bool _isLoaded = false;
  Future<void>? _inFlightLoad;

  bool get isLoaded => _isLoaded;
  List<Station> get all => List.unmodifiable(_stations);
  List<Station> get railStations => _stations.where((s) => s.isRail).toList();
  List<Station> get metroStations => _stations.where((s) => s.isMetro).toList();

  /// Loads and parses the stations GeoJSON asset into memory.
  Future<List<Station>> load() async {
    if (_isLoaded) return _stations;
    if (_inFlightLoad != null) {
      await _inFlightLoad;
      return _stations;
    }

    _inFlightLoad = () async {
      try {
        final jsonStr = await rootBundle.loadString(assetPath);
        _stations = await compute(_parseStationsIsolate, jsonStr);
        _isLoaded = true;
      } catch (e) {
        debugPrint('[StationRepository] Failed to load $assetPath: $e');
        _stations = [];
      } finally {
        _inFlightLoad = null;
      }
    }();

    await _inFlightLoad;
    return _stations;
  }

  /// Synchronously or asynchronously ensures stations are ready.
  Future<List<Station>> allStations() async {
    if (!_isLoaded) await load();
    return _stations;
  }

  /// Search stations by English name, Bengali name, or IRCTC/Metro code.
  List<Station> search(String query) {
    if (query.trim().isEmpty) return _stations;
    final q = query.trim().toLowerCase();
    return _stations.where((s) {
      final name = s.name.toLowerCase();
      final nameBn = s.nameBn?.toLowerCase() ?? '';
      final code = s.code?.toLowerCase() ?? '';
      final network = s.network?.toLowerCase() ?? '';
      return name.contains(q) ||
          nameBn.contains(q) ||
          code == q ||
          code.contains(q) ||
          network.contains(q);
    }).toList();
  }

  /// Lookup a station by unique identifier or station code (e.g. HWH, SDAH).
  Station? findById(String idOrCode) {
    final clean = idOrCode.trim().toLowerCase();
    for (final s in _stations) {
      if (s.id.toLowerCase() == clean || (s.code != null && s.code!.toLowerCase() == clean)) {
        return s;
      }
    }
    return null;
  }

  /// Lookup a station by official IRCTC or Metro code (e.g. HWH, SDAH, KOAA).
  Station? findByCode(String code) {
    final clean = code.trim().toLowerCase();
    for (final s in _stations) {
      if (s.code != null && s.code!.toLowerCase() == clean) {
        return s;
      }
    }
    return null;
  }

  /// Returns nearest stations to a given geographic point sorted by walking distance.
  List<Station> getNearest(
    LatLng location, {
    int limit = 5,
    String? kind, // 'rail' or 'metro' or null for all
  }) {
    var candidates = _stations;
    if (kind != null) {
      candidates = candidates.where((s) => s.kind == kind).toList();
    }
    final sorted = List<Station>.from(candidates)
      ..sort((a, b) {
        final distA = haversineMeters(location.latitude, location.longitude, a.lat, a.lon);
        final distB = haversineMeters(location.latitude, location.longitude, b.lat, b.lon);
        return distA.compareTo(distB);
      });
    return sorted.take(limit).toList();
  }
}
