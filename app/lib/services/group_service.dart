import 'package:firebase_database/firebase_database.dart';

/// Live location sync for groups (P0). Locations are written to Realtime DB at
/// `/groups/{groupId}/locations/{userId}` every ~5-10s while sharing is active;
/// other members listen on the same path to render live pins.
/// Architecture note: this stays separate from Firestore to avoid burning the
/// Firestore write quota on high-frequency updates.
class GroupLocationService {
  GroupLocationService(this._rtdb);
  final FirebaseDatabase _rtdb;

  /// Push the user's current position to the group node.
  Future<void> sharePosition({
    required String groupId,
    required String userId,
    required double lat,
    required double lng,
  }) async {
    final ref = _rtdb.ref('groups/$groupId/locations/$userId');
    await ref.set({
      'lat': lat,
      'lng': lng,
      'ts': ServerValue.timestamp,
    });
  }

  /// Listen to all members' locations in a group.
  Stream<Map<String, Map<String, dynamic>>> watchGroup(String groupId) {
    final ref = _rtdb.ref('groups/$groupId/locations');
    return ref.onValue.map((event) {
      final snap = event.snapshot;
      if (snap.value == null) return {};
      final raw = Map<String, dynamic>.from(snap.value as Map);
      return raw.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    });
  }

  /// Clear this user's location on disconnect / leave. Pair with onDisconnect
  /// in production (architecture: `onDisconnect` presence).
  Future<void> clearPosition({required String groupId, required String userId}) {
    return _rtdb.ref('groups/$groupId/locations/$userId').remove();
  }
}
