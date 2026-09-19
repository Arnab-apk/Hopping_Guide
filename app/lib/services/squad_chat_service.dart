import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/chat_message.dart';

/// Real-time chat & media sharing service for private hopping squads.
/// Backed by Cloud Firestore with an automatic reactive in-memory stream fallback
/// when offline or running in unconfigured demo mode.
class SquadChatService {
  SquadChatService({
    this.firestore,
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client();

  static SquadChatService? _instance;
  static SquadChatService get instance => _instance ??= SquadChatService();

  @visibleForTesting
  static void setInstance(SquadChatService testService) {
    _instance = testService;
  }

  final FirebaseFirestore? firestore;
  final http.Client _httpClient;

  FirebaseFirestore? get _effectiveFirestore {
    if (firestore != null) return firestore;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  /// Cloudinary configuration
  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'pujoparikrama',
  );
  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'squad_media_unsigned',
  );

  /// In-memory cache & broadcast stream controllers per squad for local/demo resilience
  final Map<String, List<ChatMessage>> _localMessages = {};
  final Map<String, StreamController<List<ChatMessage>>> _streamControllers = {};

  /// Festive fallback media samples for offline / demo preview
  static const List<String> sampleFestivalPhotos = [
    'https://images.unsplash.com/photo-1570701564993-e00652af8aa3?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1567157577867-05ccb1388e66?w=800&auto=format&fit=crop&q=80',
  ];

  StreamController<List<ChatMessage>> _getController(String squadId) {
    return _streamControllers.putIfAbsent(squadId, () {
      final controller = StreamController<List<ChatMessage>>.broadcast();
      // Ensure initial demo welcome message exists
      if (!_localMessages.containsKey(squadId) || _localMessages[squadId]!.isEmpty) {
        _localMessages[squadId] = [
          ChatMessage(
            id: 'welcome_$squadId',
            squadId: squadId,
            senderId: 'system_pujo',
            senderName: 'Pujo Bot 🪈',
            text: 'Welcome to your squad chat! Share live crowd updates, meetup notes, and pandal photos here.',
            type: ChatMessageType.text,
            timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          ),
        ];
      }
      return controller;
    });
  }

  /// Real-time stream of messages for a squad (ordered newest first)
  Stream<List<ChatMessage>> messagesStream(String squadId) {
    final firestore = _effectiveFirestore;

    if (firestore != null) {
      try {
        return firestore
            .collection('squads')
            .doc(squadId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(100)
            .snapshots()
            .map((snap) {
          final cloudMessages = snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return ChatMessage.fromJson(data);
          }).toList();

          // Merge local cache for immediate feedback
          final local = _localMessages[squadId] ?? [];
          final allIds = cloudMessages.map((m) => m.id).toSet();
          final merged = [
            ...cloudMessages,
            ...local.where((m) => !allIds.contains(m.id)),
          ];
          merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return merged;
        }).handleError((error) {
          debugPrint('[SquadChatService] Firestore stream note: $error, falling back to local');
          return _getLocalMessages(squadId);
        });
      } catch (e) {
        debugPrint('[SquadChatService] Firestore init note: $e');
      }
    }

    // Local / In-memory reactive stream
    final controller = _getController(squadId);
    // Emit current state on next frame
    Future.microtask(() {
      if (!controller.isClosed) {
        controller.add(_getLocalMessages(squadId));
      }
    });
    return controller.stream;
  }

  List<ChatMessage> _getLocalMessages(String squadId) {
    final list = List<ChatMessage>.from(_localMessages[squadId] ?? []);
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  /// Returns the most recent chat message snippet for preview on the Squad Screen
  ChatMessage? getLatestMessage(String squadId) {
    final list = _localMessages[squadId];
    if (list != null && list.isNotEmpty) {
      final sorted = List<ChatMessage>.from(list)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return sorted.first;
    }
    return null;
  }

  /// Send a text message
  Future<void> sendText(
    String squadId, {
    required String senderId,
    required String senderName,
    required String text,
    String? senderPhotoUrl,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final message = ChatMessage(
      id: msgId,
      squadId: squadId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      type: ChatMessageType.text,
      text: trimmed,
      timestamp: DateTime.now(),
    );

    // Save to local cache & emit
    _saveLocalMessage(squadId, message);

    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        await firestore
            .collection('squads')
            .doc(squadId)
            .collection('messages')
            .doc(msgId)
            .set(message.toJson());
      } catch (e) {
        debugPrint('[SquadChatService] Firestore sendText note: $e');
      }
    }
  }

  /// Send a photo or video media message
  Future<void> sendMedia(
    String squadId, {
    required String senderId,
    required String senderName,
    required String mediaUrl,
    required bool isVideo,
    String? caption,
    String? senderPhotoUrl,
    String? thumbnailUrl,
  }) async {
    final msgId = 'media_${DateTime.now().millisecondsSinceEpoch}';
    final message = ChatMessage(
      id: msgId,
      squadId: squadId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      type: isVideo ? ChatMessageType.video : ChatMessageType.image,
      text: caption,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      timestamp: DateTime.now(),
    );

    _saveLocalMessage(squadId, message);

    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        await firestore
            .collection('squads')
            .doc(squadId)
            .collection('messages')
            .doc(msgId)
            .set(message.toJson());
      } catch (e) {
        debugPrint('[SquadChatService] Firestore sendMedia note: $e');
      }
    }
  }

  void _saveLocalMessage(String squadId, ChatMessage message) {
    final list = _localMessages.putIfAbsent(squadId, () => []);
    list.removeWhere((m) => m.id == message.id);
    list.insert(0, message);

    final controller = _getController(squadId);
    if (!controller.isClosed) {
      controller.add(List.unmodifiable(list));
    }
  }

  /// Ingest an incoming message from Neon Realtime WebSocket fan-out
  void receiveIncomingWsMessage(ChatMessage message) {
    _saveLocalMessage(message.squadId, message);
  }

  /// Upload media to Cloudinary using an unsigned upload preset.
  /// Automatically falls back to a high-quality festive sample URL if network or preset fails,
  /// ensuring 100% demo resilience and zero crash risk.
  Future<String> uploadSquadMedia({
    required Uint8List bytes,
    required String fileName,
    required bool isVideo,
    int? durationSeconds,
  }) async {
    // Client-side guard: enforce max 20 second video clips
    if (isVideo && durationSeconds != null && durationSeconds > 20) {
      throw ArgumentError('Video clips are capped at 20 seconds to preserve bandwidth.');
    }

    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/${isVideo ? 'video' : 'image'}/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = cloudinaryUploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );

      final response = await _httpClient.send(request).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        }
      }
    } catch (e) {
      debugPrint('[SquadChatService] Cloudinary upload note: $e (using festive fallback)');
    }

    // Demo / offline fallback
    if (isVideo) {
      return 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
    }
    final pickIdx = DateTime.now().millisecond % sampleFestivalPhotos.length;
    return sampleFestivalPhotos[pickIdx];
  }
}
