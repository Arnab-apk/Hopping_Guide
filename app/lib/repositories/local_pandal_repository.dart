import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/pandal.dart';
import '../models/place.dart';
import '../utils/constants.dart';
import 'pandal_repository.dart';
import 'supplementary_repository.dart';

List<Pandal> _parsePandalsIsolate(String jsonStr) {
  final List<dynamic> rawList = json.decode(jsonStr) as List<dynamic>;
  return rawList.map((item) {
    final map = item as Map<String, dynamic>;
    final id = map['id']?.toString() ?? '';
    return Pandal.fromMap(id, map);
  }).toList();
}

/// Offline-first repository that loads the curated pandals from bundled asset JSON.
/// Parses in a background worker isolate and caches in static memory to guarantee
/// zero UI thread hitches or frame skips across screens.
class LocalAssetPandalRepository implements PandalRepository {
  LocalAssetPandalRepository({this.assetPath = 'assets/data/pandals.json'});

  final String assetPath;
  static List<Pandal>? _globalCache;
  static Future<List<Pandal>>? _inFlightFuture;

  Future<List<Pandal>> _load() async {
    if (_globalCache != null) return _globalCache!;
    if (_inFlightFuture != null) return _inFlightFuture!;

    _inFlightFuture = () async {
      try {
        final jsonStr = await rootBundle.loadString(assetPath);
        final parsed = await compute(_parsePandalsIsolate, jsonStr);
        _globalCache = parsed;
        return _globalCache!;
      } catch (e) {
        // Fallback empty list if asset missing
        return <Pandal>[];
      } finally {
        _inFlightFuture = null;
      }
    }();

    return _inFlightFuture!;
  }

  @override
  Future<List<Pandal>> all() => _load();

  /// Convenient alias for warming up and preloading all pandals
  Future<List<Pandal>> loadAll() => all();

  @override
  Future<List<Pandal>> byZone(KolkataZone zone) async {
    final list = await _load();
    return list.where((p) => p.zone == zone).toList();
  }

  @override
  Future<Pandal?> byId(String id) async {
    final list = await _load();
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Pandal>> watchAll() async* {
    yield await _load();
  }

  @override
  Future<List<Place>> getPlaces({
    required PlaceCategory category,
    KolkataZone? zoneFilter,
    String? searchQuery,
  }) async {
    if (category == PlaceCategory.pandal) {
      final pandals = zoneFilter != null ? await byZone(zoneFilter) : await all();
      var places = pandals.map(Place.fromPandal).toList();
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        places = places.where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.theme?.toLowerCase().contains(q) ?? false) ||
            (p.area?.toLowerCase().contains(q) ?? false)).toList();
      }
      return places;
    } else {
      final foodSpots = await SupplementaryRepository().getFoodSpots();
      final pandals = await all();
      var places = foodSpots.map((f) {
        final matchingPandal = pandals.cast<Pandal?>().firstWhere(
          (p) => p != null && (p.name.toLowerCase() == f.nearbyPandal.toLowerCase() ||
                 f.nearbyPandal.toLowerCase().contains(p.name.toLowerCase()) ||
                 p.name.toLowerCase().contains(f.nearbyPandal.toLowerCase())),
          orElse: () => null,
        );
        return Place.fromFoodSpot(f, zone: matchingPandal?.zone);
      }).toList();

      if (zoneFilter != null) {
        places = places.where((p) => p.zone == zoneFilter).toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        places = places.where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.type?.toLowerCase().contains(q) ?? false) ||
            (p.mustTry?.toLowerCase().contains(q) ?? false) ||
            (p.nearbyPandal?.toLowerCase().contains(q) ?? false)).toList();
      }
      return places;
    }
  }
}
