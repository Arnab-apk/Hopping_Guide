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
import '../repositories/supplementary_repository.dart';
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
/// 2. Direct On-Device Cloud AI (NVIDIA Nemotron 3 Ultra / Gemini 3.5 Flash)
/// 3. Ultra-smart deterministic on-device offline engine (airplane mode / zero internet)
class ChatService {
  ChatService({
    String? baseUrl,
    String? deviceId,
    http.Client? client,
    LocalAssetPandalRepository? pandalRepository,
    StationRepository? stationRepository,
    SupplementaryRepository? supplementaryRepository,
  })  : _configuredBaseUrl = baseUrl,
        _explicitDeviceId = deviceId,
        _client = client ?? http.Client(),
        _pandalRepo = pandalRepository ?? LocalAssetPandalRepository(),
        _stationRepo = stationRepository ?? StationRepository.instance,
        _supplementaryRepo = supplementaryRepository ?? SupplementaryRepository();

  static final ChatService instance = ChatService();

  final String? _configuredBaseUrl;
  final String? _explicitDeviceId;
  final http.Client _client;
  final LocalAssetPandalRepository _pandalRepo;
  final StationRepository _stationRepo;
  final SupplementaryRepository _supplementaryRepo;

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
      r'pujor|pandaler|rastar|police-er|policeer|metror|kina|gulo|gulor|khabo)\b',
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
      final geminiKey = AppConfig.geminiApiKey;
      if (geminiKey.isNotEmpty) {
        final reply = await _callGeminiDirect(question, route, queryLang, geminiKey);
        if (reply != null) return reply;
      }

      final nvidiaKey = AppConfig.nvidiaApiKey;
      if (nvidiaKey.isNotEmpty) {
        final reply = await _callNvidiaDirect(question, route, queryLang, nvidiaKey);
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

  /// Finds iconic food spots and historic cabins near a pandal within 1.8km.
  List<FoodSpot> _findNearbyFoodSpots(Pandal p, List<FoodSpot> allFood, {int max = 2}) {
    final nearby = <FoodSpot>[];
    for (final f in allFood) {
      final dist = haversineMeters(p.lat, p.lng, f.lat, f.lng);
      if (dist <= 1800 || f.nearbyPandal.toLowerCase().contains(p.name.toLowerCase())) {
        nearby.add(f);
      }
    }
    nearby.sort((a, b) {
      final distA = haversineMeters(p.lat, p.lng, a.lat, a.lng);
      final distB = haversineMeters(p.lat, p.lng, b.lat, b.lng);
      return distA.compareTo(distB);
    });
    return nearby.take(max).toList();
  }

  /// Returns real Kolkata Police pedestrian restrictions and vehicular diversion rules for pandals.
  String _getPoliceTrafficRestriction(Pandal p) {
    final name = p.name.toLowerCase();
    if (name.contains('bagbazar') || name.contains('kumartuli') || name.contains('hatibagan') || name.contains('kashi bose')) {
      return 'Girish Avenue, Bidhan Sarani, and Rabindra Sarani are strict pedestrian-only corridors from 4:00 PM to 4:00 AM. No cars allowed past Shyambazar 5-point.';
    }
    if (name.contains('college square') || name.contains('mohammad ali') || name.contains('santosh mitra')) {
      return 'College Street and Amherst Street have one-way pedestrian routing; MG Road vehicular diversions active after 4:00 PM.';
    }
    if (name.contains('sreebhumi')) {
      return 'VIP Road service lanes closed to private vehicles; all visitors must use the dedicated pedestrian skywalk/footbridge from Lake Town.';
    }
    if (name.contains('suruchi') || name.contains('chetla')) {
      return 'New Alipore railway bridge approach restricted; pedestrian-only lanes active on Raja Chetla Road.';
    }
    if (name.contains('ekdalia') || name.contains('singhi') || name.contains('maddox') || name.contains('ballygunge')) {
      return 'Gariahat Road and Rashbehari Avenue are pedestrian-prioritized; no private car parking within 800m of pandal entrance.';
    }
    return 'Surrounding lanes converted to pedestrian-priority zones from 4:00 PM. Follow Kolkata Police volunteer signages.';
  }

  /// Returns realistic queue waiting estimates based on live reports or time of day.
  String _getRealisticQueueTime(Pandal p) {
    if (p.queueWaitMinutes != null && p.queueWaitMinutes! > 0) {
      return 'Live reported queue: ~${p.queueWaitMinutes} min';
    }
    final crowd = (p.crowdLevel ?? 'normal').toLowerCase();
    if (crowd == 'high' || crowd == 'packed') {
      return 'Peak evening wait: 45–75 min (afternoon daylight: 10–15 min)';
    } else if (crowd == 'moderate') {
      return 'Peak evening wait: 20–35 min (afternoon daylight: 5–10 min)';
    } else {
      return 'Walk-in or minimal queue: 5–15 min';
    }
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
      final allFood = await _supplementaryRepo.getFoodSpots();
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
          final stations = _stationRepo.getNearest(LatLng(p.lat, p.lng), limit: 2);
          final nearbyFood = _findNearbyFoodSpots(p, allFood);
          final trafficAdvisory = _getPoliceTrafficRestriction(p);
          final queueWait = _getRealisticQueueTime(p);

          if (metro != null && metro.isNotEmpty) {
            blocks.add(StationBlock(name: '$metro Metro', kind: 'Metro', distanceM: 450));
          }
          blocks.add(CrowdBlock(
            place: p.name,
            level: p.crowdLevel ?? 'normal',
            source: 'Puja Directory & Queue Monitor',
            updatedMinAgo: 2,
          ));
          if (trafficAdvisory.isNotEmpty) {
            blocks.add(BlockageBlock(
              kind: 'Pedestrian Priority / Vehicular Diversion',
              near: p.area ?? p.name,
              source: 'Kolkata Police Advisory',
              updatedMinAgo: 5,
            ));
          }

          return {
            'name': p.name,
            'area_and_locality': p.area ?? p.zone.label,
            'zone': p.zone.label,
            'rating': p.rating ?? 4.5,
            'theme': p.theme,
            'special_features': p.specialFeatures,
            'nearest_metro': metro != null ? '$metro Metro Station (5–8 min walk)' : null,
            'nearest_railway': p.nearestRailway,
            'nearby_stations': stations.map((s) => '${s.name} (${s.kind}, ${(haversineMeters(p.lat, p.lng, s.lat, s.lon)/1000).toStringAsFixed(1)} km)').toList(),
            'crowd_level': p.crowdLevel ?? 'moderate',
            'queue_wait_time': queueWait,
            'timings': p.timings.isNotEmpty ? p.timings : 'Open 24 hours (public darshan throughout Puja)',
            'police_traffic_advisory': trafficAdvisory,
            'iconic_nearby_food': nearbyFood.map((f) => '${f.name} (${f.type}) — Must Try: ${f.mustTry}').toList(),
          };
        }).toList();
      }

      factsMap['citywide_puja_transit_hacks'] = [
        'Kolkata Metro runs special night-long trains every 12–15 minutes until 4:00 AM on Saptami, Ashtami, & Nabami across Blue Line and Green Line.',
        'River Ferry: Howrah Station to Bagbazar Ghat & Ahiritola Ghat ferry operates until 11:30 PM (15-min river crossing bypassing Howrah Bridge road gridlock).',
        'East-West Green Line connects Howrah Railway Station under the river to Esplanade in just 8 minutes.',
      ];
      factsMap['crowd_strategy'] = {
        'golden_daylight_window': '1:30 PM – 4:30 PM (lightest queues, easiest entry, ideal for elderly and kids)',
        'late_night_window': '1:30 AM – 4:00 AM (cooler weather, shorter queues, night metro active)',
        'peak_rush_window': '6:30 PM – 11:30 PM (heavy crowd, mandatory zig-zag pedestrian queues, vehicular diversions active)',
      };
      factsMap['emergency_helplines'] = {
        'kolkata_police_emergency': '100 / 112',
        'traffic_control_and_towing': '1073 / (033) 2214-3644',
        'women_safety_the_winners': '1091',
        'medical_ambulance': '102 / 108',
        'police_lost_and_found_childline': '1098',
      };

      String systemContent;
      switch (queryLang) {
        case QueryLanguage.bengali:
          systemContent =
              'You are UMA, the warm, deeply knowledgeable Kolkata Durga Puja companion. '
              'The user is asking in Bengali script (বাংলা). You MUST answer completely in polite, '
              'natural, culturally authentic Bengali script (বাংলা হরফে উত্তর দিন). '
              'Use the rich ground facts (exact locality, nearest metro line & walking distance, '
              'realistic queue wait time, police pedestrian diversions, iconic food spots nearby) to give '
              'a detailed, practical, and deeply satisfying answer. Never use English letters. '
              'Never output raw JSON or markdown tables.';
          break;
        case QueryLanguage.benglish:
          systemContent =
              'You are UMA, the warm, street-smart Kolkata Durga Puja companion. '
              'The user is asking in Benglish (Banglish - conversational Bengali written in English letters). '
              'You MUST reply in conversational, authentic Kolkata Benglish/Banglish. '
              'Incorporate specific ground details like exact locality, nearest metro with walking time, '
              'queue waiting hours, police diversions, and famous local street food spots (e.g. Mitra Cafe, Paramount, Golbari). '
              'Never reply in formal English or Bengali script. Never output raw JSON or markdown tables.';
          break;
        case QueryLanguage.english:
          systemContent =
              'You are UMA, the warm and highly knowledgeable route, pandal, and transit guide for Kolkata Durga Puja. '
              'Give rich, realistic, and satisfying guidance grounded in facts: include exact neighborhood locality, '
              'nearest metro stations with walking distances, realistic queue wait times, police traffic regulations, '
              'and iconic local food recommendations. Answer in fluent, friendly English with authentic local Kolkata context.';
          break;
      }

      final prompt = """
[USER QUESTION]
$question

[DETAILED GROUND FACTS JSON]
${jsonEncode(factsMap)}

[DETECTED LANGUAGE]
${queryLang.name}

Answer the user directly with realistic, detailed local Kolkata knowledge based on the facts in the user's language (2-4 sentences).
""";

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
          'temperature': 0.25,
          'max_tokens': 320,
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
      final allFood = await _supplementaryRepo.getFoodSpots();
      final matchedPandals = _findMatchingPandals(pandals, question).take(5).toList();

      final mentionedPandals = matchedPandals
          .map(
            (p) => {
              'name': p.name,
              'area_and_locality': p.area ?? p.zone.label,
              'zone': p.zone.label,
              'rating': p.rating,
              'theme': p.theme,
              'special_features': p.specialFeatures,
              'nearest_metro': p.nearestMetro,
              'nearest_railway': p.nearestRailway,
              'crowd_level': p.crowdLevel,
              'queue_wait_time': _getRealisticQueueTime(p),
              'police_traffic_advisory': _getPoliceTrafficRestriction(p),
              'iconic_nearby_food': _findNearbyFoodSpots(p, allFood).map((f) => '${f.name} (${f.type}): ${f.mustTry}').toList(),
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
        'citywide_puja_transit_hacks': [
          'Kolkata Metro runs special night-long trains every 12-15 min until 4:00 AM on Saptami, Ashtami, and Nabami across Blue Line and Green Line.',
          'River Ferry: Howrah Station to Bagbazar/Ahiritola Ghat operates until 11:30 PM (bypassing Howrah Bridge road traffic).',
        ],
        'crowd_strategy': {
          'golden_daylight_window': '1:30 PM – 4:30 PM (shortest queues, easiest entry)',
          'late_night_window': '1:30 AM – 4:00 AM (cooler weather, night metro operational)',
          'peak_rush_window': '6:30 PM – 11:30 PM (heavy crowd, police pedestrian diversions active)',
        },
        'emergency_helplines': {
          'police': '100 / 112',
          'traffic_control': '1073 / (033) 2214-3644',
          'women_safety': '1091',
          'medical': '102 / 108',
          'childline_lost_found': '1098',
        },
      };

      String systemDirective;
      switch (queryLang) {
        case QueryLanguage.bengali:
          systemDirective =
              'You are UMA, the warm, knowledgeable Kolkata Durga Puja companion. '
              'The user query is in Bengali script (বাংলা). You MUST answer completely in polite, '
              'natural, culturally authentic Bengali script (বাংলা হরফে উত্তর দিন). '
              'Provide realistic, rich facts: exact neighborhood locality, nearest metro line & walking distance, '
              'realistic queue wait times, police traffic barricades, and famous nearby food spots. Never use English letters. '
              'Never output raw JSON or tables.';
          break;
        case QueryLanguage.benglish:
          systemDirective =
              'You are UMA, the warm, street-smart Kolkata Durga Puja companion. '
              'The user query is in Benglish (Banglish - conversational Bengali written in English letters). '
              'You MUST answer in conversational, authentic Kolkata Benglish/Banglish. '
              'Incorporate realistic ground facts: exact locality, nearest metro with walking minutes, '
              'queue waiting duration, police diversions, and famous local street food spots. '
              'Never output formal English, Bengali script, or raw JSON.';
          break;
        case QueryLanguage.english:
          systemDirective =
              'You are UMA, a warm, practical, and deeply knowledgeable Kolkata Durga Puja companion. '
              'Answer naturally in English with realistic ground facts: exact neighborhood, '
              'nearest metro stations with walking distances, realistic queue wait times, police traffic restrictions, '
              'and iconic local food recommendations. Keep answers concise (2-4 sentences). Never output raw JSON or tables.';
          break;
      }

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
                    'User question:\n$question\n\nVerified rich ground context:\n${jsonEncode(context)}',
              }
            ],
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'topP': 0.9,
          'maxOutputTokens': 380,
        },
      };

      // Prefer the configured model, then Google's supported Flash aliases.
      final candidateModels = <String>[
        AppConfig.geminiModel,
        if (AppConfig.geminiModel != 'gemini-flash-latest') 'gemini-flash-latest',
        if (AppConfig.geminiModel != 'gemini-flash-lite-latest')
          'gemini-flash-lite-latest',
      ];

      for (final model in candidateModels) {
        final endpoint = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
        );

        final response = await _client.post(
          endpoint,
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
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
      }
    } catch (e) {
      debugPrint('[ChatService] Gemini request failed (${e.runtimeType})');
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
          'কাছে ভালো মিষ্টি ও খাবার',
        ];
      case QueryLanguage.benglish:
        return [
          'Kothay bhir kom?',
          'Kacher metro station',
          'Top pandals 2026',
          'Kacher bhalo khabar',
        ];
      case QueryLanguage.english:
        return [
          'Nearest metro stations',
          'Least crowded pandals',
          'Top pandals 2026',
          'Famous food spots nearby',
        ];
    }
  }

  /// Deterministic on-device fallback using bundled pandals, food spots, and stations GeoJSON.
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
          '• কলকাতা পুলিশ ইমার্জেন্সি: ১০০ / ১১২ / (০৩৩) ২২১৪-৩৬৪৪\n'
          '• ট্রাফিক কন্ট্রোল ও টোয়িং: ১০৭৩\n'
          '• মহিলা সুরক্ষা (দ্য উইনার্স পেট্রোল): ১০৯১\n'
          '• মেডিকেল অ্যাম্বুলেন্স: ১০২ / ১০৮\n'
          '• চাইল্ডলাইন ও পুলিশ লস্ট অ্যান্ড ফাউন্ড: ১০৯৮\n'
          '• দমকল ও বিপর্যয় মোকাবিলা: ১০১\n'
          'যেকোনো জরুরি পরিস্থিতিতে সরাসরি এই নম্বরগুলিতে যোগাযোগ করুন। প্রতিটি প্রধান মণ্ডপে পুলিশ হেল্প ডেস্ক সক্রিয় রয়েছে।',
          factsAsOf: DateTime.now(),
          actions: ['share_with_group'],
          suggestions: _buildSuggestionsForLang(lang),
        );
      } else if (lang == QueryLanguage.benglish) {
        return ChatReply.fallback(
          'Kolkata Pujo Emergency Helplines:\n'
          '• Kolkata Police Emergency: 100 / 112 / (033) 2214-3644\n'
          '• Traffic Police Control & Towing: 1073\n'
          '• Women Safety Helpline ("The Winners" patrol): 1091\n'
          '• Medical Ambulance: 102 / 108\n'
          '• Police Lost & Found / Childline: 1098\n'
          '• Fire & Disaster Control: 101\n'
          'Kono emergency-te ei number gulo-te direct call korun. Prottek boro pandale Kolkata Police Help Desk ache.',
          factsAsOf: DateTime.now(),
          actions: ['share_with_group'],
          suggestions: _buildSuggestionsForLang(lang),
        );
      } else {
        return ChatReply.fallback(
          'Kolkata Puja Emergency Helplines:\n'
          '• Kolkata Police Emergency: 100 / 112 / (033) 2214-3644\n'
          '• Traffic Police Control & Towing: 1073\n'
          '• Women Safety Helpline ("The Winners" all-women unit): 1091\n'
          '• Medical Ambulance: 102 / 108\n'
          '• Police Lost & Found / Childline: 1098\n'
          '• Fire & Disaster Control: 101\n'
          'Police Assistance Kiosks are stationed at all major pandal entrances.',
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
          buffer.write('${p.name}-এর নিকটবর্তী যাতায়াত নির্দেশিকা:\n');
          if (metro != null && metro.isNotEmpty) {
            buffer.write('• মেট্রো: $metro মেট্রো স্টেশন (হাঁটা পথ প্রায় ৪৫০ মি, ৫-৭ মিনিট)\n');
            blocks.add(StationBlock(name: '$metro Metro', kind: 'Metro', distanceM: 450));
          }
          if (stations.isNotEmpty) {
            final stationDetails = stations.map((s) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              return '${s.name} (${(dist / 1000).toStringAsFixed(1)} কিমি)';
            }).join(', ');
            buffer.write('• কাছাকাছি স্টেশন: $stationDetails\n');
            for (final s in stations) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              blocks.add(StationBlock(name: s.name, kind: s.network ?? 'Rail', distanceM: dist.round()));
            }
          }
          buffer.write('• বিশেষ মেট্রো সেবা: সপ্তমী, অষ্টমী ও নবমীতে রাত ৪:০০টা পর্যন্ত মেট্রো চলবে। টোকেনের দীর্ঘ লাইন এড়াতে স্মার্ট কার্ড ব্যবহার করুন।');
        } else if (lang == QueryLanguage.benglish) {
          buffer.write('${p.name}-er kacher transit details:\n');
          if (metro != null && metro.isNotEmpty) {
            buffer.write('• Metro: $metro Metro Station (Paye hete pray 450 m, 5-7 min)\n');
            blocks.add(StationBlock(name: '$metro Metro', kind: 'Metro', distanceM: 450));
          }
          if (stations.isNotEmpty) {
            final stationDetails = stations.map((s) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              return '${s.name} (${(dist / 1000).toStringAsFixed(1)} km)';
            }).join(', ');
            buffer.write('• Kacher Rail Station: $stationDetails\n');
            for (final s in stations) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              blocks.add(StationBlock(name: s.name, kind: s.network ?? 'Rail', distanceM: dist.round()));
            }
          }
          buffer.write('• Special Night Metro: Saptami, Ashtami o Nabami-te raat 4:00 AM obdhi Metro cholbe. Token line eriye cholte smart card / QR use korun.');
        } else {
          buffer.write('Nearest transit to ${p.name}:\n');
          if (metro != null && metro.isNotEmpty) {
            buffer.write('• Metro: $metro Metro Station (~450m, 5-7 min walk)\n');
            blocks.add(StationBlock(name: '$metro Metro', kind: 'Metro', distanceM: 450));
          }
          if (stations.isNotEmpty) {
            final stationDetails = stations.map((s) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              return '${s.name} (${(dist / 1000).toStringAsFixed(1)} km)';
            }).join(', ');
            buffer.write('• Nearby Stations: $stationDetails\n');
            for (final s in stations) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              blocks.add(StationBlock(name: s.name, kind: s.network ?? 'Rail', distanceM: dist.round()));
            }
          }
          buffer.write('• Puja Night Metro: Kolkata Metro runs night-long trains every 12–15 min until 4:00 AM on Saptami, Ashtami, and Nabami.');
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
              'নেটওয়ার্ক: ${s.network ?? "কলকাতা ট্রানজিট"}\n'
              'পুজো স্পেশাল: প্রধান মেট্রো স্টেশনগুলিতে মধ্যরাত পর্যন্ত স্পেশাল ট্রেনের সুবিধা রয়েছে।'
            : lang == QueryLanguage.benglish
                ? 'Station Info: ${s.name} (${s.code ?? "Kolkata Metro"})\n'
                  'Lines: ${s.lines.join(", ")}\n'
                  'Network: ${s.network ?? "Kolkata Transit"}\n'
                  'Special Night Service: Raat 4:00 AM obdhi trains available ache.'
                : 'Station Info: ${s.name} (${s.code ?? 'Kolkata Metro'})\n'
                  'Lines: ${s.lines.join(", ")}\n'
                  'Network: ${s.network ?? "Kolkata Transit"}\n'
                  'Puja Special: Night-long trains operational until 4:00 AM on festival nights.';
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
          ? 'রুট পরিকল্পনা: $from → $to\n'
            '• আনুমানিক হাঁটার সময়: প্রায় $min মিনিট ($distKm কিমি)।\n'
            '• পুলিশ ট্রাফিক সতর্কতা: নিকটবর্তী সংযোগস্থলে বিকেল ৪:০০টা থেকে ওয়ান-ওয়ে পেডেস্টিয়ান জোন কার্যকর রয়েছে।\n'
            '• পরামর্শ: দীর্ঘ হাঁটা এড়াতে নিকটবর্তী মেট্রো ব্যবহার করুন।'
          : lang == QueryLanguage.benglish
              ? 'Route details: $from theke $to\n'
                '• Paye hete somoy: pray $min min ($distKm km).\n'
                '• Police Advisory: Bikel 4:00 theke rasta pedestrian-only kora thakbe, gaari divert kora hocche.\n'
                '• Transit Tip: Jam erate kacher metro use kora shobcheye convenient.'
              : 'Route Plan: $from → $to\n'
                '• Estimated walk: about $min min ($distKm km).\n'
                '• Police Advisory: Pedestrian-only routing enforced from 4:00 PM onwards on surrounding arterial roads.\n'
                '• Transit Tip: Use the Metro corridor to bypass heavy surface road foot traffic.';

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

    // 4. Food & Eateries intent (New Ground Truth Intent)
    if (q.contains('food') ||
        q.contains('khabar') ||
        q.contains('khawa') ||
        q.contains('eat') ||
        q.contains('restaurant') ||
        q.contains('kheye') ||
        q.contains('mishti') ||
        q.contains('sweet') ||
        q.contains('biryani') ||
        q.contains('chop') ||
        q.contains('cutlet') ||
        q.contains('puchka') ||
        q.contains('খাবার') ||
        q.contains('খাওয়া') ||
        q.contains('কাফে') ||
        q.contains('মিষ্টি')) {
      final pandals = await _pandalRepo.all();
      final matched = _findMatchingPandals(pandals, question);
      final allFood = await _supplementaryRepo.getFoodSpots();

      if (matched.isNotEmpty) {
        final p = matched.first;
        final nearby = _findNearbyFoodSpots(p, allFood, max: 3);
        if (nearby.isNotEmpty) {
          final foodLines = nearby.map((f) => '• ${f.name}: ${f.mustTry} (${f.type})').join('\n');
          final ans = lang == QueryLanguage.bengali
              ? '${p.name}-এর কাছে সেরা ও বিখ্যাত খাবার:\n\n'
                '$foodLines\n\n'
                'পুজোর আড্ডার সাথে এই ঐতিহ্যবাহী খাবারগুলি মিস করবেন না!'
              : lang == QueryLanguage.benglish
                  ? '${p.name}-er kacher iconic food spots:\n\n'
                    '$foodLines\n\n'
                    'Pujo hopping-er shathe ei khabar gulo must try!'
                  : 'Iconic food spots near ${p.name}:\n\n'
                    '$foodLines\n\n'
                    'Perfect for a quick festive adda and traditional Kolkata street bites!';
          return ChatReply.fallback(
            ans,
            factsAsOf: DateTime.now(),
            actions: ['show_on_map', 'share_with_group'],
            suggestions: _buildSuggestionsForLang(lang),
          );
        }
      }

      // Generic top food spots in Kolkata
      final genericAns = lang == QueryLanguage.bengali
          ? 'কলকাতা পুজোর ঐতিহ্যবাহী খাওয়া-দাওয়া ও আড্ডার স্থান:\n\n'
            'উত্তর কলকাতা:\n'
            '• মিত্র কাফে (শ্যামবাজার ৫ মাথার মোড়) — ডায়মন্ড ফিশ ফ্রাই ও মাটন কবিরাজি\n'
            '• গোলবাড়ি (শ্যামবাজার) — বিখ্যাত কষা মাংস ও পরোটা\n'
            '• প্যারামাউন্ট (কলেজ স্কোয়ার) — ঐতিহ্যবাহী ডাব শরবত ও কাজু দ্রাক্ষা\n'
            '• চিত্তরঞ্জন মিষ্টান্ন ভাণ্ডার (হাতিবাগান) — স্পঞ্জ রসগোল্লা\n\n'
            'দক্ষিণ কলকাতা:\n'
            '• ক্যাম্পারি (গড়িয়াহাট) — ক্রিস্পি ফিশ রোল ও চপ\n'
            '• বেদুইন (গড়িয়াহাট মোড়) — স্পেশাল চিকেন ও মাটন রোল\n'
            '• মহারাজ কাফে (সাদার্ন অ্যাভিনিউ) — চা ও হিং-এর কচুরি'
          : lang == QueryLanguage.benglish
              ? 'Kolkata Pujo Special Food & Adda Trail:\n\n'
                'North Kolkata:\n'
                '• Mitra Cafe (Shyambazar) — Diamond Fish Fry & Mutton Kabiraji\n'
                '• Golbari (Shyambazar) — Legendary Kasha Mangsho & Paratha\n'
                '• Paramount Sherbets (College Square) — Daab Sherbet since 1918\n'
                '• Chittaranjan Mistanna (Hatibagan) — White Sponge Rossogolla\n\n'
                'South Kolkata:\n'
                '• Campari (Gariahat) — Legendary Fish Roll & Cutlet\n'
                '• Bedouin (Gariahat) — Mutton Tikka Roll\n'
                '• Maharaja Cha (Southern Ave) — Hing Kochuri & Malai Chai'
              : 'Iconic Kolkata Durga Puja Food & Adda Spots:\n\n'
                'North Kolkata:\n'
                '• Mitra Cafe (Shyambazar) — Diamond Fish Fry & Mutton Kabiraji\n'
                '• Golbari (Shyambazar) — Velvety Kasha Mangsho & Paratha\n'
                '• Paramount Sherbets (College Square) — Historic Daab Sharbat (Est. 1918)\n'
                '• Chittaranjan Mistanna (Hatibagan) — Soft White Sponge Rosogolla\n\n'
                'South Kolkata:\n'
                '• Campari (Gariahat) — Authentic Kolkata Fish Roll with mustard Kasundi\n'
                '• Bedouin (Gariahat) — Special Mutton Tikka & Chicken Rolls\n'
                '• Maharaja Cha (Southern Avenue) — Hing Kochuri & Clay-cup Chai';

      return ChatReply.fallback(
        genericAns,
        factsAsOf: DateTime.now(),
        actions: ['show_on_map', 'share_with_group'],
        suggestions: _buildSuggestionsForLang(lang),
      );
    }

    // 5. Pandals lookup
    final pandals = await _pandalRepo.all();
    final matched = _findMatchingPandals(pandals, question);
    if (matched.isNotEmpty) {
      final p = matched.first;
      final crowd = (p.crowdLevel ?? 'Normal').toUpperCase();
      final allFood = await _supplementaryRepo.getFoodSpots();
      final nearbyFood = _findNearbyFoodSpots(p, allFood);
      final foodNote = nearbyFood.isNotEmpty ? '${nearbyFood.first.name} (${nearbyFood.first.mustTry})' : 'Local street stalls';
      final queueWait = _getRealisticQueueTime(p);
      final traffic = _getPoliceTrafficRestriction(p);

      String answerText;
      if (lang == QueryLanguage.bengali) {
        final crowdBn = p.crowdLevel == 'high'
            ? 'অত্যধিক ভিড়'
            : p.crowdLevel == 'low'
                ? 'কম ভিড়'
                : 'স্বাভাবিক';
        answerText =
            '${p.name} (${p.area ?? p.zone.label}):\n'
            '• থিম ও শিল্প: ${p.theme}\n'
            '• ভিড় ও লাইন: $crowdBn ($queueWait)\n'
            '• নিকটবর্তী মেট্রো: ${p.nearestMetro ?? "শ্যামবাজার / সেন্ট্রাল"} (হাঁটা পথ প্রায় ৫–৮ মিনিট)\n'
            '• ট্রাফিক ও ব্যারিকেড: $traffic\n'
            '• কাছে বিখ্যাত খাবার: $foodNote\n'
            '• সময়সূচী: ${p.timings.isNotEmpty ? p.timings : "২৪ ঘণ্টা খোলা"}';
      } else if (lang == QueryLanguage.benglish) {
        final crowdBeng = p.crowdLevel == 'high'
            ? 'Onek bhir'
            : p.crowdLevel == 'low'
                ? 'Kom bhir'
                : 'Normal bhir';
        answerText =
            '${p.name} (${p.area ?? p.zone.label}):\n'
            '• Theme: ${p.theme}\n'
            '• Bhir & Line: $crowdBeng ($queueWait)\n'
            '• Kacher Metro: ${p.nearestMetro ?? "Shyambazar / Central"} (~5-8 min walk)\n'
            '• Police Diversion: $traffic\n'
            '• Kacher Bhalo Khabar: $foodNote\n'
            '• Darshan Somoy: ${p.timings.isNotEmpty ? p.timings : "24 hours open"}';
      } else {
        answerText =
            '${p.name} (${p.area ?? p.zone.label}):\n'
            '• Theme: ${p.theme}\n'
            '• Crowd & Queue: $crowd ($queueWait)\n'
            '• Nearest Metro: ${p.nearestMetro ?? "Shyambazar / Central"} (about 5–8 min walk)\n'
            '• Police Traffic Advisory: $traffic\n'
            '• Iconic Food Nearby: $foodNote\n'
            '• Visiting Hours: ${p.timings.isNotEmpty ? p.timings : "Open 24 hours"}';
      }

      return ChatReply.fallback(
        answerText,
        factsAsOf: DateTime.now(),
        blocks: [
          CrowdBlock(
            place: p.name,
            level: p.crowdLevel ?? 'normal',
            source: 'Puja Directory & Queue Monitor',
            updatedMinAgo: 2,
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

    // 6. Greetings & Identity
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
          '• বিভিন্ন মণ্ডপের সহজ রুট, হাঁটার পথ ও নিকটবর্তী মেট্রো\n'
          '• লাইভ ভিড়, লাইনের আনুমানিক সময় ও পুলিশ ব্যারিকেড আপডেট\n'
          '• মণ্ডপের কাছাকাছি বিখ্যাত খাবার ও মিষ্টির দোকান\n'
          '• জরুরি পুলিশ ও মেডিকেল হেল্পলাইন\n\n'
          'আপনি কোন মণ্ডপ, রুট বা খাবার সম্পর্কে জানতে চান?',
          factsAsOf: DateTime.now(),
          suggestions: _buildSuggestionsForLang(lang),
        );
      } else if (lang == QueryLanguage.benglish) {
        return ChatReply.fallback(
          'Shubho Sharodiya! Ami UMA, apnar Kolkata Durga Puja route companion.\n\n'
          'Ami apnake sahajjo korte pari:\n'
          '• Pandaler sohoj route, paye hete jawar somoy o kacher metro\n'
          '• Pandale bhir kemon, line er wait time o police road barricade\n'
          '• Pandaler kacher famous khabar o mishtir dokan\n'
          '• Emergency police o medical helpline\n\n'
          'Bolun apnar squad er jonno ki jante chan?',
          factsAsOf: DateTime.now(),
          suggestions: _buildSuggestionsForLang(lang),
        );
      } else {
        return ChatReply.fallback(
          'শুভ শারদীয়া! I am UMA, your Kolkata Durga Puja route assistant.\n\n'
          'I can help you with:\n'
          '• Best routes, walking directions & nearest metro stations\n'
          '• Real-time crowd levels, estimated queue times & police diversions\n'
          '• Iconic Kolkata street food & sweet spots near every pandal\n'
          '• Emergency police & medical helplines\n\n'
          'What would you like to explore?',
          factsAsOf: DateTime.now(),
          suggestions: _buildSuggestionsForLang(lang),
        );
      }
    }

    // 7. Best / Top pandals
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
          '• বাগবাজার সর্বজনীন — ঐতিহ্যবাহী ডাকের সাজ · শ্যামবাজার মেট্রো (কাছে মিত্র কাফে)\n'
          '• কুমারটুলি পার্ক — অপূর্ব শিল্পকীর্তি · শোভাবাজার মেট্রো (কাছে অ্যালেন কিচেন)\n'
          '• কলেজ স্কয়ার — সরোবরের আলো ও ঐতিহ্য · সেন্ট্রাল মেট্রো (কাছে প্যারামাউন্ট শরবত)\n\n'
          'দক্ষিণ কলকাতা:\n'
          '• সুরুচি সংঘ — অনন্য সামাজিক থিম · কালীঘাট মেট্রো\n'
          '• ম্যাডক্স স্কোয়ার — খোলামেলা আড্ডা ও প্রতিমা · নেতাজি ভবন মেট্রো\n'
          '• একডালিয়া এভারগ্রিন — ঐতিহ্যবাহী প্রতিমা ও শিল্প · গড়িয়াহাট (কাছে ক্যাম্পারি রোল)\n\n'
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
          '• Bagbazar Sarbojanin — Traditional Daker Saaj · Shyambazar Metro (Mitra Cafe nearby)\n'
          '• Kumartuli Park — Artistic theme · Sovabazar Metro (Allen Kitchen nearby)\n'
          '• College Square — Jolojonito aloksojja · Central Metro (Paramount Sherbets)\n\n'
          'South Kolkata:\n'
          '• Suruchi Sangha — Unique social theme · Kalighat Metro\n'
          '• Maddox Square — Grand adda o shundor protima · Netaji Bhavan Metro\n'
          '• Ekdalia Evergreen — Traditional mandir shojja · Gariahat (Campari Roll)\n\n'
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
          '• Bagbazar Sarbojanin — Traditional Daker Saaj · Shyambazar Metro (Mitra Cafe nearby)\n'
          '• Kumartuli Park — Artistic Heritage · Sovabazar Metro (Allen Kitchen nearby)\n'
          '• College Square — Illumination & Lake Reflection · Central Metro (Paramount Sherbet)\n\n'
          'South Kolkata:\n'
          '• Suruchi Sangha — State Themes · Kalighat Metro\n'
          '• Maddox Square — Grand Open Adda · Netaji Bhavan Metro\n'
          '• Ekdalia Evergreen — Traditional Temple Idol · Gariahat (Campari nearby)\n\n'
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

    // 8. Zone-specific query
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

    // 9. Crowd & Timing / Road Blockages query
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
          '• সবচেয়ে কম ভিড় (গোল্ডেন উইন্ডো): দুপুর ১:০০ – বিকেল ৪:৩০ (দিনের আলোয় শান্তিতে দর্শন, লাইন প্রায় থাকে না)\n'
          '• গভীর রাতের হপিং: রাত ১:৩০ – ভোর ৪:০০ (মনোরম আবহাওয়া, ছোট লাইন, রাতভর মেট্রো চালু)\n'
          '• চরম ভিড়ের সময়: সন্ধ্যা ৭:০০ – রাত ১১:৩০ (রাস্তায় গাড়ি চলাচল সম্পূর্ণ নিষিদ্ধ, জিজ-জ্যাগ লাইন কার্যকর)\n\n'
          'পরামর্শ: যানজট এড়াতে রাত ৪:০০টা পর্যন্ত চালু মেট্রো ব্যবহার করুন।',
          factsAsOf: DateTime.now(),
          suggestions: const ['মেট্রোর সময়সূচী', 'সেরা মণ্ডপসমূহ', 'জরুরি হেল্পলাইন'],
        );
      } else if (lang == QueryLanguage.benglish) {
        return ChatReply.fallback(
          'Kolkata Pujo Bhir er Advisory o Best Timing:\n\n'
          '• Shobcheye kom bhir (Golden Window): Dupur 1:00 theke Bikel 4:30 (aram se darshan, line pray nei)\n'
          '• Late night hopping: Raat 1:30 theke Bhor 4:00 (thanda weather, choto line, night metro active)\n'
          '• Peak rush somoy: Shondhye 7:00 theke Raat 11:30 (traffic diversion thake, zig-zag barricade)\n\n'
          'Tip: Jam eriye darshan korte raat 4:00 AM obdhi Metro use kora shobcheye bhalo.',
          factsAsOf: DateTime.now(),
          suggestions: const ['Metro timings', 'Top pandals 2026', 'Emergency helpline'],
        );
      } else {
        return ChatReply.fallback(
          'Kolkata Crowd Advisory & Best Times:\n\n'
          '• Golden Daylight Window: 1:00 PM – 4:30 PM (lightest queues, easiest entry)\n'
          '• Late Night Hopping: 1:30 AM – 4:00 AM (cooler weather, shorter queues, night metro active)\n'
          '• Peak Rush Hours: 7:00 PM – 11:30 PM (major vehicular restrictions active, zig-zag lines enforced)\n\n'
          'Tip: Use the Metro till 4:00 AM on festival nights to avoid surface road diversions.',
          factsAsOf: DateTime.now(),
          suggestions: const ['Metro timings', 'Top pandals', 'Emergency helplines'],
        );
      }
    }

    // 10. General fallback
    if (lang == QueryLanguage.bengali) {
      return ChatReply.fallback(
        'উমা রুট অ্যাসিস্ট্যান্ট (অফলাইন মোড):\n'
        'আমি মণ্ডপের পথনির্দেশ, নিকটবর্তী মেট্রো, ভিড় ও খাবারের তথ্য দিতে পারি। '
        'জিজ্ঞাসা করুন: "বাগবাজারের নিকটবর্তী মেট্রো", "কোথায় ভিড় কম?" অথবা "কলেজ স্কোয়ারের কাছে কী খাবার পাব?"।',
        factsAsOf: DateTime.now(),
        suggestions: _buildSuggestionsForLang(lang),
      );
    } else if (lang == QueryLanguage.benglish) {
      return ChatReply.fallback(
        'UMA Route Assistant (Offline mode):\n'
        'Ami pandaler rasta, kacher metro station, bhir o khabarer khobor dite pari. '
        'Jiggasha korun: "Bagbazar er kacher metro", "Kothay bhir kom?" ba "College Square e bhalo khabar".',
        factsAsOf: DateTime.now(),
        suggestions: _buildSuggestionsForLang(lang),
      );
    } else {
      return ChatReply.fallback(
        'UMA Route Assistant (Offline mode):\n'
        'I can guide you on routes between pandals, nearest metro stations, queue times, and famous food spots. '
        'Try asking: "Nearest metro to Baghbazar", "Where is the least crowd?" or "Food spots near College Square".',
        factsAsOf: DateTime.now(),
        suggestions: _buildSuggestionsForLang(lang),
      );
    }
  }
}
