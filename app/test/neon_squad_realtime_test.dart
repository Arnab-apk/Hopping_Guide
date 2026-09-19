import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolkata_puja/models/squad_member.dart';
import 'package:kolkata_puja/services/auth_service.dart';
import 'package:kolkata_puja/services/squad_neon_api.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/services/websocket_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SquadMember Realtime State & Indicators Tests', () {
    test('Calculates marker state dots correctly based on recency and sharing', () {
      final now = DateTime.now();

      // Fresh: < 15s
      final freshMember = SquadMember(
        id: 'm1',
        name: 'Ananya Sen',
        latitude: 22.5726,
        longitude: 88.3639,
        status: 'Walking',
        lastSeen: now.subtract(const Duration(seconds: 5)),
        isOnline: true,
        shareLocation: true,
      );
      expect(freshMember.markerState, equals(MemberMarkerState.fresh));
      expect(freshMember.markerStateDot, equals('🟢'));
      expect(freshMember.lastSeenText, equals('Live now'));

      // Stale: 15-60s
      final staleMember = SquadMember(
        id: 'm2',
        name: 'Debjit Bose',
        latitude: 22.5726,
        longitude: 88.3639,
        status: 'At Pandal',
        lastSeen: now.subtract(const Duration(seconds: 35)),
        isOnline: true,
        shareLocation: true,
      );
      expect(staleMember.markerState, equals(MemberMarkerState.stale));
      expect(staleMember.markerStateDot, equals('🟡'));
      expect(staleMember.lastSeenText, equals('35s ago'));

      // Old: > 60s
      final oldMember = SquadMember(
        id: 'm3',
        name: 'Rohan Ghosh',
        latitude: 22.5726,
        longitude: 88.3639,
        status: 'Eating Phuchka',
        lastSeen: now.subtract(const Duration(minutes: 5)),
        isOnline: true,
        shareLocation: true,
      );
      expect(oldMember.markerState, equals(MemberMarkerState.old));
      expect(oldMember.markerStateDot, equals('⚫'));
      expect(oldMember.lastSeenText, equals('5m ago'));

      // Not sharing location
      final notSharingMember = freshMember.copyWith(shareLocation: false);
      expect(notSharingMember.markerState, equals(MemberMarkerState.notSharing));
      expect(notSharingMember.markerStateDot, equals('⚫'));

      // Offline
      final offlineMember = freshMember.copyWith(isOnline: false);
      expect(offlineMember.markerState, equals(MemberMarkerState.offline));
      expect(offlineMember.markerStateDot, equals('⚪'));
    });
  });

  group('SquadSeparationAlert Tests', () {
    test('Alert holds member info, distance, and threshold', () {
      const alert = SquadSeparationAlert(
        memberId: 'm2',
        memberName: 'Debjit Bose',
        distanceMeters: 620,
        thresholdMeters: 500,
        isCleared: false,
      );

      expect(alert.memberId, equals('m2'));
      expect(alert.memberName, equals('Debjit Bose'));
      expect(alert.distanceMeters, equals(620));
      expect(alert.thresholdMeters, equals(500));
      expect(alert.isCleared, isFalse);
    });

    test('Dismissing alert in SquadService clears activeSeparationAlert', () async {
      SharedPreferences.setMockInitialValues({});
      final service = await SquadService.create();

      expect(service.activeSeparationAlert, isNull);
      service.dismissSeparationAlert();
      expect(service.activeSeparationAlert, isNull);

      service.dispose();
    });
  });

  group('SquadNeonApi Unit Tests (Mock HTTP)', () {
    test('createSquad calls POST /api/squads and parses response', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/api/squads'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], equals('Ballygunge Hoppers'));
        expect(body['meetupLabel'], equals('Maddox Square Gate 1'));

        return http.Response(
          jsonEncode({
            'squad': {
              'id': 'sq-uuid-1234',
              'name': 'Ballygunge Hoppers',
              'code': 'PUJA-ABCD',
              'meetup_point_name': 'Maddox Square Gate 1',
              'meetup_point_lat': 22.528,
              'meetup_point_lng': 88.358,
              'separation_radius_m': 500,
            },
            'member': {
              'user_id': 'host-uid',
              'role': 'host',
            }
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = SquadNeonApi(baseUrl: 'http://test.api', client: mockClient);
      final result = await api.createSquad(
        name: 'Ballygunge Hoppers',
        meetupLabel: 'Maddox Square Gate 1',
        meetupLat: 22.528,
        meetupLng: 88.358,
      );

      expect(result['squad']['id'], equals('sq-uuid-1234'));
      expect(result['squad']['code'], equals('PUJA-ABCD'));
    });

    test('joinSquad calls POST /api/squads/join and returns squad & member', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/api/squads/join'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['code'], equals('PUJA-ABCD'));

        return http.Response(
          jsonEncode({
            'squad': {
              'id': 'sq-uuid-1234',
              'name': 'Ballygunge Hoppers',
              'code': 'PUJA-ABCD',
            },
            'member': {'role': 'member'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = SquadNeonApi(baseUrl: 'http://test.api', client: mockClient);
      final result = await api.joinSquad(code: 'PUJA-ABCD');
      expect(result['squad']['id'], equals('sq-uuid-1234'));
    });

    test('previewSquad calls GET /api/squads/preview/:code', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/api/squads/preview/PUJA-ABCD'));

        return http.Response(
          jsonEncode({
            'id': 'sq-uuid-1234',
            'name': 'Ballygunge Hoppers',
            'code': 'PUJA-ABCD',
            'member_count': 3,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = SquadNeonApi(baseUrl: 'http://test.api', client: mockClient);
      final preview = await api.previewSquad('PUJA-ABCD');
      expect(preview['member_count'], equals(3));
    });

    test('updateMeetup calls PATCH /api/squads/:id/meetup', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('PATCH'));
        expect(request.url.path, equals('/api/squads/sq-123/meetup'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['label'], equals('Deshapriya Park Food Stall'));

        return http.Response(
          jsonEncode({'success': true, 'meetup_point_name': 'Deshapriya Park Food Stall'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = SquadNeonApi(baseUrl: 'http://test.api', client: mockClient);
      final res = await api.updateMeetup(
        squadId: 'sq-123',
        lat: 22.520,
        lng: 88.355,
        label: 'Deshapriya Park Food Stall',
      );
      expect(res['meetup_point_name'], equals('Deshapriya Park Food Stall'));
    });

    test('HTTP error throws SquadApiException with details', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Squad not found or code invalid'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = SquadNeonApi(baseUrl: 'http://test.api', client: mockClient);
      expect(
        () async => await api.getSquad('unknown-squad'),
        throwsA(isA<SquadApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(404),
        )),
      );
    });
  });

  group('WebSocketClient Envelope Formatting Tests', () {
    test('sendEnvelope formats standardized envelope payload', () async {
      final client = WebSocketClient();
      final env = await client.sendEnvelope(
        type: 'presence',
        squadId: 'squad-neon-1',
        senderId: 'user-debjit',
        payload: {'state': 'online'},
      );

      expect(env['type'], equals('presence'));
      expect(env['squadId'], equals('squad-neon-1'));
      expect(env['senderId'], equals('user-debjit'));
      expect(env['payload']['state'], equals('online'));
      expect(env['timestamp'], isA<String>());
      expect(env['eventId'], isA<String>());
    });

    test('constructs channel URL with squadId and token query params', () {
      final client = WebSocketClient(serverUrl: 'ws://custom.neon.host:8080/ws');
      final uri = client.buildChannelUri(token: 'my-jwt-token', squadId: 'sq-1234');
      expect(uri.queryParameters['token'], equals('my-jwt-token'));
      expect(uri.queryParameters['squadId'], equals('sq-1234'));
      expect(uri.host, equals('custom.neon.host'));
    });
  });

  group('AuthService Guest Upgrade Verification', () {
    test('Anonymous guest keeps same UID when upgrading', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = await AuthService.create();

      // Sign in as guest
      final guest = await auth.signInAsGuest();
      expect(guest.isGuest, isTrue);
      expect(auth.isAuthenticated, isTrue);
      final guestUid = guest.uid;

      // Upgrade guest to Google
      final upgradeRes = await auth.upgradeGuestToGoogle();
      expect(upgradeRes.isSuccess, isTrue);
      expect(upgradeRes.user, isNotNull);
      // The UID must remain the exact same identity
      expect(upgradeRes.user!.uid, equals(guestUid));
      expect(upgradeRes.user!.isGuest, isFalse);
    });
  });
}
