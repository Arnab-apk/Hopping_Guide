import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolkata_puja/models/route_chat_models.dart';
import 'package:kolkata_puja/services/chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RouteChat Models Serialization', () {
    test('RouteSummary toJson and fromJson', () {
      const summary = RouteSummary(
        distanceM: 5200,
        durationS: 3900,
        polyline: 'xyz_polyline',
        originName: 'Howrah Station',
        destinationName: 'Kumartuli Park',
      );

      final json = summary.toJson();
      expect(json['distance_m'], 5200);
      expect(json['duration_s'], 3900);
      expect(json['polyline'], 'xyz_polyline');
      expect(json['origin'], 'Howrah Station');
      expect(json['destination'], 'Kumartuli Park');
      expect(summary.durationMin, 65);
      expect(summary.distanceKm, 5.2);

      final reconstructed = RouteSummary.fromJson(json);
      expect(reconstructed.distanceM, 5200);
      expect(reconstructed.durationS, 3900);
      expect(reconstructed.polyline, 'xyz_polyline');
      expect(reconstructed.originName, 'Howrah Station');
      expect(reconstructed.destinationName, 'Kumartuli Park');
    });

    test('ChatReply fromJson handles standard and fallback structures', () {
      final json = {
        'answer': 'Walk via Sovabazar metro for the fastest crowd-free path.',
        'facts_as_of': '2026-10-19T21:42:00.000Z',
        'used_llm': true,
        'rate_limited': false,
        'cached': true,
        'suggestions': ['Check Baghbazar', 'Check Ahiritola'],
      };

      final reply = ChatReply.fromJson(json);
      expect(reply.answer, contains('Sovabazar metro'));
      expect(reply.usedLlm, isTrue);
      expect(reply.fromCache, isTrue);
      expect(reply.isRateLimited, isFalse);
      expect(reply.suggestions.length, 2);
      expect(reply.factsAsOf, isNotNull);
    });

    test('RouteChatMessage formatted time and freshness text', () {
      final now = DateTime.now();
      final msg = RouteChatMessage(
        id: 'msg_1',
        text: 'Road is clear.',
        isUser: false,
        timestamp: DateTime(2026, 10, 19, 14, 30),
        factsAsOf: now.subtract(const Duration(minutes: 12)),
        usedLlm: false,
      );

      expect(msg.formattedTime, '14:30');
      expect(msg.freshnessText, 'Updated 12 min ago');
    });
  });

  group('ChatService API and Fallback Integration', () {
    test('Successful 200 response from backend server', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/chat');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['deviceId'], isNotEmpty);
        expect(body['message'], 'Best route to Baghbazar?');

        return http.Response(
          jsonEncode({
            'answer': 'Take Shyambazar Metro Gate 1, then walk 450m west.',
            'facts_as_of': DateTime.now().toIso8601String(),
            'used_llm': true,
            'suggestions': ['Is Baghbazar crowded?'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ChatService(
        baseUrl: 'http://test-server:8080',
        deviceId: 'anon_test_dev_1',
        client: mockClient,
      );

      final reply = await service.ask('Best route to Baghbazar?');
      expect(reply.answer, contains('Shyambazar Metro Gate 1'));
      expect(reply.usedLlm, isTrue);
      expect(reply.suggestions, contains('Is Baghbazar crowded?'));
    });

    test('429 Rate limited response handled gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Rate limit exceeded'}),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ChatService(
        baseUrl: 'http://test-server:8080',
        deviceId: 'anon_test_dev_2',
        client: mockClient,
      );

      final reply = await service.ask('Howrah to Kumartuli');
      expect(reply.isRateLimited, isTrue);
      expect(reply.answer, contains('Hourly question limit reached'));
    });

    test('Offline network error triggers local fallback (Helplines)', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Network down');
      });

      final service = ChatService(
        baseUrl: 'http://test-server:8080',
        deviceId: 'anon_test_dev_3',
        client: mockClient,
      );

      final reply = await service.ask('What is the police emergency helpline number?');
      expect(reply.answer, contains('Kolkata Police Emergency: 100 / 112'));
      expect(reply.answer, contains('Kolkata Traffic Control'));
      expect(reply.usedLlm, isFalse);
    });

    test('Offline network error triggers route summary fallback', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final service = ChatService(
        baseUrl: 'http://test-server:8080',
        deviceId: 'anon_test_dev_4',
        client: mockClient,
      );

      const route = RouteSummary(
        distanceM: 3500,
        durationS: 2400,
        originName: 'Sealdah Station',
        destinationName: 'College Square',
      );

      final reply = await service.ask('Is the route clear?', route: route);
      expect(reply.answer, contains('Sealdah Station → College Square'));
      expect(reply.answer, contains('3.5 km'));
      expect(reply.answer, contains('40 min'));
      expect(reply.usedLlm, isFalse);
    });
  });
}
