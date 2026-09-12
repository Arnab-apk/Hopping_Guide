import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pandal.dart';
import '../utils/constants.dart';

/// Thin repository over the `pandals` Firestore collection (P0 browse/detail).
/// Kept as an interface so the backend can be swapped (e.g. to Supabase) with
/// a different implementation and no UI changes — see architecture doc section 2.
abstract class PandalRepository {
  Future<List<Pandal>> all();
  Future<List<Pandal>> byZone(KolkataZone zone);
  Future<Pandal?> byId(String id);
  Stream<List<Pandal>> watchAll();
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
}
