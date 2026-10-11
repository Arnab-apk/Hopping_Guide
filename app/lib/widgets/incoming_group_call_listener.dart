import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/group_call_signaling.dart';
import '../services/group_call_push_service.dart';
import '../services/incoming_call_alert.dart';
import '../services/squad_service.dart';
import '../screens/group_video_call_screen.dart';

class IncomingGroupCallListener extends StatefulWidget {
  const IncomingGroupCallListener({super.key, required this.child});
  final Widget child;
  @override
  State<IncomingGroupCallListener> createState() =>
      _IncomingGroupCallListenerState();
}

class _IncomingGroupCallListenerState extends State<IncomingGroupCallListener>
    with WidgetsBindingObserver {
  final _subscriptions = <String, StreamSubscription<List<CallInvitation>>>{};
  final _seen = <String>{};
  final _latest = <String, List<CallInvitation>>{};
  StreamSubscription<User?>? _auth;
  String? _uid;
  CallInvitation? _incoming;
  DialogRoute<bool>? _dialog;
  Timer? _expiry;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SquadService.instance.addListener(_sync);
    GroupCallPushService.pendingInvitation.addListener(_openPush);
    GroupCallPushService.dismissedInvitation.addListener(_nativeDismissed);
    if (Firebase.apps.isNotEmpty) {
      _auth = FirebaseAuth.instance.authStateChanges().listen((_) => _sync());
    }
    _sync();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPush());
  }

  void _nativeDismissed() {
    final id = GroupCallPushService.dismissedInvitation.value;
    if (id == null) return;
    _seen.add(id);
    if (_incoming?.id == id) _dismiss();
  }

  void _sync() {
    if (Firebase.apps.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != _uid) {
      for (final sub in _subscriptions.values) {
        unawaited(sub.cancel());
      }
      _subscriptions.clear();
      _seen.clear();
      _latest.clear();
      _dismiss();
      _uid = uid;
    }
    final groups = uid == null
        ? <String>{}
        : SquadService.instance.groups.map((g) => g.id).toSet();
    for (final id in _subscriptions.keys.toList()) {
      if (!groups.contains(id)) {
        _latest.remove(id);
        unawaited(_subscriptions.remove(id)!.cancel());
        if (_incoming?.group == id) _dismiss();
      }
    }
    if (uid == null) return;
    _openPush();
    final signaling = GroupCallSignaling(FirebaseFirestore.instance);
    for (final id in groups) {
      _subscriptions.putIfAbsent(
        id,
        () => signaling
            .invitations(id, uid)
            .listen(
              (invites) {
                if (!mounted || _uid != uid) return;
                _latest[id] = invites;
                if (_incoming?.group == id &&
                    !invites.any((i) => i.id == _incoming!.id)) {
                  _dismiss();
                }
                if (!_foreground ||
                    _dialog != null ||
                    GroupVideoCallScreen.isOpen) {
                  return;
                }
                for (final invite in invites) {
                  if (_seen.add(invite.id)) {
                    if (_seen.length > 100) _seen.remove(_seen.first);
                    _show(invite);
                    break;
                  }
                }
              },
              onError: (Object _) {
                if (_incoming?.group == id) _dismiss();
              },
            ),
      );
    }
  }

  void _dismiss({bool stopRinging = true}) {
    _expiry?.cancel();
    final incoming = _incoming;
    if (incoming != null) {
      if (stopRinging) {
        unawaited(IncomingCallAlert.stop(incoming.id));
      } else {
        _seen.remove(incoming.id);
      }
    }
    _incoming = null;
    final dialog = _dialog;
    _dialog = null;
    if (dialog != null && dialog.isActive) {
      dialog.navigator?.removeRoute(dialog);
    }
  }

  bool _openingPush = false;
  Future<void> _openPush() async {
    final pending = GroupCallPushService.pendingInvitation.value;
    if (pending?.accept == true &&
        _dialog != null &&
        _incoming?.id == pending?.id) {
      _dismiss(stopRinging: false);
    }
    if (!mounted ||
        pending == null ||
        _uid == null ||
        _openingPush ||
        !_foreground ||
        GroupVideoCallScreen.isOpen ||
        _dialog != null ||
        !SquadService.instance.groups.any((g) => g.id == pending.group)) {
      return;
    }
    _openingPush = true;
    final uid = _uid!;
    try {
      final messages = FirebaseFirestore.instance
          .collection('squads')
          .doc(pending.group)
          .collection('messages');
      final doc = await messages
          .doc(pending.id)
          .get(const GetOptions(source: Source.server));
      final ended = await messages
          .doc('${pending.id}_ended')
          .get(const GetOptions(source: Source.server));
      if (!mounted ||
          _uid != uid ||
          !_foreground ||
          _dialog != null ||
          GroupVideoCallScreen.isOpen) {
        return;
      }
      final invite = CallInvitation.fromData(
        doc.id,
        pending.group,
        doc.data() ?? {},
        uid,
        {
          if (ended.data()?['senderId'] is String)
            pending.id: ended.data()!['senderId'] as String,
        },
      );
      GroupCallPushService.pendingInvitation.value = null;
      if (invite != null) {
        _seen.add(invite.id);
        if (pending.accept) {
          final group = SquadService.instance.groups
              .where((g) => g.id == invite.group)
              .firstOrNull;
          if (group != null) {
            GroupVideoCallScreen.open(
              context,
              squadId: group.id,
              squadName: group.name,
              notifyMembers: false,
            );
          }
        } else {
          unawaited(_show(invite));
        }
      }
    } catch (_) {
      // A later authoritative message snapshot can still surface the call.
    } finally {
      _openingPush = false;
    }
  }

  Future<void> _show(CallInvitation invite) async {
    if (!mounted || _incoming != null || !_foreground) return;
    final group = SquadService.instance.groups
        .where((g) => g.id == invite.group)
        .firstOrNull;
    if (group == null) return;
    _incoming = invite;
    final handled =
        await IncomingCallAlert.invoke<bool>('handled', invite.id) ?? false;
    if (!mounted ||
        _incoming != invite ||
        !_foreground ||
        GroupVideoCallScreen.isOpen) {
      return;
    }
    if (handled || !invite.expiresAt.isAfter(DateTime.now())) {
      _incoming = null;
      return;
    }
    unawaited(
      IncomingCallAlert.invoke<bool>('show', {
        'invitationId': invite.id,
        'groupId': invite.group,
        'expiresAt': '${invite.expiresAt.millisecondsSinceEpoch}',
        'callerName': invite.caller,
        'groupName': group.name,
      }),
    );
    final dialog = DialogRoute<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Incoming group call'),
        content: Text('${invite.caller} is calling ${group.name}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Decline'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.call),
            label: const Text('Accept'),
          ),
        ],
      ),
    );
    _dialog = dialog;
    _expiry = Timer(invite.expiresAt.difference(DateTime.now()), _dismiss);
    final accepted = await Navigator.of(
      context,
      rootNavigator: true,
    ).push(dialog);
    if (accepted != null) await IncomingCallAlert.stop(invite.id);
    if (identical(_dialog, dialog)) {
      _dialog = null;
      _incoming = null;
      _expiry?.cancel();
    }
    if (accepted == true &&
        mounted &&
        _foreground &&
        _uid != null &&
        SquadService.instance.groups.any((g) => g.id == invite.group)) {
      GroupVideoCallScreen.open(
        context,
        squadId: group.id,
        squadName: group.name,
        autoJoin: true,
        notifyMembers: false,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _dismiss(stopRinging: false);
    if (_foreground) {
      GroupCallPushService.instance.refresh();
      _openPush();
      for (final invites in _latest.values) {
        for (final invite in invites) {
          if (_incoming == null &&
              invite.expiresAt.isAfter(DateTime.now()) &&
              _seen.add(invite.id)) {
            unawaited(_show(invite));
          }
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SquadService.instance.removeListener(_sync);
    GroupCallPushService.pendingInvitation.removeListener(_openPush);
    GroupCallPushService.dismissedInvitation.removeListener(_nativeDismissed);
    _auth?.cancel();
    for (final sub in _subscriptions.values) {
      unawaited(sub.cancel());
    }
    _expiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
