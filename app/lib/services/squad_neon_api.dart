import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Structured error thrown by Neon API operations
class SquadApiException implements Exception {
  const SquadApiException(this.code, this.message, [this.statusCode]);

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'SquadApiException: [$code] ($statusCode) $message';
}

/// HTTP REST API client for PandalMap Hopping Squads backed by Neon Postgres
class SquadNeonApi {
  SquadNeonApi({this._baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String? _baseUrl;
  final http.Client _client;

  String get baseUrl {
    final customUrl = _baseUrl;
    if (customUrl != null && customUrl.isNotEmpty) return customUrl;
    const envUrl = String.fromEnvironment('NEON_API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    // Android emulator maps host machine localhost to 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.instance.getIdToken();
    final uid = AuthService.instance.currentUserModel?.uid ?? '';
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (uid.isNotEmpty) 'x-user-id': uid,
    };
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return {};
      }
    }

    String code = 'API_ERROR';
    String message = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';

    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['error'] is Map) {
        final err = data['error'] as Map;
        code = err['code']?.toString() ?? code;
        message = err['message']?.toString() ?? message;
      }
    } catch (_) {}

    throw SquadApiException(code, message, response.statusCode);
  }

  /// Create a new squad in Neon Postgres
  Future<Map<String, dynamic>> createSquad({
    required String name,
    required double meetupLat,
    required double meetupLng,
    String? meetupLabel,
    int? separationRadiusM,
    String? hostDisplayName,
    String? hostAvatarUrl,
    bool isGuest = true,
  }) async {
    final uri = Uri.parse('$baseUrl/api/squads');
    final headers = await _headers();
    final body = jsonEncode({
      'name': name,
      'meetupLat': meetupLat,
      'meetupLng': meetupLng,
      'meetupLabel': meetupLabel,
      'separationRadiusM': separationRadiusM ?? 500,
      'hostDisplayName': hostDisplayName,
      'hostAvatarUrl': hostAvatarUrl,
      'isGuest': isGuest,
    });

    final res = await _client.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 8));
    final data = _processResponse(res);
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Join an existing squad with a cryptographic code (PUJA-XXXX)
  Future<Map<String, dynamic>> joinSquad({
    required String code,
    String? displayName,
    String? avatarUrl,
    bool isGuest = true,
  }) async {
    final uri = Uri.parse('$baseUrl/api/squads/join');
    final headers = await _headers();
    final body = jsonEncode({
      'code': code.trim().toUpperCase(),
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'isGuest': isGuest,
    });

    final res = await _client.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 8));
    final data = _processResponse(res);
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Preview squad details before joining (privacy-safe: 0 member coordinates exposed)
  Future<Map<String, dynamic>> getSquadPreview(String code) async {
    final norm = code.trim().toUpperCase();
    final uri = Uri.parse('$baseUrl/api/squads/preview/$norm');
    final headers = await _headers();

    final res = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 6));
    final data = _processResponse(res);
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Alias for getSquadPreview
  Future<Map<String, dynamic>> previewSquad(String code) => getSquadPreview(code);

  /// Fetch full squad metadata
  Future<Map<String, dynamic>> getSquad(String squadId) async {
    final uri = Uri.parse('$baseUrl/api/squads/$squadId');
    final headers = await _headers();

    final res = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 6));
    final data = _processResponse(res);
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Fetch squad members roster
  Future<List<Map<String, dynamic>>> getSquadMembers(String squadId) async {
    final uri = Uri.parse('$baseUrl/api/squads/$squadId/members');
    final headers = await _headers();

    final res = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 6));
    final data = _processResponse(res);
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Fetch latest member locations
  Future<List<Map<String, dynamic>>> getSquadLocations(String squadId) async {
    final uri = Uri.parse('$baseUrl/api/squads/$squadId/locations');
    final headers = await _headers();

    final res = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 6));
    final data = _processResponse(res);
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Leave or close a squad
  Future<void> leaveSquad(String squadId, [String? userId]) async {
    final uri = Uri.parse('$baseUrl/api/squads/$squadId/leave');
    final headers = await _headers();
    final payload = <String, dynamic>{};
    if (userId != null) payload['userId'] = userId;
    final body = jsonEncode(payload);

    final res = await _client.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 6));
    _processResponse(res);
  }

  /// Host updates designated meetup point
  Future<Map<String, dynamic>> updateMeetup({
    required String squadId,
    required double lat,
    required double lng,
    required String label,
  }) async {
    final uri = Uri.parse('$baseUrl/api/squads/$squadId/meetup');
    final headers = await _headers();
    final body = jsonEncode({'lat': lat, 'lng': lng, 'label': label});

    final res = await _client.patch(uri, headers: headers, body: body).timeout(const Duration(seconds: 6));
    final data = _processResponse(res);
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Host updates settings (e.g. separation radius)
  Future<Map<String, dynamic>> updateSettings({
    required String squadId,
    int? separationRadiusM,
    String? name,
  }) async {
    final uri = Uri.parse('$baseUrl/api/squads/$squadId/settings');
    final headers = await _headers();
    final payload = <String, dynamic>{};
    if (separationRadiusM != null) payload['separationRadiusM'] = separationRadiusM;
    if (name != null) payload['name'] = name;
    final body = jsonEncode(payload);

    final res = await _client.patch(uri, headers: headers, body: body).timeout(const Duration(seconds: 6));
    final data = _processResponse(res);
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Get historical chat messages
  Future<List<Map<String, dynamic>>> getMessages(String squadId, {int limit = 50}) async {
    final uri = Uri.parse('$baseUrl/api/squads/$squadId/messages?limit=$limit');
    final headers = await _headers();

    final res = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 6));
    final data = _processResponse(res);
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Post a new chat message
  Future<Map<String, dynamic>> sendMessage({
    required String squadId,
    required String message,
    String messageType = 'text',
    String? mediaUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/api/squads/$squadId/messages');
    final headers = await _headers();
    final body = jsonEncode({
      'message': message,
      'messageType': messageType,
      'mediaUrl': mediaUrl,
    });

    final res = await _client.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 6));
    final data = _processResponse(res);
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}
