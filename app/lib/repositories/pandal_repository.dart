import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pandal.dart';
import '../models/place.dart';
import '../utils/constants.dart';
import 'supplementary_repository.dart';

/// Thin repository over the `pandals` Firestore collection (P0 browse/detail).
/// Kept as an interface so the backend can be swapped (e.g. to Supabase) with
/// a different implementation and no UI changes — see architecture doc section 2.
abstract class PandalRepository {
  Future<List<Pandal>> all();
  Future<List<Pandal>> byZone(KolkataZone zone);
  Future<Pandal?> byId(String id);
  Stream<List<Pandal>> watchAll();

  /// Query places filtered strictly by category at the data/query layer.
  Future<List<Place>> getPlaces({
    required PlaceCategory category,
    KolkataZone? zoneFilter,
    String? searchQuery,
  }) async {
    if (category == PlaceCategory.pandal) {
      final list = zoneFilter != null ? await byZone(zoneFilter) : await all();
      var places = list.map(Place.fromPandal).toList();
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        places = places.where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.theme?.toLowerCase().contains(q) ?? false)).toList();
      }
      return places;
    } else {
      final spots = await SupplementaryRepository().getFoodSpots();
      var places = spots.map((f) => Place.fromFoodSpot(f)).toList();
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        places = places.where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.type?.toLowerCase().contains(q) ?? false) ||
            (p.mustTry?.toLowerCase().contains(q) ?? false)).toList();
      }
      return places;
    }
  }
}

class FirestorePandalRepository implements PandalRepository {
  FirestorePandalRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('pandals');

  @override
  Future<List<Pandal>> all() async {
    final snap = await _col.get();
    return snap.docs.map(Pandal.fromFirestore).toList();
  }

  @override
  Future<List<Pandal>> byZone(KolkataZone zone) async {
    final snap = await _col.where('zone', isEqualTo: zone.name).get();
    return snap.docs.map(Pandal.fromFirestore).toList();
  }

  @override
  Future<Pandal?> byId(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? Pandal.fromFirestore(doc) : null;
  }

  @override
  Stream<List<Pandal>> watchAll() =>
      _col.snapshots().map((s) => s.docs.map(Pandal.fromFirestore).toList());

  @override
  Future<List<Place>> getPlaces({
    required PlaceCategory category,
    KolkataZone? zoneFilter,
    String? searchQuery,
  }) async {
    Query<Map<String, dynamic>> query = _col.where('category', isEqualTo: category.name);
    if (zoneFilter != null) {
      query = query.where('zone', isEqualTo: zoneFilter.name);
    }
    final snap = await query.get();
    var list = snap.docs.map((d) => Place.fromDoc(d.data(), d.id)).toList();
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          (p.theme?.toLowerCase().contains(q) ?? false)).toList();
    }
    return list;
  }
}
