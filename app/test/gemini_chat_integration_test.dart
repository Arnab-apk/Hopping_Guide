import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolkata_puja/config/app_config.dart';
import 'package:kolkata_puja/services/chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Gemini uses header authentication and supported-model fallback',
    () async {
      var requests = 0;
      final service = ChatService(
        deviceId: 'gemini_test',
        client: MockClient((request) async {
          requests++;
          expect(request.url.host, 'generativelanguage.googleapis.com');
          expect(request.url.queryParameters.containsKey('key'), isFalse);
          expect(request.headers['x-goog-api-key'], AppConfig.geminiApiKey);
          if (requests == 1) return http.Response('{}', 503);
          expect(request.url.path, contains('gemini-flash-lite-latest'));
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Walk to your next pandal.'},
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }),
      );
      final reply = await service.ask('Help plan a walk');
      expect(reply.usedLlm, isTrue);
      expect(reply.answer, 'Walk to your next pandal.');
      expect(requests, 2);
    },
    skip: AppConfig.geminiApiKey.isEmpty
        ? 'Run with --dart-define=GEMINI_API_KEY=test-key (no live key needed).'
        : false,
  );
}
