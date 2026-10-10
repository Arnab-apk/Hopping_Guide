import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolkata_puja/services/group_video_api.dart';

void main() {
  test('fetches a session with Firebase bearer authentication', () async {
    final api = GroupVideoApi(
      baseUrl: 'https://example.com/',
      idTokenLoader: () async => 'firebase-token',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/squads/group-1/video/session');
        expect(request.headers['Authorization'], 'Bearer firebase-token');
        expect(request.headers.containsKey('x-user-id'), isFalse);
        return http.Response(
          jsonEncode({
            'apiKey': 'key',
            'userId': 'alice',
            'token': 'token',
            'callId': 'room',
            'callType': 'uma_squad',
          }),
          200,
        );
      }),
    );
    addTearDown(api.dispose);
    expect((await api.session('group-1')).callId, 'room');
  });

  test('signed-out users do not reach the token endpoint', () async {
    final api = GroupVideoApi(
      idTokenLoader: () async => null,
      client: MockClient((_) async => fail('Must not request a token')),
    );
    addTearDown(api.dispose);
    await expectLater(
      api.session('group'),
      throwsA(isA<GroupVideoException>()),
    );
  });

  test('membership denial and unavailable server show safe errors', () async {
    for (final code in [401, 403, 429, 503]) {
      final api = GroupVideoApi(
        baseUrl: 'https://example.com',
        idTokenLoader: () async => 'firebase-token',
        client: MockClient(
          (_) async => http.Response('upstream-sensitive-error', code),
        ),
      );
      try {
        await expectLater(
          api.session('group'),
          throwsA(
            isA<GroupVideoException>().having(
              (e) => e.message,
              'message',
              isNot(contains('upstream-sensitive-error')),
            ),
          ),
        );
      } finally {
        api.dispose();
      }
    }
  });

  test('malformed sessions cannot initialise the video SDK', () {
    expect(
      () => GroupVideoSession.fromJson({'apiKey': 'key'}),
      throwsA(isA<GroupVideoException>()),
    );
  });
}
