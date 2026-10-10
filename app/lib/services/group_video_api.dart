import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GroupVideoException implements Exception {
  const GroupVideoException(this.message);
  final String message;
  @override
  String toString() => message;
}

class GroupVideoSession {
  const GroupVideoSession({
    required this.apiKey,
    required this.userId,
    required this.token,
    required this.callId,
    required this.callType,
  });
  final String apiKey, userId, token, callId, callType;

  factory GroupVideoSession.fromJson(Map<String, dynamic> data) {
    String field(String key) {
      final value = data[key];
      if (value is! String || value.isEmpty) {
        throw const GroupVideoException(
          'The calling server returned an invalid session.',
        );
      }
      return value;
    }

    return GroupVideoSession(
      apiKey: field('apiKey'),
      userId: field('userId'),
      token: field('token'),
      callId: field('callId'),
      callType: field('callType'),
    );
  }
}

class GroupVideoApi {
  GroupVideoApi({
    http.Client? client,
    String? baseUrl,
    Future<String?> Function()? idTokenLoader,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? const String.fromEnvironment('VIDEO_API_URL'),
       _idTokenLoader = idTokenLoader ?? _firebaseToken;

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _idTokenLoader;

  static Future<String?> _firebaseToken() async {
    // Do not use AuthService's demo UID fallback as a bearer token.
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Future<GroupVideoSession> session(String squadId) async {
    final token = await _idTokenLoader();
    if (token == null || token.isEmpty) {
      throw const GroupVideoException('Sign in to join a group video call.');
    }
    const neonUrl = String.fromEnvironment('NEON_API_URL');
    final base = _baseUrl.isNotEmpty
        ? _baseUrl
        : neonUrl.isNotEmpty
        ? neonUrl
        : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://127.0.0.1:8080'
        : 'http://localhost:8080';
    final uri = Uri.parse(
      '${base.replaceAll(RegExp(r"/+$"), "")}/api/squads/${Uri.encodeComponent(squadId)}/video/session',
    );
    final response = await _client
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 90));
    if (response.statusCode != 200) {
      switch (response.statusCode) {
        case 401:
          throw const GroupVideoException(
            'Your sign-in expired. Sign in again.',
          );
        case 403:
          throw const GroupVideoException(
            'You are no longer a member of this group.',
          );
        case 429:
          throw const GroupVideoException(
            'Too many attempts. Try again in a minute.',
          );
        case 503:
          throw const GroupVideoException(
            'Group calling is unavailable. Check the server configuration and try again.',
          );
        default:
          throw const GroupVideoException(
            'Could not connect to group calling. Try again.',
          );
      }
    }
    return GroupVideoSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void dispose() => _client.close();
}
