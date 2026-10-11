import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'squad_service.dart';
import 'incoming_call_alert.dart';

/// FCM displays background/locked-screen alerts without retaining the map or a
/// Stream media connection. Opening an alert still verifies its live invitation.
class GroupCallPushService {
  GroupCallPushService._();
  static final instance = GroupCallPushService._();
  static final dismissedInvitation = ValueNotifier<String?>(null);
  static final pendingInvitation =
      ValueNotifier<({String group, String id, bool accept})?>(null);
  String? _uid, _token;
  String _membershipKey = '';
  bool _busy = false;
  bool _again = false;
  bool _initialized = false;
  final _registered = <String>{};

  Future<void> initialize() async {
    if (_initialized ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _initialized = true;
    try {
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'uma_incoming_calls',
              'Incoming group calls',
              description: 'Calls from members of your hopping groups',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
      FirebaseMessaging.onMessageOpenedApp.listen(_open);
      IncomingCallAlert.channel.setMethodCallHandler((call) async {
        if (call.method == 'opened') _openNative(call.arguments);
        if (call.method == 'dismissed' && call.arguments is String) {
          dismissedInvitation.value = call.arguments as String;
        }
      });
      _openNative(await IncomingCallAlert.invoke<Object>('pending'));
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _open(initial);
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _token = token;
        _registered.clear();
        refresh();
      });
      FirebaseAuth.instance.authStateChanges().listen((_) => refresh());
      SquadService.instance.addListener(_onGroupsChanged);
      refresh();
    } catch (_) {
      _initialized = false;
      debugPrint('[GroupCalls] Push initialization unavailable.');
    }
  }

  void _openNative(Object? value) {
    if (value is! Map) return;
    final expiry = int.tryParse(value['expiresAt']?.toString() ?? '');
    if (expiry == null ||
        expiry <= DateTime.now().millisecondsSinceEpoch ||
        value['groupId'] is! String ||
        value['invitationId'] is! String) {
      return;
    }
    pendingInvitation.value = (
      group: value['groupId'] as String,
      id: value['invitationId'] as String,
      accept: value['action'] == 'answer',
    );
  }

  void _open(RemoteMessage message) {
    final data = message.data;
    final expiry = int.tryParse(data['expiresAt'] ?? '');
    if (data['type'] != 'group_call' ||
        expiry == null ||
        expiry <= DateTime.now().millisecondsSinceEpoch ||
        data['groupId'] is! String ||
        data['invitationId'] is! String) {
      return;
    }
    pendingInvitation.value = (
      group: data['groupId'] as String,
      id: data['invitationId'] as String,
      accept: false,
    );
  }

  void _onGroupsChanged() {
    final groups = SquadService.instance.groups.map((g) => g.id).toSet();
    _registered.removeWhere((id) => !groups.contains(id));
    final key = groups.join(',');
    if (key == _membershipKey) return;
    _membershipKey = key;
    refresh();
  }

  void refresh() {
    if (!_initialized) return;
    if (_busy) {
      _again = true;
      return;
    }
    unawaited(_register());
  }

  Future<void> _register() async {
    _busy = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await IncomingCallAlert.invoke<void>('configure', {
        'uid': uid,
        'groups': SquadService.instance.groups.map((g) => g.id).toList(),
      });
      if (uid != _uid) {
        if (_uid != null) {
          await FirebaseMessaging.instance.deleteToken();
          pendingInvitation.value = null;
        }
        _uid = uid;
        _token = null;
        _registered.clear();
      }
      if (uid == null || SquadService.instance.groups.isEmpty) return;
      final permission = await FirebaseMessaging.instance.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied) return;
      _token ??= await FirebaseMessaging.instance.getToken();
      final token = _token;
      if (token == null || FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }
      for (final group in SquadService.instance.groups) {
        if (_registered.contains(group.id)) continue;
        await FirebaseFirestore.instance
            .collection('squads')
            .doc(group.id)
            .collection('members')
            .doc(uid)
            .set({
              'callPushTokens': FieldValue.arrayUnion([token]),
              'callRingTokens': FieldValue.arrayUnion([token]),
            }, SetOptions(merge: true));
        if (FirebaseAuth.instance.currentUser?.uid != uid || _token != token) {
          return;
        }
        _registered.add(group.id);
      }
    } catch (_) {
      debugPrint('[GroupCalls] Notification registration needs a retry.');
    } finally {
      _busy = false;
      if (_again) {
        _again = false;
        refresh();
      }
    }
  }
}
