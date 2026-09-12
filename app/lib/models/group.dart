import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore collection: `groups`
/// A group is created/joined via a shareable code (P0). Members' live locations
/// are NOT stored here — those go to Realtime DB under /groups/{groupId}/locations
/// (architecture doc section 3: keep ephemeral high-frequency data out of Firestore).
class Group {
  Group({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String code; // short shareable join code
  final String ownerId;
  final List<String> memberIds;
  final DateTime createdAt;

  factory Group.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Group(
      id: doc.id,
      name: d['name'] as String? ?? '',
      code: d['code'] as String? ?? '',
      ownerId: d['owner_id'] as String? ?? '',
      memberIds: List<String>.from((d['member_ids'] as List?)?.cast() ?? const []),
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'code': code,
        'owner_id': ownerId,
        'member_ids': memberIds,
        'created_at': Timestamp.now(),
      };
}
