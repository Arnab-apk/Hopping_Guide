import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/chat_message.dart';
import 'package:kolkata_puja/models/squad_member.dart';
import 'package:kolkata_puja/repositories/squad_firestore_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SquadFirestoreRepository Unit Tests', () {
    test('leaving a saved group that no longer contains the account needs no write', () async {
      final firestore = _LeaveFirestore([
        _LeaveSnapshot({'membersUid': ['other_member']}),
      ]);
      await SquadFirestoreRepository(firestore: firestore)
          .leaveSquad(squadId: 'sq_old', memberId: 'current_member');
      expect(firestore.commits, 0);
      expect(firestore.document.sources, [Source.server]);
    });

    test('leaving a deleted saved group succeeds without a write', () async {
      final firestore = _LeaveFirestore([_LeaveSnapshot(null)]);
      await SquadFirestoreRepository(firestore: firestore)
          .leaveSquad(squadId: 'sq_old', memberId: 'current_member');
      expect(firestore.commits, 0);
    });

    test('an active member is removed from the roster and member records together', () async {
      final firestore = _LeaveFirestore([
        _LeaveSnapshot({'membersUid': ['current_member', 'other_member']}),
      ]);
      await SquadFirestoreRepository(firestore: firestore)
          .leaveSquad(squadId: 'sq_active', memberId: 'current_member');
      expect(firestore.commits, 1);
      expect(firestore.batchImpl.deletedIds, ['current_member']);
      expect(firestore.batchImpl.updatedFields.single.keys, ['membersUid']);
    });

    test('a concurrent leave on another device is treated as already complete', () async {
      final firestore = _LeaveFirestore([
        _LeaveSnapshot({'membersUid': ['current_member', 'other_member']}),
        _LeaveSnapshot({'membersUid': ['other_member']}),
      ], commitError: FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
      await SquadFirestoreRepository(firestore: firestore)
          .leaveSquad(squadId: 'sq_active', memberId: 'current_member');
      expect(firestore.document.sources, [Source.server, Source.server]);
    });

    test('permission denial is preserved when server membership still exists', () async {
      final firestore = _LeaveFirestore([
        _LeaveSnapshot({'membersUid': ['current_member']}),
        _LeaveSnapshot({'membersUid': ['current_member']}),
      ], commitError: FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
      await expectLater(
        SquadFirestoreRepository(firestore: firestore)
            .leaveSquad(squadId: 'sq_active', memberId: 'current_member'),
        throwsA(isA<FirebaseException>()),
      );
    });

    test('generateSquadCode produces valid 8-char PUJA uppercase format', () {
      for (int i = 0; i < 20; i++) {
        final code = SquadFirestoreRepository.generateSquadCode();
        expect(code.length, equals(8));
        expect(code.startsWith('PUJA'), isTrue);
        expect(RegExp(r'^PUJA[2-9A-Z]{4}$').hasMatch(code), isTrue);
      }
    });

    test('createSquad returns valid squad metadata structure without active Firestore', () async {
      final repo = SquadFirestoreRepository();
      expect(repo.isAvailable, isFalse);

      final host = SquadMember(
        id: 'host_123',
        name: 'Arnab (Host)',
        latitude: 22.5726,
        longitude: 88.3639,
        status: 'Host • Active',
        isHost: true,
        isUser: true,
        lastSeen: DateTime.now(),
      );

      final result = await repo.createSquad(
        name: 'Bagbazar Hoppers',
        meetupPointName: 'Gate 2 Landmark',
        meetupLat: 22.5726,
        meetupLng: 88.3639,
        separationThresholdMeters: 450,
        host: host,
      );

      expect(result['name'], equals('Bagbazar Hoppers'));
      expect(result['squadCode'], startsWith('PUJA'));
      expect(result['meetupPointName'], equals('Gate 2 Landmark'));
      expect(result['meetupLat'], equals(22.5726));
      expect(result['meetupLng'], equals(88.3639));
      expect(result['separationThresholdMeters'], equals(450));
      expect(result['squadId'], isNotNull);
    });

    test('findSquadByCode and streams return gracefully when Firestore unconfigured', () async {
      final repo = SquadFirestoreRepository();

      final found = await repo.findSquadByCode('PUJA99');
      expect(found, isNull);

      final squadStream = repo.streamSquad('sq_test');
      expect(await squadStream.isEmpty, isTrue);

      final membersStream = repo.streamMembers('sq_test', currentUserId: 'u1');
      expect(await membersStream.isEmpty, isTrue);

      final messagesStream = repo.streamMessages('sq_test');
      expect(await messagesStream.isEmpty, isTrue);
    });

    test('joinSquad, leaveSquad, updateMemberLocation succeed without throwing when offline', () async {
      final repo = SquadFirestoreRepository();

      final member = SquadMember(
        id: 'member_456',
        name: 'Debjit',
        latitude: 22.5300,
        longitude: 88.3500,
        status: 'Walking',
        isHost: false,
        isUser: false,
        lastSeen: DateTime.now(),
      );

      final joined = await repo.joinSquad(squadId: 'sq_1', member: member);
      expect(joined, isTrue);

      await repo.updateMemberLocation(
        squadId: 'sq_1',
        memberId: 'member_456',
        lat: 22.5310,
        lng: 88.3510,
        batteryLevel: 80,
        isOnline: true,
        shareLocation: true,
      );

      await repo.updateSquadSettings(
        squadId: 'sq_1',
        name: 'New Name',
        separationThresholdMeters: 600,
      );

      await repo.sendMessage(
        squadId: 'sq_1',
        message: ChatMessage(
          id: 'msg_1',
          squadId: 'sq_1',
          senderId: 'u1',
          senderName: 'Debjit',
          text: 'Reached pandal!',
          type: ChatMessageType.text,
          timestamp: DateTime.now(),
        ),
      );

      await repo.leaveSquad(
        squadId: 'sq_1',
        memberId: 'member_456',
        memberName: 'Debjit',
      );
    });
  });
}

class _LeaveFirestore implements FirebaseFirestore {
  _LeaveFirestore(List<_LeaveSnapshot> snapshots, {this.commitError})
      : document = _LeaveDocument(snapshots);
  final _LeaveDocument document;
  final FirebaseException? commitError;
  int commits = 0;
  late final batchImpl = _LeaveBatch(this);
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => _LeaveCollection(document);
  @override
  WriteBatch batch() => batchImpl;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// SDK interfaces are implemented only as isolated test doubles here.
// ignore: subtype_of_sealed_class
class _LeaveCollection implements CollectionReference<Map<String, dynamic>> {
  _LeaveCollection(this.document);
  final _LeaveDocument document;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => document;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _LeaveDocument implements DocumentReference<Map<String, dynamic>> {
  _LeaveDocument(this.responses, {this.id = 'squad'});
  final List<_LeaveSnapshot> responses;
  final sources = <Source?>[];
  @override
  final String id;
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    sources.add(options?.source);
    return responses.removeAt(0);
  }
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _LeaveCollection(_LeaveDocument([], id: 'current_member'));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _LeaveSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _LeaveSnapshot(this.value);
  final Map<String, dynamic>? value;
  @override
  bool get exists => value != null;
  @override
  Map<String, dynamic>? data() => value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LeaveBatch implements WriteBatch {
  _LeaveBatch(this.firestore);
  final _LeaveFirestore firestore;
  final deletedIds = <String>[];
  final updatedFields = <Map<String, dynamic>>[];
  @override
  void delete(DocumentReference<Object?> document) => deletedIds.add(document.id);
  @override
  void update<T>(DocumentReference<T> document, T data) =>
      updatedFields.add(data as Map<String, dynamic>);
  @override
  Future<void> commit() async {
    firestore.commits++;
    if (firestore.commitError != null) throw firestore.commitError!;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
