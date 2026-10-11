import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/services/group_call_signaling.dart';

void main() {
  final now = DateTime(2026, 10, 11);
  Map<String, dynamic> data() => {
    'callEvent': 'invite',
    'senderId': 'alice',
    'senderName': 'Alice',
    'callInvitationId': 'invite',
    'callSentAt': Timestamp.fromDate(now),
  };
  CallInvitation? parse(
    Map<String, dynamic> value, {
    String uid = 'bob',
    Map<String, String> ended = const {},
  }) => CallInvitation.fromData('invite', 'group', value, uid, ended, now: now);

  test('fresh invitation can be accepted without opening the group first', () {
    final invite = parse(data());
    expect(invite?.group, 'group');
    expect(invite?.caller, 'Alice');
    expect(invite?.expiresAt, now.add(const Duration(seconds: 60)));
  });
  test('self, ended, expired, unconfirmed and malformed calls never ring', () {
    expect(parse(data(), uid: 'alice'), isNull);
    expect(parse(data(), ended: {'invite': 'alice'}), isNull);
    expect(
      parse({
        ...data(),
        'callSentAt': Timestamp.fromDate(
          now.subtract(const Duration(seconds: 61)),
        ),
      }),
      isNull,
    );
    expect(parse({...data(), 'callSentAt': null}), isNull);
    expect(parse({...data(), 'callInvitationId': 'other'}), isNull);
    expect(parse({...data(), 'senderId': 'system_pujo'}), isNull);
    expect(
      parse({
        ...data(),
        'callSentAt': Timestamp.fromDate(now.add(const Duration(minutes: 1))),
      }),
      isNull,
    );
    expect(parse(data(), ended: {'invite': 'someone_else'}), isNotNull);
  });
}
