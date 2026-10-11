import 'package:cloud_firestore/cloud_firestore.dart';

/// Short-lived invitations over the existing member-only group message stream.
/// No media client is kept alive while the user is browsing the map.
class GroupCallSignaling {
  GroupCallSignaling(this.firestore);
  final FirebaseFirestore firestore;
  static const lifetime = Duration(seconds: 60);

  CollectionReference<Map<String, dynamic>> _messages(String group) =>
      firestore.collection('squads').doc(group).collection('messages');

  Future<String> invite(String group, String uid, String name) async {
    final doc = _messages(group).doc();
    await doc.set({
      'squadId': group,
      'senderId': uid,
      'senderName': name,
      'type': 'text',
      'text': '$name started a group call.',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'callEvent': 'invite',
      'callInvitationId': doc.id,
      'callSentAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> end(String group, String uid, String invitation) =>
      _messages(group).doc('${invitation}_ended').set({
        'squadId': group,
        'senderId': uid,
        'senderName': 'Group member',
        'type': 'text',
        'text': 'The caller left the group call.',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'callEvent': 'end',
        'callInvitationId': invitation,
        'callSentAt': FieldValue.serverTimestamp(),
      });

  Stream<List<CallInvitation>> invitations(String group, String uid) =>
      _messages(group)
          .orderBy('timestamp', descending: true)
          .limit(30)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
            if (snapshot.metadata.isFromCache) return <CallInvitation>[];
            final ended = <String, String>{};
            for (final doc in snapshot.docs) {
              final data = doc.data();
              if (data['callEvent'] == 'end' &&
                  data['callInvitationId'] is String &&
                  data['senderId'] is String) {
                ended[data['callInvitationId'] as String] =
                    data['senderId'] as String;
              }
            }
            return [
              for (final doc in snapshot.docs)
                if (CallInvitation.fromData(
                      doc.id,
                      group,
                      doc.data(),
                      uid,
                      ended,
                    )
                    case final CallInvitation invitation)
                  invitation,
            ];
          });
}

class CallInvitation {
  const CallInvitation({
    required this.id,
    required this.group,
    required this.caller,
    required this.expiresAt,
  });
  final String id, group, caller;
  final DateTime expiresAt;

  static CallInvitation? fromData(
    String id,
    String group,
    Map<String, dynamic> data,
    String uid,
    Map<String, String> ended, {
    DateTime? now,
  }) {
    final sender = data['senderId'];
    final sent = data['callSentAt'];
    if (data['callEvent'] != 'invite' ||
        data['callInvitationId'] != id ||
        sender is! String ||
        sender == uid ||
        sender == 'system_pujo' ||
        ended[id] == sender ||
        sent is! Timestamp) {
      return null;
    }
    final time = now ?? DateTime.now();
    final expires = sent.toDate().add(GroupCallSignaling.lifetime);
    if (!expires.isAfter(time) ||
        sent.toDate().isAfter(time.add(const Duration(seconds: 10)))) {
      return null;
    }
    return CallInvitation(
      id: id,
      group: group,
      caller: data['senderName'] is String
          ? data['senderName'] as String
          : 'Group member',
      expiresAt: expires,
    );
  }
}
