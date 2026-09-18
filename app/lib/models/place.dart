import '../repositories/supplementary_repository.dart';
import '../utils/constants.dart';
import 'pandal.dart';
import 'place_category.dart';

export 'place_category.dart';

/// Unified place model providing a common contract for pandals and culinary spots.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    this.area,
    this.region,
    this.rating,
    this.distanceKm,
    // Pandal specifics
    this.zone,
    this.theme,
    this.crowdLevel,
    this.timings,
    this.imageUrl,
    this.description,
    this.nearestMetro,
    this.nearestMetroList = const [],
    this.nearestRailway,
    this.transport = const [],
    this.specialFeatures = const [],
    // FoodSpot specifics
    this.type,
    this.mustTry,
    this.priceRange,
    this.nearbyPandal,
    this.source,
    // Original model references
    this.rawPandal,
    this.rawFoodSpot,
  });

  final String id;
  final String name;
  final PlaceCategory category;
  final double lat;
  final double lng;
  final String? area;
  final String? region;
  final double? rating;
  final double? distanceKm;

  // Pandal fields
  final KolkataZone? zone;
  final String? theme;
  final String? crowdLevel;
  final String? timings;
  final String? imageUrl;
  final String? description;
  final String? nearestMetro;
  final List<String> nearestMetroList;
  final String? nearestRailway;
  final List<String> transport;
  final List<String> specialFeatures;

  // FoodSpot fields
  final String? type;
  final String? mustTry;
  final String? priceRange;
  final String? nearbyPandal;
  final String? source;

  final Pandal? rawPandal;
  final FoodSpot? rawFoodSpot;

  bool get isPandal => category == PlaceCategory.pandal;
  bool get isFoodSpot => category == PlaceCategory.foodSpot;
  double get latitude => lat;
  double get longitude => lng;

  factory Place.fromPandal(Pandal p) {
    return Place(
      id: p.id,
      name: p.name,
      category: PlaceCategory.pandal,
      lat: p.lat,
      lng: p.lng,
      area: p.area,
      region: p.region,
      rating: p.rating,
      zone: p.zone,
      theme: p.theme,
      crowdLevel: p.crowdLevel,
      timings: p.timings,
      imageUrl: p.imageUrl,
      description: p.description,
      nearestMetro: p.nearestMetro,
      nearestMetroList: p.nearestMetroList,
      nearestRailway: p.nearestRailway,
      transport: p.transport,
      specialFeatures: p.specialFeatures,
      rawPandal: p,
    );
  }

  factory Place.fromFoodSpot(FoodSpot f, {KolkataZone? zone}) {
    return Place(
      id: f.id,
      name: f.name,
      category: PlaceCategory.foodSpot,
      lat: f.lat,
      lng: f.lng,
      area: f.nearbyPandal,
      rating: f.rating,
      type: f.type,
      mustTry: f.mustTry,
      priceRange: f.priceRange,
      nearbyPandal: f.nearbyPandal,
      source: f.source,
      zone: zone,
      rawFoodSpot: f,
    );
  }

  factory Place.fromDoc(Map<String, dynamic> d, String id) {
    final catStr = d['category'] as String?;
    final cat = catStr == 'foodSpot' ? PlaceCategory.foodSpot : PlaceCategory.pandal;
    if (cat == PlaceCategory.foodSpot) {
      return Place.fromFoodSpot(FoodSpot.fromJson({'id': id, ...d}));
    } else {
      return Place.fromPandal(Pandal.fromMap(id, d));
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category.name,
        'lat': lat,
        'lng': lng,
        'area': area,
        'region': region,
        'rating': rating,
        'zone': zone?.name,
        'theme': theme,
        'crowd_level': crowdLevel,
        'timings': timings,
        'image_url': imageUrl,
        'description': description,
        'nearest_metro': nearestMetro,
        'transport': transport,
        'special_features': specialFeatures,
        'type': type,
        'mustTry': mustTry,
        'priceRange': priceRange,
        'nearbyPandal': nearbyPandal,
        'source': source,
      };
}
