import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/route_chat_models.dart';
import '../repositories/local_pandal_repository.dart';
import '../repositories/station_repository.dart';
import '../utils/constants.dart';
import '../utils/haversine.dart';

/// Client service for the UMA Route Assistant Chatbot.
/// Backed by the backend /chat endpoint with deterministic, zero-data-loss
/// on-device offline fallback using bundled pandals and station repositories.
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
        'http://127.0.0.1:8080',      // Physical device (USB adb reverse tunnel)
        'http://localhost:8080',      // Physical device (USB adb reverse tunnel)
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
        final response = await _client.get(uri).timeout(const Duration(seconds: 4));
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
    final candidates = _resolvedBaseUrl != null ? [_resolvedBaseUrl!] : candidateBaseUrls;

    for (final candidate in candidates) {
      try {
        final uri = Uri.parse('$candidate/chat');
        final payload = {
          'deviceId': devId,
          'message': trimmed,
          if (route != null) 'route': route.toJson(),
          'lang': lang,
        };

        final response = await _client
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 429) {
          _resolvedBaseUrl = candidate;
          return ChatReply.rateLimited();
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _resolvedBaseUrl = candidate;
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return ChatReply.fromJson(data);
        }

        debugPrint('[ChatService] Endpoint $candidate returned ${response.statusCode}');
      } catch (e) {
        debugPrint('[ChatService] Failed to reach $candidate: $e');
        if (_resolvedBaseUrl == candidate) {
          _resolvedBaseUrl = null;
        }
      }
    }

    // All endpoints failed or timed out -> execute deterministic local fallback
    debugPrint('[ChatService] All server endpoints unreachable, falling back to local data');
    return await _localFallback(trimmed, route);
  }

  /// Deterministic on-device fallback using bundled pandals and stations GeoJSON.
  Future<ChatReply> _localFallback(String question, RouteSummary? route) async {
    final q = question.toLowerCase();

    // 1. Helpline intent
    if (q.contains('help') ||
        q.contains('police') ||
        q.contains('emergency') ||
        q.contains('danger') ||
        q.contains('phone')) {
      return ChatReply.fallback(
        '🚨 Emergency Helplines:\n'
        '• Kolkata Police Emergency: 100 / 112\n'
        '• Kolkata Traffic Control: 1073 / (033) 2214-3644\n'
        '• Medical Ambulance: 102 / 108\n'
        '• Women Safety Helpline: 1091\n'
        '• Fire Control: 101',
        factsAsOf: DateTime.now(),
      );
    }

    // 2. Metro / Nearest station intent
    if (q.contains('metro') || q.contains('station') || q.contains('train')) {
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
          if (metro != null && metro.isNotEmpty) {
            buffer.write('🚇 Metro: $metro Metro Station\n');
          }
          if (stations.isNotEmpty) {
            final stationDetails = stations.map((s) {
              final dist = haversineMeters(p.lat, p.lng, s.lat, s.lon);
              return '${s.name} (${(dist / 1000).toStringAsFixed(1)} km)';
            }).join(', ');
            buffer.write('🚆 Nearby Stations: $stationDetails');
          }
          return ChatReply.fallback(buffer.toString(), factsAsOf: DateTime.now());
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
        );
      }
    }

    // 5. General fallback
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
