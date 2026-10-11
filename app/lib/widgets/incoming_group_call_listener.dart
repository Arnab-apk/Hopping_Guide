import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/group_call_signaling.dart';
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
    if (Firebase.apps.isNotEmpty) {
      _auth = FirebaseAuth.instance.authStateChanges().listen((_) => _sync());
    }
    _sync();
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
      _dismiss();
      _uid = uid;
    }
    final groups = uid == null
        ? <String>{}
        : SquadService.instance.groups.map((g) => g.id).toSet();
    for (final id in _subscriptions.keys.toList()) {
      if (!groups.contains(id)) {
        unawaited(_subscriptions.remove(id)!.cancel());
        if (_incoming?.group == id) _dismiss();
      }
    }
    if (uid == null) return;
    final signaling = GroupCallSignaling(FirebaseFirestore.instance);
    for (final id in groups) {
      _subscriptions.putIfAbsent(
        id,
        () => signaling
            .invitations(id, uid)
            .listen(
              (invites) {
                if (!mounted || _uid != uid) return;
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

  void _dismiss() {
    _expiry?.cancel();
    _incoming = null;
    final dialog = _dialog;
    _dialog = null;
    if (dialog != null && dialog.isActive) {
      dialog.navigator?.removeRoute(dialog);
    }
  }

  Future<void> _show(CallInvitation invite) async {
    if (!mounted) return;
    final group = SquadService.instance.groups
        .where((g) => g.id == invite.group)
        .firstOrNull;
    if (group == null) return;
    _incoming = invite;
    unawaited(SystemSound.play(SystemSoundType.alert));
    unawaited(HapticFeedback.vibrate());
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
    if (!_foreground) _dismiss();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SquadService.instance.removeListener(_sync);
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
