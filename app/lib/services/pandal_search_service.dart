import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../utils/constants.dart';
import '../utils/haversine.dart';

/// Representation of an auto-complete search result with relevance scoring and highlight spans
class PandalSearchResult {
  const PandalSearchResult({
    required this.pandal,
    required this.score,
    required this.matchedField,
    required this.matchedText,
    required this.nameHighlightSpans,
    this.distanceMeters,
  });

  final Pandal pandal;
  final double score;
  final String matchedField;
  final String matchedText;
  final List<TextSpan> nameHighlightSpans;
  final double? distanceMeters;
}

/// Service providing intelligent keyword matching, transliteration normalization,
/// relevance scoring, and auto-complete suggestions for pandals.
class PandalSearchService {
  static final PandalSearchService instance = PandalSearchService._();
  PandalSearchService._();

  // In-memory cache of recent search queries (up to 8)
  final List<String> _recentSearches = [
    'Ekdalia Evergreen',
    'Bagbazar Sarbojanin',
    'Sreebhumi',
    'College Square',
    'Suruchi Sangha',
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

  /// Normalizes Bengali / English transliterations and common variations
  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('sarbojanin', 'sarbojanin')
        .replaceAll('sarbajanin', 'sarbojanin')
        .replaceAll('pujo', 'puja')
        .replaceAll('shreebhumi', 'sreebhumi')
        .replaceAll('shobhabazar', 'sovabazar')
        .replaceAll('sobhahazar', 'sovabazar')
        .replaceAll('kolkata', 'calcutta')
        .replaceAll('ballygunge', 'baliganj')
        .replaceAll('hatibagan', 'hatibagan')
        .replaceAll('mudiali', 'mudiali')
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Matches query keywords against pandal attributes and computes an auto-complete score.
  /// Higher score = more relevant.
  PandalSearchResult? scorePandal(
    Pandal pandal,
    String rawQuery, {
    double? userLat,
    double? userLng,
    TextStyle? normalStyle,
    TextStyle? highlightStyle,
  }) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return null;

    final normQuery = normalize(query);
    final queryTokens = normQuery.split(' ').where((t) => t.isNotEmpty).toList();
    if (queryTokens.isEmpty) return null;

    final normName = normalize(pandal.name);
    final normArea = normalize(pandal.area ?? '');
    final normRegion = normalize(pandal.region ?? '');
    final normZone = normalize(pandal.zone.label);
    final normMetro = normalize(pandal.nearestMetro ?? '');
    final normTheme = normalize(pandal.theme);
    final normSpecial = pandal.specialFeatures.map(normalize).join(' ');

    double score = 0.0;
    String matchedField = 'Name';
    String matchedText = pandal.name;

    // 1. Exact or prefix match on full name (highest priority)
    if (normName == normQuery) {
      score += 1200;
    } else if (normName.startsWith(normQuery)) {
      score += 800;
    } else if (normName.contains(normQuery)) {
      score += 450;
    }

    // 2. Token-by-token evaluation across fields
    int tokensMatched = 0;
    for (final token in queryTokens) {
      bool tokenMatched = false;

      // Name check
      final nameWords = normName.split(' ');
      for (final word in nameWords) {
        if (word == token) {
          score += 300;
          tokenMatched = true;
          break;
        } else if (word.startsWith(token)) {
          score += 200;
          tokenMatched = true;
          break;
        }
      }

      if (!tokenMatched && normName.contains(token)) {
        score += 150;
        tokenMatched = true;
      }

      // Metro check
      if (normMetro.contains(token)) {
        score += 120;
        tokenMatched = true;
        matchedField = 'Nearest Metro';
        matchedText = pandal.nearestMetro ?? '';
      }

      // Area & Region check
      if (normArea.contains(token) || normRegion.contains(token)) {
        score += 110;
        tokenMatched = true;
        if (matchedField == 'Name') {
          matchedField = 'Area';
          matchedText = pandal.area ?? '';
        }
      }

      // Zone check
      if (normZone.contains(token)) {
        score += 90;
        tokenMatched = true;
        if (matchedField == 'Name') {
          matchedField = 'Zone';
          matchedText = pandal.zone.label;
        }
      }

      // Theme & special features check
      if (normTheme.contains(token) || normSpecial.contains(token)) {
        score += 70;
        tokenMatched = true;
        if (matchedField == 'Name') {
          matchedField = 'Theme';
          matchedText = pandal.theme;
        }
      }

      if (tokenMatched) {
        tokensMatched++;
      }
    }

    // Require all query tokens to match at least one attribute for multi-word queries
    if (tokensMatched < queryTokens.length) {
      return null;
    }

    // 3. Proximity bonus (up to 80 points) if user coordinates available
    double? distMeters;
    if (userLat != null && userLng != null) {
      distMeters = haversineMeters(userLat, userLng, pandal.lat, pandal.lng);
      // Give closer pandals (within 15km) a gentle ranking boost
      final distKm = distMeters / 1000.0;
      final proximityScore = math.max(0.0, (15.0 - distKm) * 5.0);
      score += proximityScore;
    }

    // 4. Rating slight tie-breaker
    if (pandal.rating != null) {
      score += (pandal.rating! * 4.0);
    }

    // Generate highlight spans for the pandal name
    final spans = buildHighlightSpans(
      text: pandal.name,
      query: query,
      normalStyle: normalStyle,
      highlightStyle: highlightStyle,
    );

    return PandalSearchResult(
      pandal: pandal,
      score: score,
      matchedField: matchedField,
      matchedText: matchedText,
      nameHighlightSpans: spans,
      distanceMeters: distMeters,
    );
  }

  /// Fast auto-complete suggestions: returns top [limit] matches sorted by score descending.
  List<PandalSearchResult> getAutoCompleteSuggestions(
    String query,
    List<Pandal> pandals, {
    int limit = 6,
    double? userLat,
    double? userLng,
    TextStyle? normalStyle,
    TextStyle? highlightStyle,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final results = <PandalSearchResult>[];
    for (final p in pandals) {
      final res = scorePandal(
        p,
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

    results.sort((a, b) => b.score.compareTo(a.score));
    if (results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }

  /// Search pandals matching [query], sorted by relevance score descending.
  List<PandalSearchResult> searchPandals(
    String query,
    List<Pandal> pandals, {
    double? userLat,
    double? userLng,
    TextStyle? normalStyle,
    TextStyle? highlightStyle,
  }) {
    return getAutoCompleteSuggestions(
      query,
      pandals,
      limit: 1000,
      userLat: userLat,
      userLng: userLng,
      normalStyle: normalStyle,
      highlightStyle: highlightStyle,
    );
  }

  /// Builds a [List<TextSpan>] where any substring in [text] that matches [query]
  /// or its constituent tokens is highlighted with [highlightStyle].
  static List<TextSpan> buildHighlightSpans({
    required String text,
    required String query,
    TextStyle? normalStyle,
    TextStyle? highlightStyle,
  }) {
    final effectiveNormal = normalStyle ?? const TextStyle(color: Colors.white, fontSize: 14);
    final effectiveHighlight = highlightStyle ??
        const TextStyle(
          color: PujaColors.festivalGold,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        );

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return [TextSpan(text: text, style: effectiveNormal)];
    }

    final lowerText = text.toLowerCase();
    final tokens = trimmed.split(' ').where((t) => t.isNotEmpty).toList();

    // Mark matched intervals [start, end)
    final intervals = <_Interval>[];
    for (final token in tokens) {
      int startIdx = 0;
      while (startIdx < lowerText.length) {
        final found = lowerText.indexOf(token, startIdx);
        if (found == -1) break;
        intervals.add(_Interval(found, found + token.length));
        startIdx = found + token.length;
      }
    }

    if (intervals.isEmpty) {
      return [TextSpan(text: text, style: effectiveNormal)];
    }

    // Merge overlapping intervals
    intervals.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_Interval>[];
    var cur = intervals.first;
    for (int i = 1; i < intervals.length; i++) {
      final next = intervals[i];
      if (next.start <= cur.end) {
        cur = _Interval(cur.start, math.max(cur.end, next.end));
      } else {
        merged.add(cur);
        cur = next;
      }
    }
    merged.add(cur);

    // Build the spans
    final spans = <TextSpan>[];
    int cursor = 0;
    for (final interval in merged) {
      if (interval.start > cursor) {
        spans.add(TextSpan(
          text: text.substring(cursor, interval.start),
          style: effectiveNormal,
        ));
      }
      spans.add(TextSpan(
        text: text.substring(interval.start, interval.end),
        style: effectiveHighlight,
      ));
      cursor = interval.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(
        text: text.substring(cursor),
        style: effectiveNormal,
      ));
    }

    return spans;
  }
}

class _Interval {
  const _Interval(this.start, this.end);
  final int start;
  final int end;
}
