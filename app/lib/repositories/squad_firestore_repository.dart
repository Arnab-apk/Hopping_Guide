import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../models/squad_member.dart';
import '../services/queue_wait_service.dart';

/// Clean Cloud Firestore repository for Durga Puja Hopping Squads.
/// Inspired by the group & chat architecture in CHAT_APP-FLUTTER.
/// Handles serverless real-time sync for squads, companions, live location sharing,
/// and group festival chat across mobile devices.
class SquadFirestoreRepository {
  SquadFirestoreRepository({FirebaseFirestore? firestore}) : _injectedFirestore = firestore;

  final FirebaseFirestore? _injectedFirestore;

  FirebaseFirestore? get _firestore {
    if (_injectedFirestore != null) return _injectedFirestore;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  bool get isAvailable => _firestore != null;

  static final Random _rng = Random();

  /// Generates a human-friendly 8-character squad join code (e.g. PUJA7K9X)
  static String generateSquadCode([String prefix = 'PUJA']) {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final suffix = List.generate(4, (_) => chars[_rng.nextInt(chars.length)]).join();
    return '$prefix$suffix';
  }

  /// Create a new squad in Firestore
  Future<Map<String, dynamic>> createSquad({
    required String name,
    required String meetupPointName,
    required double meetupLat,
    required double meetupLng,
    required int separationThresholdMeters,
    required SquadMember host,
  }) async {
    final fs = _firestore;
    var squadCode = generateSquadCode();
    var squadId = 'sq_$squadCode';

    final squadData = {
      'squadId': squadId,
      'squadCode': squadCode,
      'name': name,
      'hostId': host.id,
      'hostName': host.name,
      'meetupPointName': meetupPointName,
      'meetupLat': meetupLat,
      'meetupLng': meetupLng,
      'separationThresholdMeters': separationThresholdMeters,
      'membersUid': [host.id],
      'chosenPandals': <Map<String, dynamic>>[],
      'isHoppingActive': false,
      'activeStopIndex': 0,
      'lastMessage': 'Squad created. Welcome to Durga Puja hopping!',
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (fs != null) {
        // Use the code in the document ID and reserve it transactionally.
        // Two creators cannot accidentally receive the same invite code.
        var created = false;
        for (var attempt = 0; attempt < 5 && !created; attempt++) {
          final squadDoc = fs.collection('squads').doc(squadId);
          final hostData = host.toJson();
          hostData['last_seen'] = DateTime.now().millisecondsSinceEpoch;
          created = await fs.runTransaction<bool>((transaction) async {
            if ((await transaction.get(squadDoc)).exists) return false;
            transaction.set(squadDoc, squadData);
            transaction.set(squadDoc.collection('members').doc(host.id), hostData);
            return true;
          });
          if (!created) {
            squadCode = generateSquadCode();
            squadId = 'sq_$squadCode';
            squadData['squadId'] = squadId;
            squadData['squadCode'] = squadCode;
          }
        }
        if (!created) throw StateError('Could not reserve a unique group code');

        final squadDoc = fs.collection('squads').doc(squadId);

        // Chat is optional; a welcome message failure must not hide a real squad.
        final welcomeMsg = ChatMessage(
          id: 'welcome_$squadId',
          squadId: squadId,
          senderId: 'system_pujo',
          senderName: 'Pujo Bot 🪈',
          text: 'Welcome to "$name"! Share live crowd updates, meetup notes, and pandal photos here.',
          type: ChatMessageType.text,
          timestamp: DateTime.now(),
        );
        try {
          await squadDoc.collection('messages').doc(welcomeMsg.id).set(welcomeMsg.toJson());
        } catch (e) {
          debugPrint('[SquadFirestoreRepository] welcome message error: $e');
        }
    }

    return {
      'squadId': squadId,
      'squadCode': squadCode,
      'name': name,
      'meetupPointName': meetupPointName,
      'meetupLat': meetupLat,
      'meetupLng': meetupLng,
      'separationThresholdMeters': separationThresholdMeters,
    };
  }

  /// Lookup a squad by its 6-character uppercase code
  Future<Map<String, dynamic>?> findSquadByCode(String code) async {
    final fs = _firestore;
    if (fs == null) return null;

    try {
      final query = await fs
          .collection('squads')
          .where('squadCode', isEqualTo: code.trim().toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      final doc = query.docs.first;
      final data = doc.data();
      data['squadId'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('[SquadFirestoreRepository] findSquadByCode error: $e');
      rethrow;
    }
  }

  /// Join an existing squad with member record
  Future<bool> joinSquad({
    required String squadId,
    required SquadMember member,
  }) async {
    final fs = _firestore;
    if (fs == null) return true;

    try {
      final squadDoc = fs.collection('squads').doc(squadId);

      // Commit roster and member record together so neither can be half joined.
      final memberData = member.toJson();
      memberData['last_seen'] = DateTime.now().millisecondsSinceEpoch;
      final batch = fs.batch();
      batch.update(squadDoc, {'membersUid': FieldValue.arrayUnion([member.id])});
      batch.set(squadDoc.collection('members').doc(member.id), memberData, SetOptions(merge: true));
      await batch.commit();

      // Post join notice in chat
      final joinMsg = ChatMessage(
        id: 'join_${member.id}_${DateTime.now().millisecondsSinceEpoch}',
        squadId: squadId,
        senderId: 'system_pujo',
        senderName: 'Pujo Bot 🪈',
        text: '👋 ${member.name} joined the squad!',
        type: ChatMessageType.text,
        timestamp: DateTime.now(),
      );
      try {
        await squadDoc.collection('messages').doc(joinMsg.id).set(joinMsg.toJson());
      } catch (e) {
        debugPrint('[SquadFirestoreRepository] join notice error: $e');
      }

      return true;
    } catch (e) {
      debugPrint('[SquadFirestoreRepository] joinSquad error: $e');
      return false;
    }
  }

  /// Leave an active squad
  Future<void> leaveSquad({
    required String squadId,
    required String memberId,
    String? memberName,
  }) async {
    final fs = _firestore;
    if (fs == null) return;

    try {
      final squadDoc = fs.collection('squads').doc(squadId);

      if (memberName != null && memberName.isNotEmpty) {
        final leaveMsg = ChatMessage(
          id: 'leave_${memberId}_${DateTime.now().millisecondsSinceEpoch}',
          squadId: squadId,
          senderId: 'system_pujo',
          senderName: 'Pujo Bot 🪈',
          text: '🏃 $memberName left the squad.',
          type: ChatMessageType.text,
          timestamp: DateTime.now(),
        );
        try {
          await squadDoc.collection('messages').doc(leaveMsg.id).set(leaveMsg.toJson());
        } catch (e) {
          debugPrint('[SquadFirestoreRepository] leave notice error: $e');
        }
      }
      final batch = fs.batch();
      batch.delete(squadDoc.collection('members').doc(memberId));
      batch.update(squadDoc, {'membersUid': FieldValue.arrayRemove([memberId])});
      await batch.commit();
    } catch (e) {
      debugPrint('[SquadFirestoreRepository] leaveSquad error: $e');
      rethrow;
    }
  }

  /// Update live GPS position and presence for a member
  Future<void> updateMemberLocation({
    required String squadId,
    required String memberId,
    required double lat,
    required double lng,
    int? batteryLevel,
    bool? isOnline,
    bool? shareLocation,
    String? status,
    String? name,
    String? photoUrl,
  }) async {
    final fs = _firestore;
    if (fs == null) return;

    try {
      final updateData = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'last_seen': DateTime.now().millisecondsSinceEpoch,
      };
      if (batteryLevel != null) {
        updateData['battery'] = batteryLevel;
        updateData['batteryLevel'] = batteryLevel;
      }
      if (isOnline != null) updateData['is_online'] = isOnline;
      if (shareLocation != null) updateData['share_location'] = shareLocation;
      if (status != null && status.isNotEmpty) updateData['status'] = status;
      if (name != null && name.isNotEmpty) updateData['name'] = name;
      if (photoUrl != null && photoUrl.isNotEmpty) updateData['photo_url'] = photoUrl;

      await fs
          .collection('squads')
          .doc(squadId)
          .collection('members')
          .doc(memberId)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SquadFirestoreRepository] updateMemberLocation error: $e');
    }
  }

  /// Update squad settings (name, meetup point, radius)
  Future<void> updateSquadSettings({
    required String squadId,
    String? name,
    String? meetupPointName,
    double? meetupLat,
    double? meetupLng,
    int? separationThresholdMeters,
  }) async {
    final fs = _firestore;
    if (fs == null) return;

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (meetupPointName != null) updates['meetupPointName'] = meetupPointName;
      if (meetupLat != null) updates['meetupLat'] = meetupLat;
      if (meetupLng != null) updates['meetupLng'] = meetupLng;
      if (separationThresholdMeters != null) {
        updates['separationThresholdMeters'] = separationThresholdMeters;
      }

      if (updates.isNotEmpty) {
        await fs.collection('squads').doc(squadId).update(updates);
      }
    } catch (e) {
      debugPrint('[SquadFirestoreRepository] updateSquadSettings error: $e');
    }
  }

  /// Applies one intent to the latest server plan. Firestore retries this callback
  /// when another member changes the squad during the transaction.
  Future<Map<String, dynamic>> mutateSquadPlan({
    required String squadId,
    required Map<String, dynamic> Function(Map<String, dynamic>) change,
  }) async {
    final fs = _firestore;
    if (fs == null) throw StateError('Cloud sync is unavailable');
    final ref = fs.collection('squads').doc(squadId);
    return fs.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('This group no longer exists');
      final current = snapshot.data()!;
      final next = change(current);
      final revision = (current['planRevision'] as num?)?.toInt() ?? 0;
      final updates = <String, dynamic>{
        'chosenPandals': next['chosenPandals'],
        'isHoppingActive': next['isHoppingActive'],
        'activeStopIndex': next['activeStopIndex'],
        'planRevision': revision + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      transaction.update(ref, updates);
      return {...next, 'planRevision': revision + 1};
    });
  }

  /// Real-time stream of squad metadata
  Stream<Map<String, dynamic>?> streamSquad(String squadId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();

    return fs.collection('squads').doc(squadId).snapshots(includeMetadataChanges: true).map((snap) {
      if (!snap.exists || snap.data() == null) {
        return {'_exists': false, '_fromCache': snap.metadata.isFromCache};
      }
      final data = snap.data()!;
      data['squadId'] = snap.id;
      // A cached snapshot is useful offline, but must not be presented as live sync.
      data['_fromCache'] = snap.metadata.isFromCache;
      return data;
    });
  }

  /// Real-time stream of squad members (companions + self)
  Stream<List<SquadMember>> streamMembers(String squadId, {required String currentUserId}) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();

    return fs.collection('squads').doc(squadId).collection('members').snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['is_user'] = (doc.id == currentUserId);
        return SquadMember.fromJson(data);
      }).toList();
    });
  }

  /// Real-time stream of squad chat messages (newest first)
  Stream<List<ChatMessage>> streamMessages(String squadId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();

    return fs
        .collection('squads')
        .doc(squadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ChatMessage.fromJson(data);
      }).toList();
    });
  }

  /// Send a chat message or photo/video
  Future<void> sendMessage({
    required String squadId,
    required ChatMessage message,
  }) async {
    final fs = _firestore;
    if (fs == null) return;

    try {
      final msgData = message.toJson();
      await fs
          .collection('squads')
          .doc(squadId)
          .collection('messages')
          .doc(message.id)
          .set(msgData);

      // Update parent squad's lastMessage preview
      final previewText = message.text?.isNotEmpty == true
          ? message.text!
          : (message.isImage ? '📷 Photo' : '🎥 Video');

      await fs.collection('squads').doc(squadId).update({
        'lastMessage': previewText,
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('[SquadFirestoreRepository] sendMessage error: $e');
    }
  }

  /// Add a queue wait report to squad's queue_reports collection
  Future<void> addQueueReport({
    required String squadId,
    required QueueReport report,
  }) async {
    final fs = _firestore;
    if (fs == null) return;

    try {
      await fs
          .collection('squads')
          .doc(squadId)
          .collection('queue_reports')
          .doc('${report.pandalId}_${report.reporterId}_${report.timestamp.millisecondsSinceEpoch}')
          .set({
        'pandalId': report.pandalId,
        'waitMinutes': report.waitMinutes,
        'timestamp': report.timestamp.millisecondsSinceEpoch,
        'reporterId': report.reporterId,
        'source': report.source,
      });
    } catch (e) {
      debugPrint('[SquadFirestoreRepository] addQueueReport error: $e');
    }
  }
}
