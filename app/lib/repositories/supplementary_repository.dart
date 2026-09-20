import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/place_category.dart';
import '../models/toilet.dart';

class Helpline {
  const Helpline({required this.label, required this.number});
  final String label;
  final String number;

  factory Helpline.fromJson(Map<String, dynamic> json) => Helpline(
        label: json['label'] as String? ?? '',
        number: json['number'] as String? ?? '',
      );
}

class FoodSpot {
  const FoodSpot({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.nearbyPandal,
    this.rating,
    this.mustTry,
    this.priceRange,
    this.source,
  });

  final String id;
  final String name;
  final String type;
  final double lat;
  final double lng;
  final String nearbyPandal;
  final double? rating;
  final String? mustTry;
  final String? priceRange;
  final String? source;

  double get latitude => lat;
  double get longitude => lng;
  PlaceCategory get category => PlaceCategory.foodSpot;

  factory FoodSpot.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>? ?? {};
    return FoodSpot(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'Food',
      lat: (coords['lat'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (coords['lng'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble() ?? 0,
      nearbyPandal: json['nearbyPandal'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble(),
      mustTry: json['mustTry'] as String?,
      priceRange: json['priceRange'] as String?,
      source: json['source'] as String?,
    );
  }
}

class CulturalEvent {
  const CulturalEvent({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.timing,
    required this.nearbyPandal,
  });

  final String id;
  final String name;
  final String type;
  final double lat;
  final double lng;
  final String timing;
  final String nearbyPandal;

  factory CulturalEvent.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>? ?? {};
    return CulturalEvent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      lat: (coords['lat'] as num?)?.toDouble() ?? 0,
      lng: (coords['lng'] as num?)?.toDouble() ?? 0,
      timing: json['timing'] as String? ?? '',
      nearbyPandal: json['nearbyPandal'] as String? ?? '',
    );
  }
}

class SafetyGuide {
  const SafetyGuide({required this.title, required this.content});
  final String title;
  final List<String> content;

  factory SafetyGuide.fromJson(Map<String, dynamic> json) => SafetyGuide(
        title: json['title'] as String? ?? '',
        content: (json['content'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class SupplementaryRepository {
  List<Helpline>? _helplines;
  List<FoodSpot>? _foodSpots;
  List<CulturalEvent>? _events;
  List<SafetyGuide>? _safetyGuides;

  Future<List<Helpline>> getHelplines() async {
    if (_helplines != null) return _helplines!;
    try {
      final str = await rootBundle.loadString('assets/data/helplines.json');
      final list = json.decode(str) as List<dynamic>;
      _helplines = list.map((e) => Helpline.fromJson(e as Map<String, dynamic>)).toList();
      return _helplines!;
    } catch (_) {
      return [];
    }
  }

  Future<List<FoodSpot>> getFoodSpots() async {
    if (_foodSpots != null) return _foodSpots!;
    try {
      final str = await rootBundle.loadString('assets/data/food_spots.json');
      final list = json.decode(str) as List<dynamic>;
      _foodSpots = list.map((e) => FoodSpot.fromJson(e as Map<String, dynamic>)).toList();
      return _foodSpots!;
    } catch (_) {
      return [];
    }
  }

  Future<List<CulturalEvent>> getEvents() async {
    if (_events != null) return _events!;
    try {
      final str = await rootBundle.loadString('assets/data/events.json');
      final list = json.decode(str) as List<dynamic>;
      _events = list.map((e) => CulturalEvent.fromJson(e as Map<String, dynamic>)).toList();
      return _events!;
    } catch (_) {
      return [];
    }
  }

  Future<List<SafetyGuide>> getSafetyGuides() async {
    if (_safetyGuides != null) return _safetyGuides!;
    try {
      final str = await rootBundle.loadString('assets/data/safety_first_aid.json');
      final list = json.decode(str) as List<dynamic>;
      _safetyGuides = list.map((e) => SafetyGuide.fromJson(e as Map<String, dynamic>)).toList();
      return _safetyGuides!;
    } catch (_) {
      return [];
    }
  }

  List<PandalToilets>? _toilets;
  Map<String, PandalToilets>? _toiletsByPandalId;

  Future<List<PandalToilets>> getToilets() async {
    if (_toilets != null) return _toilets!;
    try {
      final str = await rootBundle.loadString('assets/data/toilets.json');
      final list = json.decode(str) as List<dynamic>;
      _toilets = list
          .map((e) => PandalToilets.fromJson(e as Map<String, dynamic>))
          .toList();
      _toiletsByPandalId = {for (final t in _toilets!) t.pandalId: t};
      return _toilets!;
    } catch (_) {
      return [];
    }
  }

  Future<PandalToilets?> getToiletsForPandal(String pandalId) async {
    if (_toiletsByPandalId == null) await getToilets();
    return _toiletsByPandalId?[pandalId];
  }
}
