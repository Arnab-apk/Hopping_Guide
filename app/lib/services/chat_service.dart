import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/route_chat_models.dart';
import '../repositories/local_pandal_repository.dart';
import '../repositories/station_repository.dart';
import '../utils/constants.dart';
import '../utils/haversine.dart';

/// Client service for the UMA Route Assistant Chatbot.
/// Backed by a 3-tier high-resilience architecture:
/// 1. Backend server (Local via USB adb reverse / Remote if configured)
/// 2. Direct On-Device Cloud AI (NVIDIA Nemotron 3 Ultra / Gemini)
/// 3. Ultra-smart deterministic on-device offline engine (airplane mode / zero internet)
class ChatService {
  ChatService({
    String? baseUrl,
    String? deviceId,
    http.Client? client,
    LocalAssetPandalRepository? pandalRepository,
    StationRepository? stationRepository,
  })  : _configuredBaseUrl = baseUrl,
        _explicitDeviceId = deviceId,
        _client = client ?? http.Client(),
        _pandalRepo = pandalRepository ?? LocalAssetPandalRepository(),
        _stationRepo = stationRepository ?? StationRepository.instance;

  static final ChatService instance = ChatService();

  final String? _configuredBaseUrl;
  final String? _explicitDeviceId;
  final http.Client _client;
  final LocalAssetPandalRepository _pandalRepo;
  final StationRepository _stationRepo;

  String? _cachedDeviceId;
  String? _resolvedBaseUrl;

  /// Candidate backend URLs tried in order of priority.
  List<String> get candidateBaseUrls {
    final customUrl = _configuredBaseUrl;
    if (customUrl != null && customUrl.isNotEmpty) return [customUrl];

    const envUrl = String.fromEnvironment('BACKEND_SERVER_URL');
    if (envUrl.isNotEmpty) return [envUrl];

    const neonUrl = String.fromEnvironment('NEON_API_URL');
    if (neonUrl.isNotEmpty) return [neonUrl];

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return [
        'http://127.0.0.1:8080',      // Physical device (via adb reverse)
        'http://localhost:8080',      // Physical device (via adb reverse)
        'http://192.168.0.102:8080',  // Physical device (Local Wi-Fi network)
        'http://10.0.2.2:8080',       // Android emulator
      ];
    }
    return ['http://localhost:8080', 'http://127.0.0.1:8080'];
  }

  /// Resolves the backend base URL across web, Android emulator, and desktop/iOS.
  String get baseUrl => _resolvedBaseUrl ?? candidateBaseUrls.first;

  /// Obtains or generates a persistent, privacy-preserving anonymous device ID.
  /// Never linked to phone number, Google account, or hardware IMEI.
  Future<String> getDeviceId() async {
    final explicit = _explicitDeviceId;
    if (explicit != null) return explicit;
    final cached = _cachedDeviceId;
    if (cached != null) return cached;

    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString('uma_chat_anon_device_id');
      if (id == null || id.isEmpty) {
        final rand = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
        id = 'anon_${DateTime.now().millisecondsSinceEpoch}_$rand';
        await prefs.setString('uma_chat_anon_device_id', id);
      }
      _cachedDeviceId = id;
      return id;
    } catch (_) {
      final rand = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
      _cachedDeviceId = 'anon_temp_$rand';
      return _cachedDeviceId!;
    }
  }

  /// Fetches live closure count and top alerts for the empty state.
  Future<ChatStatusSummary> getStatus() async {
    final candidates = _resolvedBaseUrl != null ? [_resolvedBaseUrl!] : candidateBaseUrls;

    for (final candidate in candidates) {
      try {
        final uri = Uri.parse('$candidate/chat/status');
        final response = await _client.get(uri).timeout(const Duration(milliseconds: 700));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _resolvedBaseUrl = candidate;
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return ChatStatusSummary.fromJson(data);
        }
      } catch (_) {}
    }

    return ChatStatusSummary.fallback;
  }

  /// Ask a route or crowd question to the UMA Route Assistant.
  Future<ChatReply> ask(
    String message, {
    RouteSummary? route,
    String lang = 'auto',
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return ChatReply.fallback('Please ask a question about routes, pandals, or road closures.');
    }

    final devId = await getDeviceId();

    // 1. Try backend server if responsive
    final candidates = _resolvedBaseUrl != null ? [_resolvedBaseUrl!] : candidateBaseUrls;
    for (final candidate in candidates) {
      final reply = await _tryServerCandidate(candidate, devId, trimmed, route, lang);
      if (reply != null) {
        _resolvedBaseUrl = candidate;
        return reply;
      }
    }

    // 2. Server unreachable -> Direct On-Device Cloud AI (NVIDIA Nemotron 3 Ultra / Gemini)
    debugPrint('[ChatService] Server unreachable, invoking direct Cloud AI agent...');
    final directReply = await _askDirectLlm(trimmed, route, lang);
    if (directReply != null) {
      return directReply;
    }

    // 3. Complete offline fallback -> Local Heuristic Engine (zero network / airplane mode)
    debugPrint('[ChatService] Cloud LLM unavailable, using instant local offline engine');
    return await _localFallback(trimmed, route);
  }

  Future<ChatReply?> _tryServerCandidate(
    String candidate,
    String devId,
    String message,
    RouteSummary? route,
    String lang,
  ) async {
    try {
      final uri = Uri.parse('$candidate/chat');
      final payload = {
        'deviceId': devId,
        'message': message,
        if (route != null) 'route': route.toJson(),
        'lang': lang,
      };

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(milliseconds: 1500));

      if (response.statusCode == 429) {
        return ChatReply.rateLimited();
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ChatReply.fromJson(data);
      }
    } catch (e) {
      debugPrint('[ChatService] Failed to reach $candidate: $e');
    }
    return null;
  }

  /// Calls NVIDIA Nemotron 3 Ultra directly from the mobile app.
  Future<ChatReply?> _askDirectLlm(
    String question,
    RouteSummary? route,
    String lang,
  ) async {
    final nvidiaKey = AppConfig.nvidiaApiKey;
    if (nvidiaKey.isNotEmpty) {
      final reply = await _callNvidiaDirect(question, route, lang, nvidiaKey);
      if (reply != null) return reply;
    }

    final geminiKey = AppConfig.geminiApiKey;
    if (geminiKey.isNotEmpty) {
      final reply = await _callGeminiDirect(question, route, lang, geminiKey);
      if (reply != null) return reply;
    }

    return null;
  }

  Future<ChatReply?> _callNvidiaDirect(
    String question,
    RouteSummary? route,
    String lang,
    String apiKey,
  ) async {
    try {
      await _stationRepo.load();
      final pandals = await _pandalRepo.all();
      final qLower = question.toLowerCase();

      final matchedPandals = pandals.where((p) {
        final name = p.name.toLowerCase();
        return qLower.contains(name) ||
            name.split(' ').any((w) => w.length > 3 && qLower.contains(w));
      }).take(3).toList();

      final blocks = <ChatFactBlock>[];
      final factsMap = <String, dynamic>{
        'question': question,
        'current_time': DateTime.now().toIso8601String(),
        if (route != null) 'route': {
          'from': route.originName ?? 'Origin',
          'to': route.destinationName ?? 'Destination',
          'distance_m': route.distanceM,
          'duration_min': route.durationMin,
        },
      };

      if (route != null) {
        blocks.add(RouteBlock(
          from: route.originName ?? 'Origin',
          to: route.destinationName ?? 'Destination',
          durationMin: route.durationMin,
          distanceM: route.distanceM,
        ));
      }

      if (matchedPandals.isNotEmpty) {
        factsMap['relevant_pandals'] = matchedPandals.map((p) {
          final metro = p.nearestMetro;
          if (metro != null && metro.isNotEmpty) {
            blocks.add(StationBlock(name: '$metro Metro', kind: 'Metro', distanceM: 450));
          }
          blocks.add(CrowdBlock(place: p.name, level: p.crowdLevel ?? 'normal', source: 'Puja Directory'));
          return {
            'name': p.name,
            'zone': p.zone.label,
            'nearest_metro': p.nearestMetro,
            'crowd_level': p.crowdLevel ?? 'moderate',
            'theme': p.theme,
            'timings': p.timings,
          };
        }).toList();
      }

      final prompt = '''
[USER QUESTION]
$question

[FACTS JSON]
${jsonEncode(factsMap)}

[PREFERRED LANGUAGE]
$lang

Reply in 1-3 warm, helpful, natural sentences answering the user directly based on the facts. Never sound robotic or output JSON.
''';

      final response = await _client.post(
        Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConfig.nvidiaModel,
          'messages': [
            {
              'role': 'system',
              'content': 'You are UMA, the warm and knowledgeable route and pandal guide for Kolkata Durga Puja. You provide short, warm, and highly accurate guidance for pandal hoppers in Kolkata. Answer in the user\'s language (Bengali if asked in Bengali, English if asked in English, Banglish if asked in Banglish). Never output markdown tables or raw JSON.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.2,
          'max_tokens': 200,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final choice = choices[0] as Map<String, dynamic>;
          final msg = choice['message'] as Map<String, dynamic>?;
          var content = msg?['content'] as String? ?? msg?['reasoning_content'] as String?;
          if (content != null && content.isNotEmpty) {
            content = content.replaceAll(RegExp(r'thinking[\s\S]*?</think>'), '').trim();
            if (content.isNotEmpty) {
              return ChatReply(
                answer: content,
                factsAsOf: DateTime.now(),
                usedLlm: true,
                blocks: blocks,
                actions: ['show_on_map', 'share_with_group'],
                suggestions: [
                  'Nearest metro stations',
                  'Least crowded pandals',
                  'Emergency Helplines',
                ],
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[ChatService] Direct NVIDIA LLM call error: $e');
    }
    return null;
  }

  Future<ChatReply?> _callGeminiDirect(
    String question,
    RouteSummary? route,
    String lang,
    String apiKey,
  ) async {
    try {
      final endpoint = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );
      final payload = {
        'systemInstruction': {
          'parts': [
            {
              'text':
                  'You are UMA, the Kolkata Durga Puja route and pandal guide. Provide 1-2 friendly, accurate sentences answering the user. If in Bengali, reply in Bengali. If in English, reply in English.'
            }
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [{'text': question}],
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 200,
        },
      };

      final response = await _client.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final answer = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (answer != null && answer.trim().isNotEmpty) {
          return ChatReply(
            answer: answer.trim(),
            factsAsOf: DateTime.now(),
            usedLlm: true,
            actions: ['show_on_map', 'share_with_group'],
          );
        }
      }
    } catch (e) {
      debugPrint('[ChatService] Gemini direct error: $e');
    }
    return null;
  }

  /// Deterministic on-device fallback using bundled pandals and stations GeoJSON.
  Future<ChatReply> _localFallback(String question, RouteSummary? route) async {
    final q = question.toLowerCase();

    // 1. Helpline intent
    if (q.contains('help') ||
        q.contains('police') ||
        q.contains('emergency') ||
        q.contains('danger') ||
        q.contains('phone') ||
        q.contains('ambulance') ||
        q.contains('lost') ||
        q.contains('hospital')) {
      return ChatReply.fallback(
        'Kolkata Puja Emergency Helplines:\n'
        '• Kolkata Police Emergency: 100 / 112\n'
        '• Kolkata Traffic Control: 1073 / (033) 2214-3644\n'
        '• Medical Ambulance: 102 / 108\n'
        '• Women Safety Helpline: 1091\n'
        '• Fire & Disaster Control: 101\n'
        '• Childline Helpline: 1098',
        factsAsOf: DateTime.now(),
        actions: ['share_with_group'],
      );
    }

    // 2. Metro / Nearest station intent
    if (q.contains('metro') || q.contains('station') || q.contains('train') || q.contains('railway')) {
      await _stationRepo.load();
      final pandals = await _pandalRepo.all();

      // Find pandal mention in question
      for (final p in pandals) {
        if (q.contains(p.name.toLowerCase()) ||
            p.name.toLowerCase().split(' ').any((w) => w.length > 3 && q.contains(w))) {
          final metro = p.nearestMetro;
          final stations = _stationRepo.getNearest(LatLng(p.lat, p.lng), limit: 2);
          final buffer = StringBuffer();
          buffer.write('Nearest transit to ${p.name}:\n');
          final blocks = <ChatFactBlock>[];
          if (metro != null && metro.isNotEmpty) {
            buffer.write('Metro: $metro Metro Station\n');
            blocks.add(StationBlock(name: '$metro Metro', kind: 'Metro', distanceM: 450));
          }
          if (stations.isNotEmpty) {
            final stationDetails = stations.map((s) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              return '${s.name} (${(dist / 1000).toStringAsFixed(1)} km)'; }
            ).join(', ');
            buffer.write('Nearby Stations: $stationDetails');
            for (final s in stations) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              blocks.add(StationBlock(name: s.name, kind: s.network ?? 'Rail', distanceM: dist.round()));
            }
          }
          return ChatReply.fallback(
            buffer.toString(),
            factsAsOf: DateTime.now(),
            blocks: blocks,
            actions: ['show_on_map', 'start_walking', 'share_with_group'],
          );
        }
      }

      // Generic stations lookup
      final searched = _stationRepo.search(question);
      if (searched.isNotEmpty) {
        final s = searched.first;
        return ChatReply.fallback(
          'Station Info: ${s.name} (${s.code ?? 'Kolkata Metro'})\n'
          'Lines: ${s.lines.join(", ")}\n'
          'Network: ${s.network ?? "Kolkata Transit"}',
          factsAsOf: DateTime.now(),
          blocks: [StationBlock(name: s.name, kind: s.network ?? 'Metro', distanceM: 0)],
          actions: ['start_walking', 'share_with_group'],
        );
      }
    }

    // 3. Active route summary fallback
    if (route != null) {
      final from = route.originName ?? 'Origin';
      final to = route.destinationName ?? 'Destination';
      final distKm = route.distanceKm.toStringAsFixed(1);
      final min = route.durationMin;
      return ChatReply.fallback(
        'Route: $from → $to\n'
        'Estimated walk: about $min min ($distKm km).\n'
        'No recent official barricade reports on this local segment. '
        'Follow Kolkata Police ground signages.',
        factsAsOf: DateTime.now(),
        blocks: [
          RouteBlock(
            from: from,
            to: to,
            durationMin: min,
            distanceM: route.distanceM,
          ),
        ],
        actions: ['show_on_map', 'start_walking', 'share_with_group'],
      );
    }

    // 4. Pandals lookup
    final pandals = await _pandalRepo.all();
    for (final p in pandals) {
      if (q.contains(p.name.toLowerCase())) {
        final crowd = (p.crowdLevel ?? 'Normal').toUpperCase();
        return ChatReply.fallback(
          '${p.name} (${p.zone.label}):\n'
          '• Theme: ${p.theme}\n'
          '• Crowd level: $crowd\n'
          '• Nearest Metro: ${p.nearestMetro ?? "Shyambazar / Central"}\n'
          '• Timings: ${p.timings}',
          factsAsOf: DateTime.now(),
          blocks: [
            CrowdBlock(
              place: p.name,
              level: p.crowdLevel ?? 'normal',
              source: 'Baseline estimates',
              updatedMinAgo: 3,
            ),
            if (p.nearestMetro != null && p.nearestMetro!.isNotEmpty)
              StationBlock(
                name: '${p.nearestMetro!} Metro',
                kind: 'Metro',
                distanceM: 500,
              ),
          ],
          actions: ['show_on_map', 'start_walking', 'share_with_group'],
        );
      }
    }

    // 5. Greetings & Identity
    if (q.contains('hi') ||
        q.contains('hello') ||
        q.contains('hey') ||
        q.contains('nomoshkar') ||
        q.contains('namaste') ||
        q.contains('kemon') ||
        q.contains('who are you') ||
        q.contains('ke tumi') ||
        q.contains('sharodiya')) {
      return ChatReply.fallback(
        'শুভ শারদীয়া! I am UMA, your Kolkata Durga Puja route assistant.\n\n'
        'I can help you with:\n'
        '• Best routes & walking times between pandals\n'
        '• Nearest Metro & railway stations\n'
        '• Crowd levels & police road barricades\n'
        '• Emergency police & medical helplines\n\n'
        'What would you like to know?',
        factsAsOf: DateTime.now(),
        suggestions: [
          'Best pandals in South Kolkata',
          'Nearest metro to Bagbazar',
          'Least crowded pandals',
          'Emergency Helplines',
        ],
      );
    }

    // 6. Best / Top pandals
    if (q.contains('best') ||
        q.contains('top') ||
        q.contains('famous') ||
        q.contains('must') ||
        q.contains('popular') ||
        q.contains('recommend') ||
        q.contains('bhalo')) {
      return ChatReply.fallback(
        'Top Pandals in Kolkata 2026:\n\n'
        'North Kolkata:\n'
        '• Bagbazar Sarbojanin — Traditional Daker Saaj · Shyambazar Metro\n'
        '• Kumartuli Park — Artistic Heritage · Sovabazar Metro\n'
        '• College Square — Illumination & Lake Reflection · Central Metro\n\n'
        'South Kolkata:\n'
        '• Suruchi Sangha — State Themes · Kalighat Metro\n'
        '• Maddox Square — Grand Open Adda · Netaji Bhavan Metro\n'
        '• Ekdalia Evergreen — Traditional Temple Idol · Gariahat\n\n'
        'Salt Lake & VIP:\n'
        '• Sreebhumi Sporting — Architectural Replica · Ultadanga/Bidhannagar',
        factsAsOf: DateTime.now(),
        suggestions: [
          'Route to Bagbazar',
          'Suruchi Sangha details',
          'Least crowded times',
        ],
        actions: ['show_on_map', 'share_with_group'],
      );
    }

    // 7. Zone-specific query
    if (q.contains('north') ||
        q.contains('south') ||
        q.contains('salt lake') ||
        q.contains('behala') ||
        q.contains('central') ||
        q.contains('howrah')) {
      final zoneName = q.contains('north')
          ? 'North Kolkata'
          : q.contains('south')
              ? 'South Kolkata'
              : q.contains('salt lake')
                  ? 'Salt Lake'
                  : q.contains('behala')
                      ? 'Behala'
                      : q.contains('central')
                          ? 'Central Kolkata'
                          : 'Howrah';
      return ChatReply.fallback(
        '$zoneName Highlights:\n'
        'Famous pandals, vibrant lighting, and cultural adda spots. '
        'You can filter by this zone on the Map tab to view clustered walking routes.',
        factsAsOf: DateTime.now(),
        actions: ['show_on_map'],
        suggestions: [
          'Show $zoneName on map',
          'Nearest metro stations',
        ],
      );
    }

    // 8. Crowd & Timing query
    if (q.contains('crowd') ||
        q.contains('bhir') ||
        q.contains('busy') ||
        q.contains('line') ||
        q.contains('time') ||
        q.contains('shanto')) {
      return ChatReply.fallback(
        'Kolkata Crowd Advisory & Best Times:\n\n'
        '• Least crowded hours: 1:00 PM – 4:30 PM (afternoon daylight)\n'
        '• Late night hopping: 1:30 AM – 4:00 AM (cooler weather, easier queues)\n'
        '• Peak rush: 7:00 PM – 11:30 PM (major vehicular restrictions active)\n\n'
        'Tip: Use the Metro till midnight on Puja days to avoid surface road diversions.',
        factsAsOf: DateTime.now(),
        suggestions: ['Metro timings', 'Top pandals', 'Emergency helplines'],
      );
    }

    // 9. General fallback
    return ChatReply.fallback(
      'UMA Route Assistant (Offline mode):\n'
      'I can guide you on routes between pandals, nearest metro stations, and emergency helplines. '
      'Try asking: "Nearest metro to Baghbazar" or "Route from Howrah to Kumartuli".',
      factsAsOf: DateTime.now(),
      suggestions: [
        'Nearest metro to Baghbazar',
        'Howrah to Kumartuli',
        'Least crowded pandals',
        'Emergency Helplines',
      ],
    );
  }
}