import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/chat_message.dart';
import 'package:kolkata_puja/models/squad_member.dart';
import 'package:kolkata_puja/repositories/squad_firestore_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SquadFirestoreRepository Unit Tests', () {
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
