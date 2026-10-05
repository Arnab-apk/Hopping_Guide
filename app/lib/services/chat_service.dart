import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/pandal.dart';
import '../models/route_chat_models.dart';
import '../repositories/local_pandal_repository.dart';
import '../repositories/station_repository.dart';
import '../utils/constants.dart';
import '../utils/haversine.dart';

/// Language format detected for user queries.
enum QueryLanguage {
  bengali,  // Bengali script (বাংলা)
  benglish, // Bengali language in Latin/English letters (Banglish)
  english,
}

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
  final List<DateTime> _directRequestTimes = <DateTime>[];
  bool _directRequestInFlight = false;

  static const int _maxMessageLength = 800;
  static const int _maxDirectRequestsPerMinute = 6;

  static final RegExp _unsafeRequestPattern = RegExp(
    r'\b(?:make|build|write|create|give me)\b.*\b(?:bomb|weapon|explosive|malware|ransomware|virus)\b'
    r'|\b(?:self[- ]harm|suicide|kill myself|hurt myself)\b',
    caseSensitive: false,
  );

  /// Mapping for Bengali script and colloquial Benglish names to standard pandal name substrings.
  static const Map<String, String> _pandalAliases = {
    // Bengali script (বাংলা)
    'বাগবাজার': 'bagbazar',
    'কুমারটুলি': 'kumartuli',
    'কলেজ স্কোয়ার': 'college square',
    'মহম্মদ আলী': 'mohammad ali',
    'সন্তোষ মিত্র': 'santosh mitra',
    'সুরুচি': 'suruchi',
    'চেতলা': 'chetla',
    'শ্রীভূমি': 'sreebhumi',
    'ম্যাডক্স': 'maddox',
    'একডালিয়া': 'ekdalia',
    'সিংহী পার্ক': 'singhi park',
    'বালিগঞ্জ': 'ballygunge',
    'যোধপুর পার্ক': 'jodhpur park',
    'মুদিয়ালী': 'mudiali',
    'শিব মন্দির': 'shib mandir',
    'বোসপুকুর': 'bosepukur',
    'নাকতলা': 'naktala',
    'বেহালা': 'behala',
    'বড়িশা': 'barisha',
    'টালা প্রত্যয়': 'tala prattoy',
    'কাশী বোস': 'kashi bose',
    'হাতিবাগান': 'hatibagan',
    'দমদম': 'dum dum',
    'এফডি ব্লক': 'fd block',
    'বাবুবাগান': 'babubagan',
    'সেলিমপুর': 'selimpur',
    'শোভাবাজার': 'sovabazar',
    'অহীন্দ্র': 'ahindra',
    'আলিপুর': 'alipore',
    // Benglish / Banglish spelling variants
    'sribhumi': 'sreebhumi',
    'sribhoomi': 'sreebhumi',
    'shreebhumi': 'sreebhumi',
    'baghbazar': 'bagbazar',
    'lebutala': 'santosh mitra',
    'kumortuli': 'kumartuli',
    'ekdalia evergreen': 'ekdalia',
    'maddox square': 'maddox',
    'suruchi sangha': 'suruchi',
  };

  /// Detects whether a query is written in Bengali script (বাংলা),
  /// Benglish (Banglish - Bengali in Latin/Roman alphabet), or English.
  static QueryLanguage detectLanguage(String text) {
    if (text.isEmpty) return QueryLanguage.english;

    // 1. Bengali Unicode script block: U+0980 to U+09FF
    if (RegExp(r'[\u0980-\u09FF]').hasMatch(text)) {
      return QueryLanguage.bengali;
    }

    // 2. Benglish / Banglish vocabulary & distinctive Bengali linguistic tokens
    final benglishPattern = RegExp(
      r'\b(?:kothay|kothaye|konta|kemon|achen|acho|achi|tumi|apni|amra|tora|'
      r'bhir|bhidd|pujo|mondop|thakur|protima|rasta|bondho|khola|'
      r'kache|kacher|jabo|jabe|dekhte|achhe|ache|shobcheye|seraa|sera|bhalo|'
      r'notun|somoy|koto|khabar|adda|pulis|saaj|ghurbo|ghurte|shuru|'
      r'sesh|sharodiya|nomoshkar|namashkar|bhai|dada|didi|suvo|shubho|'
      r'uttar|dakkhin|hocche|parbo|dao|bolun|bolo|korbo|koro|korun|'
      r'pujor|pandaler|rastar|police-er|policeer|metror|kina|gulo|gulor)\b',
      caseSensitive: false,
    );

    if (benglishPattern.hasMatch(text)) {
      return QueryLanguage.benglish;
    }

    return QueryLanguage.english;
  }

  static QueryLanguage _resolveLang(String lang) {
    final l = lang.toLowerCase().trim();
    if (l == 'bn' || l == 'bengali' || l == 'bangla') {
      return QueryLanguage.bengali;
    }
    if (l == 'benglish' || l == 'banglish') {
      return QueryLanguage.benglish;
    }
    return QueryLanguage.english;
  }

  static String _langToString(QueryLanguage lang) {
    switch (lang) {
      case QueryLanguage.bengali:
        return 'bn';
      case QueryLanguage.benglish:
        return 'benglish';
      case QueryLanguage.english:
        return 'en';
    }
  }

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
    if (trimmed.length > _maxMessageLength) {
      return ChatReply.error(
        message: 'Please keep your question under $_maxMessageLength characters.',
      );
    }
    if (_unsafeRequestPattern.hasMatch(trimmed)) {
      return ChatReply.fallback(
        'I can help with Kolkata pandals, routes, metro stations, food spots, '
        'crowd-aware planning, and festival safety, but I cannot help create '
        'weapons or assist with harming anyone.',
        actions: const ['share_with_group'],
      );
    }

    final queryLang = lang == 'auto' ? detectLanguage(trimmed) : _resolveLang(lang);
    final devId = await getDeviceId();

    // Prefer the configured direct model so a reachable local backend cannot
    // silently return a basic/offline answer instead.
    final configuredLlmReply = await _askDirectLlm(trimmed, route, queryLang);
    if (configuredLlmReply != null) {
      return configuredLlmReply;
    }

    // 1. Try backend server if responsive
    final candidates = _resolvedBaseUrl != null ? [_resolvedBaseUrl!] : candidateBaseUrls;
    for (final candidate in candidates) {
      final reply = await _tryServerCandidate(
        candidate,
        devId,
        trimmed,
        route,
        _langToString(queryLang),
      );
      if (reply != null) {
        _resolvedBaseUrl = candidate;
        return reply;
      }
    }

    // 2. Complete offline fallback -> Local Heuristic Engine
    debugPrint('[ChatService] Cloud LLM unavailable, using instant local offline engine for ${queryLang.name}');
    return await _localFallback(trimmed, route, queryLang);
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

  /// Calls NVIDIA Nemotron 3 Ultra or Gemini directly from the mobile app.
  Future<ChatReply?> _askDirectLlm(
    String question,
    RouteSummary? route,
    QueryLanguage queryLang,
  ) async {
    final now = DateTime.now();
    _directRequestTimes.removeWhere(
      (time) => now.difference(time) >= const Duration(minutes: 1),
    );
    if (_directRequestInFlight ||
        _directRequestTimes.length >= _maxDirectRequestsPerMinute) {
      return ChatReply.rateLimited(
        message: 'Please wait a moment before asking another assistant question.',
      );
    }
    _directRequestTimes.add(now);
    _directRequestInFlight = true;

    try {
      final nvidiaKey = AppConfig.nvidiaApiKey;
      if (nvidiaKey.isNotEmpty) {
        final reply = await _callNvidiaDirect(question, route, queryLang, nvidiaKey);
        if (reply != null) return reply;
      }

      final geminiKey = AppConfig.geminiApiKey;
      if (geminiKey.isNotEmpty) {
        final reply = await _callGeminiDirect(question, route, queryLang, geminiKey);
        if (reply != null) return reply;
      }

      return null;
    } finally {
      _directRequestInFlight = false;
    }
  }

  /// Finds pandals matching query directly by name, word tokens, or alias keywords.
  List<Pandal> _findMatchingPandals(List<Pandal> pandals, String question) {
    final qLower = question.toLowerCase();

    final matchedAliasTargets = <String>[];
    for (final entry in _pandalAliases.entries) {
      if (qLower.contains(entry.key.toLowerCase())) {
        matchedAliasTargets.add(entry.value.toLowerCase());
      }
    }

    return pandals.where((p) {
      final nameLower = p.name.toLowerCase();
      if (qLower.contains(nameLower)) return true;
      if (nameLower.split(' ').any((w) => w.length > 3 && qLower.contains(w))) return true;
      for (final target in matchedAliasTargets) {
        if (nameLower.contains(target)) return true;
      }
      return false;
    }).toList();
  }

  Future<ChatReply?> _callNvidiaDirect(
    String question,
    RouteSummary? route,
    QueryLanguage queryLang,
    String apiKey,
  ) async {
    try {
      await _stationRepo.load();
      final pandals = await _pandalRepo.all();
      final matchedPandals = _findMatchingPandals(pandals, question).take(3).toList();

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

      String systemContent;
      switch (queryLang) {
        case QueryLanguage.bengali:
          systemContent =
              'You are UMA, the warm, knowledgeable Kolkata Durga Puja companion. '
              'The user is asking in Bengali script (বাংলা). You MUST answer completely in polite, '
              'natural, culturally authentic Bengali script (বাংলা হরফে উত্তর দিন). '
              'Give clear route, metro, pandal, and crowd facts. Never use English or Latin letters in the reply text. '
              'Never output raw JSON or markdown tables.';
          break;
        case QueryLanguage.benglish:
          systemContent =
              'You are UMA, the warm and friendly Kolkata Durga Puja companion. '
              'The user is asking in Benglish (Banglish - conversational Bengali written in English/Latin letters). '
              'You MUST reply in conversational, authentic Kolkata Benglish/Banglish '
              '(e.g., "Bagbazar Sarbojanin-er kacher metro holo Shyambazar. Ekhon bhir beshi nei, apnara shondhye 6tar aage pouchhole aram se thakur dekhte parben."). '
              'Do not reply in formal English or Bengali script. Never output raw JSON or markdown tables.';
          break;
        case QueryLanguage.english:
          systemContent =
              'You are UMA, the warm and knowledgeable route and pandal guide for Kolkata Durga Puja. '
              'You provide short, warm, and highly accurate guidance for pandal hoppers in Kolkata. '
              'Answer in fluent, friendly English with authentic local context. Never output markdown tables or raw JSON.';
          break;
      }

      final prompt = '''
[USER QUESTION]
$question

[FACTS JSON]
${jsonEncode(factsMap)}

[DETECTED LANGUAGE]
${queryLang.name}

Reply in 1-3 warm, helpful, natural sentences answering the user directly based on the facts in the user's language.
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
            {'role': 'system', 'content': systemContent},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.2,
          'max_tokens': 240,
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
                suggestions: _buildSuggestionsForLang(queryLang),
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
    QueryLanguage queryLang,
    String apiKey,
  ) async {
    try {
      await _stationRepo.load();
      final pandals = await _pandalRepo.all();
      final matchedPandals = _findMatchingPandals(pandals, question).take(5).toList();

      final mentionedPandals = matchedPandals
          .map(
            (p) => {
              'name': p.name,
              'area': p.area,
              'latitude': p.lat,
              'longitude': p.lng,
              'nearest_metro': p.nearestMetro,
              'crowd_level': p.crowdLevel,
              'theme': p.theme,
            },
          )
          .toList();

      final context = <String, dynamic>{
        'current_time': DateTime.now().toIso8601String(),
        'known_pandals': mentionedPandals,
        if (route != null)
          'route': {
            'from': route.originName,
            'to': route.destinationName,
            'distance_m': route.distanceM,
            'duration_min': route.durationMin,
          },
      };

      String systemDirective;
      switch (queryLang) {
        case QueryLanguage.bengali:
          systemDirective =
              'You are UMA, a warm, practical Kolkata Durga Puja companion. '
              'The user query is in Bengali script (বাংলা). You MUST answer completely in polite, '
              'natural, culturally authentic Bengali script (বাংলা হরফে উত্তর দিন). '
              'Give the most useful route, metro, or pandal answer first. Never output English text, raw JSON or tables.';
          break;
        case QueryLanguage.benglish:
          systemDirective =
              'You are UMA, a warm, practical Kolkata Durga Puja companion. '
              'The user query is in Benglish (Banglish - conversational Bengali written in English letters). '
              'You MUST answer in conversational, authentic Kolkata Benglish/Banglish '
              '(e.g., "Bagbazar-er kacher metro Shyambazar. Ekhon bhir moderate ache."). '
              'Never output formal English, Bengali script, or raw JSON.';
          break;
        case QueryLanguage.english:
          systemDirective =
              'You are UMA, a warm, practical Kolkata Durga Puja companion. '
              'Answer naturally, like a helpful local friend in English. Keep answers concise (2-4 sentences), '
              'never invent closures or crowd facts. Never output raw JSON or tables.';
          break;
      }

      final endpoint = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/${AppConfig.geminiModel}:generateContent?key=$apiKey',
      );
      final payload = {
        'systemInstruction': {
          'parts': [
            {'text': systemDirective}
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text':
                    'User question:\n$question\n\nVerified app context:\n${jsonEncode(context)}',
              }
            ],
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'topP': 0.9,
          'maxOutputTokens': 350,
        },
      };

      final response = await _client.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 429) {
        return ChatReply.rateLimited(
          message: queryLang == QueryLanguage.bengali
              ? 'সার্ভিসটি এই মুহূর্তে ব্যস্ত। অনুগ্রহ করে একটু পরে আবার চেষ্টা করুন।'
              : queryLang == QueryLanguage.benglish
                  ? 'Service ekhon ektu busy ache. Ektu pore abar try korun.'
                  : 'Assistant is busy right now. Please try again in a little while.',
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        String? answer;
        if (candidates != null && candidates.isNotEmpty) {
          final firstCandidate = candidates.first;
          if (firstCandidate is Map<String, dynamic>) {
            final content = firstCandidate['content'];
            if (content is Map<String, dynamic>) {
              final parts = content['parts'];
              if (parts is List && parts.isNotEmpty && parts.first is Map<String, dynamic>) {
                answer = (parts.first as Map<String, dynamic>)['text'] as String?;
              }
            }
          }
        }
        if (answer != null && answer.trim().isNotEmpty) {
          return ChatReply(
            answer: answer.trim(),
            factsAsOf: DateTime.now(),
            usedLlm: true,
            actions: ['show_on_map', 'share_with_group'],
            suggestions: _buildSuggestionsForLang(queryLang),
          );
        }
      }
    } catch (e) {
      debugPrint('[ChatService] Gemini direct error: $e');
    }
    return null;
  }

  static List<String> _buildSuggestionsForLang(QueryLanguage lang) {
    switch (lang) {
      case QueryLanguage.bengali:
        return [
          'কোথায় ভিড় কম?',
          'নিকটবর্তী মেট্রো স্টেশন',
          'সেরা পুজো কোনগুলো?',
          'জরুরি হেল্পলাইন',
        ];
      case QueryLanguage.benglish:
        return [
          'Kothay bhir kom?',
          'Kacher metro station',
          'Top pandals 2026',
          'Emergency helpline',
        ];
      case QueryLanguage.english:
        return [
          'Nearest metro stations',
          'Least crowded pandals',
          'Top pandals 2026',
          'Emergency Helplines',
        ];
    }
  }

  /// Deterministic on-device fallback using bundled pandals and stations GeoJSON.
  /// Supports Bengali script (বাংলা), Benglish (Banglish), and English with high fidelity.
  Future<ChatReply> _localFallback(
    String question,
    RouteSummary? route, [
    QueryLanguage? explicitLang,
  ]) async {
    final lang = explicitLang ?? detectLanguage(question);
    final q = question.toLowerCase();

    // 1. Helpline / Emergency intent
    if (q.contains('help') ||
        q.contains('police') ||
        q.contains('pulis') ||
        q.contains('emergency') ||
        q.contains('danger') ||
        q.contains('phone') ||
        q.contains('phn') ||
        q.contains('ambulance') ||
        q.contains('lost') ||
        q.contains('hospital') ||
        q.contains('সাহায্য') ||
        q.contains('পুলিশ') ||
        q.contains('জরুরি') ||
        q.contains('বিপদ') ||
        q.contains('ফোন') ||
        q.contains('অ্যাম্বুলেন্স') ||
        q.contains('হাসপাতাল') ||
        q.contains('হারিয়ে') ||
        q.contains('sahajjo') ||
        q.contains('joruri') ||
        q.contains('bipod')) {
      if (lang == QueryLanguage.bengali) {
        return ChatReply.fallback(
          'কলকাতা পূজা জরুরি হেল্পলাইন:\n'
          '• কলকাতা পুলিশ ইমার্জেন্সি: ১০০ / ১১২\n'
          '• কলকাতা ট্রাফিক কন্ট্রোল: ১০৭৩ / (০৩৩) ২২১৪-৩৬৪৪\n'
          '• মেডিকেল অ্যাম্বুলেন্স: ১০২ / ১০৮\n'
          '• মহিলা সুরক্ষা হেল্পলাইন: ১০৯১\n'
          '• দমকল ও বিপর্যয় মোকাবিলা: ১০১\n'
          '• চাইল্ডলাইন: ১০৯৮\n'
          'যেকোনো বিপদে সরাসরি এই নম্বরগুলিতে যোগাযোগ করুন।',
          factsAsOf: DateTime.now(),
          actions: ['share_with_group'],
          suggestions: _buildSuggestionsForLang(lang),
        );
      } else if (lang == QueryLanguage.benglish) {
        return ChatReply.fallback(
          'Kolkata Pujo Emergency Helplines:\n'
          '• Kolkata Police Emergency: 100 / 112\n'
          '• Traffic Police Control: 1073 / (033) 2214-3644\n'
          '• Medical Ambulance: 102 / 108\n'
          '• Women Safety Helpline: 1091\n'
          '• Fire & Disaster Control: 101\n'
          '• Childline Helpline: 1098\n'
          'Kono emergency-te ei number gulo-te direct call korun.',
          factsAsOf: DateTime.now(),
          actions: ['share_with_group'],
          suggestions: _buildSuggestionsForLang(lang),
        );
      } else {
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
          suggestions: _buildSuggestionsForLang(lang),
        );
      }
    }

    // 2. Metro / Transit intent
    if (q.contains('metro') ||
        q.contains('station') ||
        q.contains('train') ||
        q.contains('railway') ||
        q.contains('rail') ||
        q.contains('মেট্রো') ||
        q.contains('স্টেশন') ||
        q.contains('ট্রেন') ||
        q.contains('রেল')) {
      await _stationRepo.load();
      final pandals = await _pandalRepo.all();
      final matchedPandals = _findMatchingPandals(pandals, question);

      if (matchedPandals.isNotEmpty) {
        final p = matchedPandals.first;
        final metro = p.nearestMetro;
        final stations = _stationRepo.getNearest(LatLng(p.lat, p.lng), limit: 2);
        final buffer = StringBuffer();
        final blocks = <ChatFactBlock>[];

        if (lang == QueryLanguage.bengali) {
          buffer.write('${p.name}-এর নিকটবর্তী যাতায়াত:\n');
          if (metro != null && metro.isNotEmpty) {
            buffer.write('• মেট্রো: $metro মেট্রো স্টেশন (হাঁটা পথ প্রায় ৪৫০ মি)\n');
            blocks.add(StationBlock(name: '$metro Metro', kind: 'Metro', distanceM: 450));
          }
          if (stations.isNotEmpty) {
            final stationDetails = stations.map((s) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              return '${s.name} (${(dist / 1000).toStringAsFixed(1)} কিমি)';
            }).join(', ');
            buffer.write('• কাছাকাছি স্টেশন: $stationDetails');
            for (final s in stations) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              blocks.add(StationBlock(name: s.name, kind: s.network ?? 'Rail', distanceM: dist.round()));
            }
          }
        } else if (lang == QueryLanguage.benglish) {
          buffer.write('${p.name}-er kacher transit options:\n');
          if (metro != null && metro.isNotEmpty) {
            buffer.write('• Metro: $metro Metro Station (Paye hete pray 450 m)\n');
            blocks.add(StationBlock(name: '$metro Metro', kind: 'Metro', distanceM: 450));
          }
          if (stations.isNotEmpty) {
            final stationDetails = stations.map((s) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              return '${s.name} (${(dist / 1000).toStringAsFixed(1)} km)';
            }).join(', ');
            buffer.write('• Kacher Station: $stationDetails');
            for (final s in stations) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              blocks.add(StationBlock(name: s.name, kind: s.network ?? 'Rail', distanceM: dist.round()));
            }
          }
        } else {
          buffer.write('Nearest transit to ${p.name}:\n');
          if (metro != null && metro.isNotEmpty) {
            buffer.write('Metro: $metro Metro Station\n');
            blocks.add(StationBlock(name: '$metro Metro', kind: 'Metro', distanceM: 450));
          }
          if (stations.isNotEmpty) {
            final stationDetails = stations.map((s) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              return '${s.name} (${(dist / 1000).toStringAsFixed(1)} km)';
            }).join(', ');
            buffer.write('Nearby Stations: $stationDetails');
            for (final s in stations) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              blocks.add(StationBlock(name: s.name, kind: s.network ?? 'Rail', distanceM: dist.round()));
            }
          }
        }

        return ChatReply.fallback(
          buffer.toString(),
          factsAsOf: DateTime.now(),
          blocks: blocks,
          actions: ['show_on_map', 'start_walking', 'share_with_group'],
          suggestions: _buildSuggestionsForLang(lang),
        );
      }

      // Generic station search
      final searched = _stationRepo.search(question);
      if (searched.isNotEmpty) {
        final s = searched.first;
        final answer = lang == QueryLanguage.bengali
            ? 'স্টেশন তথ্য: ${s.name} (${s.code ?? 'কলকাতা মেট্রো'})\n'
              'লাইন: ${s.lines.join(", ")}\n'
              'নেটওয়ার্ক: ${s.network ?? "কলকাতা ট্রানজিট"}'
            : lang == QueryLanguage.benglish
                ? 'Station Info: ${s.name} (${s.code ?? "Kolkata Metro"})\n'
                  'Lines: ${s.lines.join(", ")}\n'
                  'Network: ${s.network ?? "Kolkata Transit"}'
                : 'Station Info: ${s.name} (${s.code ?? 'Kolkata Metro'})\n'
                  'Lines: ${s.lines.join(", ")}\n'
                  'Network: ${s.network ?? "Kolkata Transit"}';
        return ChatReply.fallback(
          answer,
          factsAsOf: DateTime.now(),
          blocks: [StationBlock(name: s.name, kind: s.network ?? 'Metro', distanceM: 0)],
          actions: ['start_walking', 'share_with_group'],
          suggestions: _buildSuggestionsForLang(lang),
        );
      }
    }

    // 3. Active route summary fallback
    if (route != null) {
      final from = route.originName ?? 'Origin';
      final to = route.destinationName ?? 'Destination';
      final distKm = route.distanceKm.toStringAsFixed(1);
      final min = route.durationMin;

      final text = lang == QueryLanguage.bengali
          ? 'রুট: $from → $to\n'
            'আনুমানিক হাঁটার সময়: প্রায় $min মিনিট ($distKm কিমি)।\n'
            'বর্তমানে এই রুটে কোনো সরকারি রোড ব্যারিকেড বা ব্লকেজ রিপোর্ট নেই। পুলিশ সাইনেজ অনুসরণ করুন।'
          : lang == QueryLanguage.benglish
              ? 'Route: $from theke $to\n'
                'Paye hete somoy: pray $min min ($distKm km).\n'
                'Ekhon ei rastay kono police barricade ba blockage report nei. Kolkata Police er signage follow korun.'
              : 'Route: $from → $to\n'
                'Estimated walk: about $min min ($distKm km).\n'
                'No recent official barricade reports on this local segment. '
                'Follow Kolkata Police ground signages.';

      return ChatReply.fallback(
        text,
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
        suggestions: _buildSuggestionsForLang(lang),
      );
    }

    // 4. Pandals lookup
    final pandals = await _pandalRepo.all();
    final matched = _findMatchingPandals(pandals, question);
    if (matched.isNotEmpty) {
      final p = matched.first;
      final crowd = (p.crowdLevel ?? 'Normal').toUpperCase();

      String answerText;
      if (lang == QueryLanguage.bengali) {
        final crowdBn = p.crowdLevel == 'high'
            ? 'অত্যধিক ভিড়'
            : p.crowdLevel == 'low'
                ? 'কম ভিড়'
                : 'স্বাভাবিক';
        answerText =
            '${p.name} (${p.zone.label}):\n'
            '• থিম: ${p.theme}\n'
            '• ভিড়ের মাত্রা: $crowdBn\n'
            '• নিকটবর্তী মেট্রো: ${p.nearestMetro ?? "শ্যামবাজার / সেন্ট্রাল"}\n'
            '• দর্শনের সময়: ${p.timings}';
      } else if (lang == QueryLanguage.benglish) {
        final crowdBeng = p.crowdLevel == 'high'
            ? 'Onek bhir'
            : p.crowdLevel == 'low'
                ? 'Kom bhir'
                : 'Normal bhir';
        answerText =
            '${p.name} (${p.zone.label}):\n'
            '• Theme: ${p.theme}\n'
            '• Bhir er matra: $crowdBeng\n'
            '• Kacher Metro: ${p.nearestMetro ?? "Shyambazar / Central"}\n'
            '• Darshan er somoy: ${p.timings}';
      } else {
        answerText =
            '${p.name} (${p.zone.label}):\n'
            '• Theme: ${p.theme}\n'
            '• Crowd level: $crowd\n'
            '• Nearest Metro: ${p.nearestMetro ?? "Shyambazar / Central"}\n'
            '• Timings: ${p.timings}';
      }

      return ChatReply.fallback(
        answerText,
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
        suggestions: _buildSuggestionsForLang(lang),
      );
    }

    // 5. Greetings & Identity
    final isGreeting = RegExp(
          r'\b(?:hi|hello|hey|nomoshkar|namaste|who\s+are\s+you|ke\s+tumi|ke\s+apni|sharodiya)\b'
          r'|\b(?:kemon\s+acho|kemon\s+achen|kemon\s+achis)\b',
          caseSensitive: false,
        ).hasMatch(q) ||
        q.contains('নমস্কার') ||
        q.contains('কেমন আছ') ||
        q.contains('কেমন আছেন') ||
        q.contains('শুভ শারদীয়া') ||
        q.contains('তুমি কে') ||
        q.contains('আপনি কে') ||
        q.contains('হ্যালো');

    if (isGreeting) {
      if (lang == QueryLanguage.bengali) {
        return ChatReply.fallback(
          'শুভ শারদীয়া! আমি উমা (UMA), আপনার কলকাতা দুর্গাপূজার পার্সোনাল রুট ও প্যান্ডেল গাইড।\n\n'
          'আমি সাহায্য করতে পারি:\n'
          '• বিভিন্ন মণ্ডপের সহজ রুট ও হাঁটার সময়\n'
          '• নিকটবর্তী মেট্রো ও ট্রেন স্টেশন\n'
          '• মণ্ডপের ভিড়ের আপডেট ও পুলিশ রোড ব্যারিকেড\n'
          '• জরুরি পুলিশ ও মেডিকেল হেল্পলাইন\n\n'
          'আপনি কোন মণ্ডপ বা রুট সম্পর্কে জানতে চান?',
          factsAsOf: DateTime.now(),
          suggestions: _buildSuggestionsForLang(lang),
        );
      } else if (lang == QueryLanguage.benglish) {
        return ChatReply.fallback(
          'Shubho Sharodiya! Ami UMA, apnar Kolkata Durga Puja route companion.\n\n'
          'Ami apnake sahajjo korte pari:\n'
          '• Pandaler sohoj route o paye hete jawar somoy\n'
          '• Kacher Metro o train station\n'
          '• Pandale bhir kemon o police rasta bondho ache kina\n'
          '• Emergency police o medical helpline\n\n'
          'Bolun apnar squad er jonno ki jante chan?',
          factsAsOf: DateTime.now(),
          suggestions: _buildSuggestionsForLang(lang),
        );
      } else {
        return ChatReply.fallback(
          'শুভ শারদীয়া! I am UMA, your Kolkata Durga Puja route assistant.\n\n'
          'I can help you with:\n'
          '• Best routes & walking times between pandals\n'
          '• Nearest Metro & railway stations\n'
          '• Crowd levels & police road barricades\n'
          '• Emergency police & medical helplines\n\n'
          'What would you like to know?',
          factsAsOf: DateTime.now(),
          suggestions: _buildSuggestionsForLang(lang),
        );
      }
    }

    // 6. Best / Top pandals
    if (q.contains('best') ||
        q.contains('top') ||
        q.contains('famous') ||
        q.contains('must') ||
        q.contains('popular') ||
        q.contains('recommend') ||
        q.contains('bhalo') ||
        q.contains('sera') ||
        q.contains('seraa') ||
        q.contains('সেরা') ||
        q.contains('ভালো') ||
        q.contains('বিখ্যাত') ||
        q.contains('জনপ্রিয়')) {
      if (lang == QueryLanguage.bengali) {
        return ChatReply.fallback(
          'কলকাতা পূজা ২০২৬-এর সেরা ও বিখ্যাত মণ্ডপসমূহ:\n\n'
          'উত্তর কলকাতা:\n'
          '• বাগবাজার সর্বজনীন — ঐতিহ্যবাহী ডাকের সাজ · শ্যামবাজার মেট্রো\n'
          '• কুমারটুলি পার্ক — অপূর্ব শিল্পকীর্তি · শোভাবাজার মেট্রো\n'
          '• কলেজ স্কয়ার — ঐতিহ্যবাহী আলোকসজ্জা ও সরোবর · সেন্ট্রাল মেট্রো\n\n'
          'দক্ষিণ কলকাতা:\n'
          '• সুরুচি সংঘ — অনন্য সামাজিক থিম · কালীঘাট মেট্রো\n'
          '• ম্যাডক্স স্কোয়ার — খোলামেলা আড্ডা ও প্রতিমা · নেতাজি ভবন মেট্রো\n'
          '• একডালিয়া এভারগ্রিন — ঐতিহ্যবাহী প্রতিমা ও শিল্প · গড়িয়াহাট\n\n'
          'সল্টলেক ও ভিআইপি:\n'
          '• শ্রীভূমি স্পোর্টিং — দর্শনীয় স্থাপত্য রূপায়ণ · উল্টোডাঙা/বিধাননগর',
          factsAsOf: DateTime.now(),
          suggestions: [
            'বাগবাজার যাওয়ার রুট',
            'সুরুচি সংঘের বিস্তারিত',
            'কোথায় ভিড় কম?',
          ],
          actions: ['show_on_map', 'share_with_group'],
        );
      } else if (lang == QueryLanguage.benglish) {
        return ChatReply.fallback(
          'Kolkata Pujo 2026 er best o famous pandal gulo:\n\n'
          'North Kolkata:\n'
          '• Bagbazar Sarbojanin — Traditional Daker Saaj · Shyambazar Metro\n'
          '• Kumartuli Park — Artistic theme · Sovabazar Metro\n'
          '• College Square — Jolojonito aloksojja · Central Metro\n\n'
          'South Kolkata:\n'
          '• Suruchi Sangha — Unique social theme · Kalighat Metro\n'
          '• Maddox Square — Grand adda o shundor protima · Netaji Bhavan Metro\n'
          '• Ekdalia Evergreen — Traditional mandir shojja · Gariahat\n\n'
          'Salt Lake & VIP:\n'
          '• Sreebhumi Sporting — Grand replica darshan · Ultadanga/Bidhannagar',
          factsAsOf: DateTime.now(),
          suggestions: [
            'Bagbazar jabar route',
            'Suruchi Sangha details',
            'Kothay bhir kom?',
          ],
          actions: ['show_on_map', 'share_with_group'],
        );
      } else {
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
    }

    // 7. Zone-specific query
    if (q.contains('north') ||
        q.contains('south') ||
        q.contains('salt lake') ||
        q.contains('behala') ||
        q.contains('central') ||
        q.contains('howrah') ||
        q.contains('উত্তর') ||
        q.contains('দক্ষিণ') ||
        q.contains('সল্টলেক') ||
        q.contains('বেহালা') ||
        q.contains('হাওড়া') ||
        q.contains('uttar') ||
        q.contains('dakkhin')) {
      final zoneName = (q.contains('north') || q.contains('উত্তর') || q.contains('uttar'))
          ? 'North Kolkata'
          : (q.contains('south') || q.contains('দক্ষিণ') || q.contains('dakkhin'))
              ? 'South Kolkata'
              : (q.contains('salt lake') || q.contains('সল্টলেক'))
                  ? 'Salt Lake'
                  : (q.contains('behala') || q.contains('বেহালা'))
                      ? 'Behala'
                      : (q.contains('central'))
                          ? 'Central Kolkata'
                          : 'Howrah';

      final zoneNameBn = zoneName == 'North Kolkata'
          ? 'উত্তর কলকাতা'
          : zoneName == 'South Kolkata'
              ? 'দক্ষিণ কলকাতা'
              : zoneName == 'Central Kolkata'
                  ? 'মধ্য কলকাতা'
                  : zoneName;

      final text = lang == QueryLanguage.bengali
          ? '$zoneNameBn-এর আকর্ষণ:\n'
            'বিখ্যাত মণ্ডপ, অপূর্ব আলোকসজ্জা এবং উৎসবের আড্ডা। '
            'ম্যাপ ট্যাবে গিয়ে আপনি এই জোনের মণ্ডপ এবং হাঁটার রুট সহজে দেখতে পারেন।'
          : lang == QueryLanguage.benglish
              ? '$zoneName-er highlights:\n'
                'Famous pandals, durdanto aloksojja ar addar jayga. '
                'Map tab-e giye ei zone filter kore shohojei hete ghurar route dekhte paren.'
              : '$zoneName Highlights:\n'
                'Famous pandals, vibrant lighting, and cultural adda spots. '
                'You can filter by this zone on the Map tab to view clustered walking routes.';

      return ChatReply.fallback(
        text,
        factsAsOf: DateTime.now(),
        actions: ['show_on_map'],
        suggestions: _buildSuggestionsForLang(lang),
      );
    }

    // 8. Crowd & Timing / Road Blockages query
    if (q.contains('crowd') ||
        q.contains('bhir') ||
        q.contains('busy') ||
        q.contains('line') ||
        q.contains('time') ||
        q.contains('shanto') ||
        q.contains('rasta') ||
        q.contains('bondho') ||
        q.contains('ভিড়') ||
        q.contains('ভিড়') ||
        q.contains('লাইন') ||
        q.contains('সময়') ||
        q.contains('রাস্তা') ||
        q.contains('বন্ধ') ||
        q.contains('কখন')) {
      if (lang == QueryLanguage.bengali) {
        return ChatReply.fallback(
          'কলকাতা পূজা ভিড় সংক্রান্ত তথ্য ও সেরা সময়:\n\n'
          '• সবচেয়ে কম ভিড়: দুপুর ১:০০ – বিকেল ৪:৩০ (দিনের আলোয় শান্তিতে দর্শন)\n'
          '• গভীর রাতের হপিং: রাত ১:৩০ – ভোর ৪:০০ (মনোরম আবহাওয়া, ছোট লাইন)\n'
          '• চরম ভিড়ের সময়: সন্ধ্যা ৭:০০ – রাত ১১:৩০ (রাস্তায় গাড়ি চলাচল সীমিত)\n\n'
          'পরামর্শ: পুজোতে যানজট ও রোড ডাইভারশন এড়াতে রাত ১২টা পর্যন্ত মেট্রো ব্যবহার করা সবচেয়ে সুবিধাজনক।',
          factsAsOf: DateTime.now(),
          suggestions: const ['মেট্রোর সময়সূচী', 'সেরা মণ্ডপসমূহ', 'জরুরি হেল্পলাইন'],
        );
      } else if (lang == QueryLanguage.benglish) {
        return ChatReply.fallback(
          'Kolkata Pujo Bhir er Advisory o Best Timing:\n\n'
          '• Shobcheye kom bhir: Dupur 1:00 theke Bikel 4:30 (aram se darshan)\n'
          '• Late night hopping: Raat 1:30 theke Bhor 4:00 (thanda thanda weather, choto line)\n'
          '• Peak rush somoy: Shondhye 7:00 theke Raat 11:30 (traffic diversion thake)\n\n'
          'Tip: Rastar jam eriye shonshoi hopti korte raat obdhi Metro use kora shobcheye bhalo.',
          factsAsOf: DateTime.now(),
          suggestions: const ['Metro timings', 'Top pandals 2026', 'Emergency helpline'],
        );
      } else {
        return ChatReply.fallback(
          'Kolkata Crowd Advisory & Best Times:\n\n'
          '• Least crowded hours: 1:00 PM – 4:30 PM (afternoon daylight)\n'
          '• Late night hopping: 1:30 AM – 4:00 AM (cooler weather, easier queues)\n'
          '• Peak rush: 7:00 PM – 11:30 PM (major vehicular restrictions active)\n\n'
          'Tip: Use the Metro till midnight on Puja days to avoid surface road diversions.',
          factsAsOf: DateTime.now(),
          suggestions: const ['Metro timings', 'Top pandals', 'Emergency helplines'],
        );
      }
    }

    // 9. General fallback
    if (lang == QueryLanguage.bengali) {
      return ChatReply.fallback(
        'উমা রুট অ্যাসিস্ট্যান্ট (অফলাইন মোড):\n'
        'আমি মণ্ডপের পথনির্দেশ, নিকটবর্তী মেট্রো এবং জরুরি হেল্পলাইন সম্পর্কে সাহায্য করতে পারি। '
        'জিজ্ঞাসা করুন: "বাগবাজারের নিকটবর্তী মেট্রো" অথবা "হাওড়া থেকে কুমারটুলি রুট"।',
        factsAsOf: DateTime.now(),
        suggestions: _buildSuggestionsForLang(lang),
      );
    } else if (lang == QueryLanguage.benglish) {
      return ChatReply.fallback(
        'UMA Route Assistant (Offline mode):\n'
        'Ami pandaler rasta, kacher metro station o emergency helpline niye sahajjo korte pari. '
        'Jiggasha korun: "Bagbazar er kacher metro" ba "Kothay bhir kom?".',
        factsAsOf: DateTime.now(),
        suggestions: _buildSuggestionsForLang(lang),
      );
    } else {
      return ChatReply.fallback(
        'UMA Route Assistant (Offline mode):\n'
        'I can guide you on routes between pandals, nearest metro stations, and emergency helplines. '
        'Try asking: "Nearest metro to Baghbazar" or "Route from Howrah to Kumartuli".',
        factsAsOf: DateTime.now(),
        suggestions: _buildSuggestionsForLang(lang),
      );
    }
  }
}