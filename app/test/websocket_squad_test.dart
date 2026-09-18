import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/squad_member.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/services/websocket_client.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebSocketClient Unit Tests', () {
    test('Default URL derives localhost or Android loopback', () {
      final client = WebSocketClient(serverUrl: 'ws://custom.host:9000/squad');
      expect(client.defaultServerUrl, equals('ws://custom.host:9000/squad'));
    });

    test('Initial connection state is disconnected', () {
      final client = WebSocketClient();
      expect(client.currentState, equals(WebSocketConnectionState.disconnected));
      expect(client.isConnected, isFalse);
    });

    test('Send message attaches timestamp to payload', () async {
      final client = WebSocketClient();
      final message = <String, dynamic>{
        'type': 'test_ping',
      };
      await client.sendMessage(message);
      expect(message.containsKey('timestamp'), isTrue);
      expect(message['timestamp'], isA<int>());
    });
  });

  group('SquadService WebSocket Event Handling Tests', () {
    late SquadService squadService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      squadService = await SquadService.create();
    });

    tearDown(() {
      squadService.dispose();
    });

    test('Adding companion directly or via event updates companionMembers', () {
      expect(squadService.companionMembers, isEmpty);

      final companion = SquadMember(
        id: 'companion_subrata',
        name: 'Subrata Roy',
        latitude: 22.5850,
        longitude: 88.3700,
        status: 'Walking to Maddox Square',
        lastSeen: DateTime.now(),
        isHost: false,
        isUser: false,
        batteryLevel: 85,
      );

      squadService.addMember(companion);
      expect(squadService.companionMembers.length, equals(1));
      expect(squadService.companionMembers.first.name, equals('Subrata Roy'));

      // Remove companion
      squadService.removeMember('companion_subrata');
      expect(squadService.companionMembers, isEmpty);
    });

    test('setMeetupPoint updates landmark name and coordinates', () {
      squadService.setMeetupPoint('Tridhara Sammilani Gate 2', const LatLng(22.5200, 88.3600));
      expect(squadService.meetupPointName, equals('Tridhara Sammilani Gate 2'));
      expect(squadService.meetupPointCoords.latitude, equals(22.5200));
      expect(squadService.meetupPointCoords.longitude, equals(88.3600));
    });

    test('leaveSquad clears all active squad state', () async {
      await squadService.createSquad('Bagbazar Squad', 'North Gate Landmark');
      expect(squadService.hasActiveSquad, isTrue);
      expect(squadService.squadCode, isNotNull);

      await squadService.leaveSquad();
      expect(squadService.hasActiveSquad, isFalse);
      expect(squadService.squadCode, isNull);
      expect(squadService.squadName, isNull);
      expect(squadService.members, isEmpty);
    });
  });
}
