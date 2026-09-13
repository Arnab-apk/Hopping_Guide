import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/pandal.dart';
import '../utils/constants.dart';
import 'pandal_repository.dart';

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

  Future<List<Pandal>> _load() async {
    if (_globalCache != null) return _globalCache!;
    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final parsed = await compute(_parsePandalsIsolate, jsonStr);
      _globalCache = parsed;
      return _globalCache!;
    } catch (e) {
      // Fallback empty list if asset missing
      return [];
    }
  }

  @override
  Future<List<Pandal>> all() => _load();

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
}
