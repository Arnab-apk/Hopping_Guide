import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/metro_station.dart';
import '../models/pandal.dart';
import '../repositories/metro_repository.dart';
import '../repositories/supplementary_repository.dart';
import '../utils/constants.dart';
import '../utils/haversine.dart';
import 'pandal_search_service.dart';

/// Categories of search entities in the Universal Omni-Search
enum OmniCategory {
  all(label: 'All', icon: Icons.auto_awesome_rounded),
  pandals(label: 'Pandals', icon: Icons.temple_hindu_rounded),
  metro(label: 'Metro', icon: Icons.subway_rounded),
  food(label: 'Food', icon: Icons.restaurant_rounded);

  const OmniCategory({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

/// Type of matched search entity
enum OmniResultType {
  pandal,
  metro,
  food,
}

/// Unified auto-complete result entity returned by [OmniSearchService]
class OmniSearchResult {
  const OmniSearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.score,
    required this.highlightSpans,
    this.matchedField = 'Name',
    this.distanceMeters,
    this.pandal,
    this.metroStation,
    this.foodSpot,
    this.badgeText,
    this.badgeColor,
    this.rating,
  });

  final OmniResultType type;
  final String id;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final double score;
  final List<TextSpan> highlightSpans;
  final String matchedField;
  final double? distanceMeters;
  final Pandal? pandal;
  final MetroStation? metroStation;
  final FoodSpot? foodSpot;
  final String? badgeText;
  final Color? badgeColor;
  final double? rating;

  IconData get icon {
    switch (type) {
      case OmniResultType.pandal:
        return Icons.temple_hindu_rounded;
      case OmniResultType.metro:
        return Icons.subway_rounded;
      case OmniResultType.food:
        return Icons.restaurant_rounded;
    }
  }

  Color get accentColor {
    switch (type) {
      case OmniResultType.pandal:
        return PujaColors.durgaRed;
      case OmniResultType.metro:
        return metroStation?.line.color ?? const Color(0xFF1976D2);
      case OmniResultType.food:
        return const Color(0xFFFF9100); // warm culinary amber
    }
  }
}

/// Unified system-wide search engine (inspired by Rofi / Spotlight / Arch Linux Omachi)
/// Searches simultaneously across Pandals, Metro Stations, and Culinary Spots.
class OmniSearchService {
  OmniSearchService._();
  static final OmniSearchService instance = OmniSearchService._();

  // In-memory cache of recent search keywords
  final List<String> _recentSearches = [
    'Ekdalia Evergreen',
    'Shyambazar Metro',
    'Golbari',
    'Mitra Cafe',
    'College Square',
    'Esplanade',
  ];

  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  void addRecentSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _recentSearches.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > 8) {
      _recentSearches.removeLast();
    }
  }

  void clearRecentSearches() {
    _recentSearches.clear();
  }

  /// Evaluates and scores a Metro Station against a search query
  OmniSearchResult? scoreMetroStation(
    MetroStation station,
    String rawQuery, {
    double? userLat,
    double? userLng,
    TextStyle? normalStyle,
    TextStyle? highlightStyle,
  }) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return null;

    final normQuery = PandalSearchService.normalize(query);
    final queryTokens = normQuery.split(' ').where((t) => t.isNotEmpty).toList();
    if (queryTokens.isEmpty) return null;

    final normName = PandalSearchService.normalize(station.name);
    final normLine = PandalSearchService.normalize(station.line.label);
    final normCorridor = PandalSearchService.normalize(station.line.corridor);
    final normAliases = station.aliases.map(PandalSearchService.normalize).toList();
    final normNearby = station.popularPandalsNearby
        .map(PandalSearchService.normalize)
        .join(' ');

    double score = 0.0;
    String matchedField = 'Name';

    // 1. Exact or prefix match on station name or aliases
    if (normName == normQuery || normAliases.contains(normQuery)) {
      score += 1300;
    } else if (normName.startsWith(normQuery) || normAliases.any((a) => a.startsWith(normQuery))) {
      score += 850;
    } else if (normName.contains(normQuery) || normAliases.any((a) => a.contains(normQuery))) {
      score += 480;
    }

    // 2. Token evaluation across line & nearby pandals
    int tokensMatched = 0;
    for (final token in queryTokens) {
      bool tokenMatched = false;

      // Word match in name
      final nameWords = normName.split(' ');
      for (final w in nameWords) {
        if (w == token) {
          score += 320;
          tokenMatched = true;
          break;
        } else if (w.startsWith(token)) {
          score += 220;
          tokenMatched = true;
          break;
        }
      }

      if (!tokenMatched && normName.contains(token)) {
        score += 160;
        tokenMatched = true;
      }

      // Check "metro" keyword
      if (token == 'metro' || token == 'station') {
        score += 200;
        tokenMatched = true;
        matchedField = 'Metro System';
      }

      // Check line or corridor
      if (normLine.contains(token) || normCorridor.contains(token)) {
        score += 180;
        tokenMatched = true;
        matchedField = 'Metro Line';
      }

      // Check nearby famous pandals connected to this station
      if (normNearby.contains(token)) {
        score += 150;
        tokenMatched = true;
        matchedField = 'Nearby Pandal';
      }

      if (tokenMatched) tokensMatched++;
    }

    if (tokensMatched < queryTokens.length) {
      return null;
    }

    // Interchange bonus
    if (station.isInterchange) {
      score += 50;
    }

    // Distance bonus
    double? distMeters;
    if (userLat != null && userLng != null) {
      distMeters = haversineMeters(userLat, userLng, station.latitude, station.longitude);
      final distKm = distMeters / 1000.0;
      score += math.max(0.0, (15.0 - distKm) * 5.0);
    }

    final spans = PandalSearchService.buildHighlightSpans(
      text: station.name,
      query: query,
      normalStyle: normalStyle,
      highlightStyle: highlightStyle,
    );

    return OmniSearchResult(
      type: OmniResultType.metro,
      id: station.id,
      title: station.name,
      subtitle: station.subtitle,
      latitude: station.latitude,
      longitude: station.longitude,
      score: score,
      highlightSpans: spans,
      matchedField: matchedField,
      distanceMeters: distMeters,
      metroStation: station,
      badgeText: station.line.code.toUpperCase(),
      badgeColor: station.line.color,
    );
  }

  /// Evaluates and scores a Food Spot / Restaurant against a search query
  OmniSearchResult? scoreFoodSpot(
    FoodSpot spot,
    String rawQuery, {
    double? userLat,
    double? userLng,
    TextStyle? normalStyle,
    TextStyle? highlightStyle,
  }) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return null;

    final normQuery = PandalSearchService.normalize(query);
    final queryTokens = normQuery.split(' ').where((t) => t.isNotEmpty).toList();
    if (queryTokens.isEmpty) return null;

    final normName = PandalSearchService.normalize(spot.name);
    final normType = PandalSearchService.normalize(spot.type);
    final normMustTry = PandalSearchService.normalize(spot.mustTry ?? '');
    final normNearby = PandalSearchService.normalize(spot.nearbyPandal);

    double score = 0.0;
    String matchedField = 'Name';

    // 1. Exact or prefix match on name
    if (normName == normQuery) {
      score += 1250;
    } else if (normName.startsWith(normQuery)) {
      score += 820;
    } else if (normName.contains(normQuery)) {
      score += 460;
    }

    // 2. Token evaluation across cuisine, must-try items, and location
    int tokensMatched = 0;
    for (final token in queryTokens) {
      bool tokenMatched = false;

      final words = normName.split(' ');
      for (final w in words) {
        if (w == token) {
          score += 310;
          tokenMatched = true;
          break;
        } else if (w.startsWith(token)) {
          score += 210;
          tokenMatched = true;
          break;
        }
      }

      if (!tokenMatched && normName.contains(token)) {
        score += 150;
        tokenMatched = true;
      }

      // Check cuisine / type (e.g. Biryani, Rolls, Snacks, Sweets)
      if (normType.contains(token)) {
        score += 180;
        tokenMatched = true;
        matchedField = 'Cuisine';
      }

      // Check must-try specialty (e.g. Kosha Mangsho, Fish Fry, Kabiraji)
      if (normMustTry.contains(token)) {
        score += 190;
        tokenMatched = true;
        matchedField = 'Specialty';
      }

      // Check nearby pandal
      if (normNearby.contains(token)) {
        score += 140;
        tokenMatched = true;
        matchedField = 'Near Pandal';
      }

      // Food keywords
      if (token == 'food' || token == 'restaurant' || token == 'eat' || token == 'eating') {
        score += 120;
        tokenMatched = true;
        matchedField = 'Food Spot';
      }

      if (tokenMatched) tokensMatched++;
    }

    if (tokensMatched < queryTokens.length) {
      return null;
    }

    // Distance bonus
    double? distMeters;
    if (userLat != null && userLng != null) {
      distMeters = haversineMeters(userLat, userLng, spot.lat, spot.lng);
      final distKm = distMeters / 1000.0;
      score += math.max(0.0, (15.0 - distKm) * 5.0);
    }

    // Rating boost
    if (spot.rating != null) {
      score += (spot.rating! * 5.0);
    }

    final spans = PandalSearchService.buildHighlightSpans(
      text: spot.name,
      query: query,
      normalStyle: normalStyle,
      highlightStyle: highlightStyle,
    );

    final subtitleParts = <String>[];
    if (spot.mustTry != null && spot.mustTry!.isNotEmpty) {
      subtitleParts.add(spot.mustTry!);
    } else {
      subtitleParts.add(spot.type);
    }
    if (spot.nearbyPandal.isNotEmpty) {
      subtitleParts.add('Near ${spot.nearbyPandal}');
    }

    return OmniSearchResult(
      type: OmniResultType.food,
      id: spot.id,
      title: spot.name,
      subtitle: subtitleParts.join(' · '),
      latitude: spot.lat,
      longitude: spot.lng,
      score: score,
      highlightSpans: spans,
      matchedField: matchedField,
      distanceMeters: distMeters,
      foodSpot: spot,
      badgeText: spot.priceRange ?? 'FOOD',
      badgeColor: const Color(0xFFFF9100),
      rating: spot.rating,
    );
  }

  /// Converts a PandalSearchResult to an OmniSearchResult
  OmniSearchResult _fromPandalResult(PandalSearchResult res) {
    final p = res.pandal;
    final subtitleParts = <String>[p.zone.label];
    if (p.nearestMetro != null && p.nearestMetro!.isNotEmpty) {
      subtitleParts.add('🚇 ${p.nearestMetro}');
    }
    if (p.theme.isNotEmpty) {
      subtitleParts.add(p.theme);
    }

    return OmniSearchResult(
      type: OmniResultType.pandal,
      id: p.id,
      title: p.name,
      subtitle: subtitleParts.join(' · '),
      latitude: p.lat,
      longitude: p.lng,
      score: res.score,
      highlightSpans: res.nameHighlightSpans,
      matchedField: res.matchedField,
      distanceMeters: res.distanceMeters,
      pandal: p,
      badgeText: p.zone.shortLabel,
      badgeColor: PujaColors.durgaRed,
      rating: p.rating,
    );
  }

  /// Performs a universal query across all system entities:
  /// Pandals, Metro Stations, and Food Spots.
  List<OmniSearchResult> search({
    required String query,
    required List<Pandal> pandals,
    List<FoodSpot>? foodSpots,
    List<MetroStation>? metroStations,
    OmniCategory category = OmniCategory.all,
    int limit = 8,
    double? userLat,
    double? userLng,
    TextStyle? normalStyle,
    TextStyle? highlightStyle,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final stations = metroStations ?? MetroRepository.allStations;
    final results = <OmniSearchResult>[];

    // 1. Search Pandals
    if (category == OmniCategory.all || category == OmniCategory.pandals) {
      for (final p in pandals) {
        final res = PandalSearchService.instance.scorePandal(
          p,
          trimmed,
          userLat: userLat,
          userLng: userLng,
          normalStyle: normalStyle,
          highlightStyle: highlightStyle,
        );
        if (res != null) {
          results.add(_fromPandalResult(res));
        }
      }
    }

    // 2. Search Metro Stations
    if (category == OmniCategory.all || category == OmniCategory.metro) {
      for (final station in stations) {
        final res = scoreMetroStation(
          station,
          trimmed,
          userLat: userLat,
          userLng: userLng,
          normalStyle: normalStyle,
          highlightStyle: highlightStyle,
        );
        if (res != null) {
          results.add(res);
        }
      }
    }

    // 3. Search Food Spots
    if ((category == OmniCategory.all || category == OmniCategory.food) && foodSpots != null) {
      for (final spot in foodSpots) {
        final res = scoreFoodSpot(
          spot,
          trimmed,
          userLat: userLat,
          userLng: userLng,
          normalStyle: normalStyle,
          highlightStyle: highlightStyle,
        );
        if (res != null) {
          results.add(res);
        }
      }
    }

    // Sort by relevance score descending
    results.sort((a, b) => b.score.compareTo(a.score));

    if (results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }
}
