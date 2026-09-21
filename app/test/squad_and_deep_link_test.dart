import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/squad_member.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Deep Link Parsing Tests', () {
    String? extractSquadCode(Uri uri) {
      final codeParam = uri.queryParameters['code'];
      if (codeParam != null && codeParam.trim().isNotEmpty) {
        return codeParam.trim().toUpperCase();
      }
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        if (segments.first.toLowerCase() == 'join' && segments.length > 1) {
          return segments[1].trim().toUpperCase();
        }
        if (uri.host.toLowerCase() == 'join' && segments.length == 1) {
          return segments.first.trim().toUpperCase();
        }
      }
      return null;
    }

    String? extractPandalId(Uri uri) {
      final idParam = uri.queryParameters['id'] ?? uri.queryParameters['pandalId'];
      if (idParam != null && idParam.trim().isNotEmpty) {
        return idParam.trim();
      }
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        if (segments.first.toLowerCase() == 'pandal' && segments.length > 1) {
          return segments[1].trim();
        }
        if (uri.host.toLowerCase() == 'pandal' && segments.length == 1) {
          return segments.first.trim();
        }
      }
      return null;
    }

    test('parses custom scheme squad invite query: pujoparikrama://join?code=PUJAX4K9', () {
      final uri = Uri.parse('pujoparikrama://join?code=PUJAX4K9');
      expect(extractSquadCode(uri), equals('PUJAX4K9'));
    });

    test('parses route URI received by Flutter route observer: /?code=PUJAUB5P', () {
      final uri = Uri.parse('/?code=PUJAUB5P');
      expect(extractSquadCode(uri), equals('PUJAUB5P'));
    });

    test('parses route URI with join path: /join?code=PUJAUB5P', () {
      final uri = Uri.parse('/join?code=PUJAUB5P');
      expect(extractSquadCode(uri), equals('PUJAUB5P'));
    });

    test('parses custom scheme squad invite path: pujoparikrama://join/PUJAB9Z2', () {
      final uri = Uri.parse('pujoparikrama://join/PUJAB9Z2');
      expect(extractSquadCode(uri), equals('PUJAB9Z2'));
    });

    test('parses https squad invite query: https://sharodiya.com/join?code=PUJA77AA', () {
      final uri = Uri.parse('https://sharodiya.com/join?code=PUJA77AA');
      expect(extractSquadCode(uri), equals('PUJA77AA'));
    });

    test('parses https squad invite path: https://sharodiya.com/join/PUJA99BB', () {
      final uri = Uri.parse('https://sharodiya.com/join/PUJA99BB');
      expect(extractSquadCode(uri), equals('PUJA99BB'));
    });

    test('parses custom scheme pandal query: pujoparikrama://pandal?id=bagbazar_sarbojanin', () {
      final uri = Uri.parse('pujoparikrama://pandal?id=bagbazar_sarbojanin');
      expect(extractPandalId(uri), equals('bagbazar_sarbojanin'));
    });

    test('parses https pandal path: https://sharodiya.com/pandal/suruchi_sangha', () {
      final uri = Uri.parse('https://sharodiya.com/pandal/suruchi_sangha');
      expect(extractPandalId(uri), equals('suruchi_sangha'));
    });
  });

  group('SquadMember Model Tests', () {
    test('companion members from JSON preserve companion status', () {
      final json = {
        'id': 'member_friend_1',
        'name': 'Subrata Ghosh',
        'lat': 22.5697,
        'lng': 88.3697,
        'status': 'At Pandal Gate',
        'is_host': false,
        'is_user': true, // Simulated remote device stored true
        'battery': 82,
        'color': 0xFF2196F3,
        'last_seen': DateTime.now().millisecondsSinceEpoch,
      };

      // When parsing cloud member, copyWith(isUser: false) is applied
      final member = SquadMember.fromJson(json).copyWith(isUser: false);
      expect(member.isUser, isFalse);
      expect(member.name, equals('Subrata Ghosh'));
      expect(member.initials, equals('SG'));
      expect(member.latitude, equals(22.5697));
    });

    test('initials generator handles single and multi-word names', () {
      final m1 = SquadMember(
        id: '1',
        name: 'Ananya Roy',
        latitude: 22.0,
        longitude: 88.0,
        status: 'Active',
        lastSeen: DateTime.now(),
      );
      expect(m1.initials, equals('AR'));

      final m2 = SquadMember(
        id: '2',
        name: 'PujoHopper',
        latitude: 22.0,
        longitude: 88.0,
        status: 'Active',
        lastSeen: DateTime.now(),
      );
      expect(m2.initials, equals('P'));
    });
  });

  group('SquadService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('creates squad and verifies zero dummy companions initially', () async {
      final service = await SquadService.create();
      expect(service.hasActiveSquad, isFalse);
      expect(service.companionMembers, isEmpty);

      await service.createSquad('Hatibagan Crawlers', 'Hatibagan Crossing');
      expect(service.hasActiveSquad, isTrue);
      expect(service.squadCode, startsWith('PUJA'));
      expect(service.squadName, equals('Hatibagan Crawlers'));
      expect(service.meetupPointName, equals('Hatibagan Crossing'));
      expect(service.companionMembers, isEmpty);
      expect(service.members.length, equals(1));
      expect(service.members.first.isUser, isTrue);
      expect(service.members.first.isHost, isTrue);
    });

    test('adding companion updates companionMembers list', () async {
      final service = await SquadService.create();
      await service.createSquad('College Street Explorers', 'Coffee House');

      final companion = SquadMember(
        id: 'companion_rohit',
        name: 'Rohit Paul',
        latitude: 22.5744,
        longitude: 88.3629,
        status: 'Walking',
        lastSeen: DateTime.now(),
        isUser: false,
      );

      service.addMember(companion);
      expect(service.companionMembers.length, equals(1));
      expect(service.companionMembers.first.name, equals('Rohit Paul'));
      expect(service.members.length, equals(2));

      service.removeMember('companion_rohit');
      expect(service.companionMembers, isEmpty);
    });

    test('leaveSquad clears all active squad state and persisted data', () async {
      final service = await SquadService.create();
      await service.createSquad('Maddox Square Squad', 'South Entrance');
      expect(service.hasActiveSquad, isTrue);

      await service.leaveSquad();
      expect(service.hasActiveSquad, isFalse);
      expect(service.squadCode, isNull);
      expect(service.squadName, isNull);
      expect(service.members, isEmpty);
      expect(service.companionMembers, isEmpty);
    });
  });
}
