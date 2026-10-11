import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';

import '../widgets/app_page_intro.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../services/group_video_api.dart';
import '../services/group_call_signaling.dart';
import '../services/incoming_call_alert.dart';

/// A foreground group room. Every join and token renewal verifies membership.
class GroupVideoCallScreen extends StatefulWidget {
  const GroupVideoCallScreen({
    super.key,
    required this.squadId,
    required this.squadName,
    this.autoJoin = false,
    this.notifyMembers = true,
  });
  final String squadId, squadName;
  final bool autoJoin, notifyMembers;
  static bool isOpen = false;

  static void open(
    BuildContext context, {
    required String squadId,
    required String squadName,
    bool autoJoin = true,
    bool notifyMembers = true,
  }) {
    if (isOpen) return;
    isOpen = true;
    unawaited(IncomingCallAlert.busy(true));
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => GroupVideoCallScreen(
              squadId: squadId,
              squadName: squadName,
              autoJoin: autoJoin,
              notifyMembers: notifyMembers,
            ),
          ),
        )
        .whenComplete(() {
          isOpen = false;
          unawaited(IncomingCallAlert.busy(false));
        });
  }

  @override
  State<GroupVideoCallScreen> createState() => _GroupVideoCallScreenState();
}

class _GroupVideoCallScreenState extends State<GroupVideoCallScreen>
    with WidgetsBindingObserver {
  final _api = GroupVideoApi();
  StreamVideo? _client;
  Call? _call;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _membership;
  StreamSubscription<firebase.User?>? _auth;
  StreamSubscription<CallStatus>? _status;
  bool _joining = false;
  bool _camera = true;
  bool _microphone = true;
  String? _invitationId;
  String? _invitationOwner;
  String? _notice;
  bool _leaving = false;
  bool _closed = false;
  String? _error;
  Future<void>? _cleanup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.autoJoin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_closed) unawaited(_join());
      });
    }
  }

  Future<void> _join() async {
    if (_joining || _call != null) return;
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      // Ask while entering the call, before waiting for the hosted server.
      // Denying media still permits a receive-only call.
      final requestedCamera = _camera;
      final permissions = await [
        Permission.microphone,
        if (requestedCamera) Permission.camera,
      ].request();
      if (!mounted || _closed) return;
      _microphone = permissions[Permission.microphone]?.isGranted ?? false;
      _camera =
          requestedCamera &&
          (permissions[Permission.camera]?.isGranted ?? false);
      if (!_microphone || (requestedCamera && !_camera)) {
        _notice = 'Joined with unavailable media switched off. You can allow camera and microphone in app settings.';
      }
      final session = await _api.session(widget.squadId);
      if (!mounted || _closed) return;
      final user = firebase.FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != session.userId) {
        throw const GroupVideoException(
          'Sign in again before joining this call.',
        );
      }
      if (!mounted || _closed) return;
      _client = StreamVideo.create(
        session.apiKey,
        user: User.regular(
          userId: session.userId,
          name: user.displayName ?? 'Group member',
        ),
        userToken: session.token,
        tokenLoader: (userId) async {
          if (_closed ||
              firebase.FirebaseAuth.instance.currentUser?.uid != userId) {
            throw const GroupVideoException('Your sign-in changed.');
          }
          try {
            final renewed = await _api.session(widget.squadId);
            if (renewed.userId != userId || renewed.callId != session.callId) {
              throw const GroupVideoException(
                'The group call changed. Please rejoin.',
              );
            }
            return renewed.token;
          } catch (_) {
            unawaited(_leave());
            rethrow;
          }
        },
      );
      final call = _client!.makeCall(
        callType: StreamCallType.custom(session.callType),
        id: session.callId,
      );
      _call = call;
      _auth = firebase.FirebaseAuth.instance.authStateChanges().listen((
        signedIn,
      ) {
        if (signedIn?.uid != session.userId) unawaited(_leave());
      });
      _membership = FirebaseFirestore.instance
          .collection('squads')
          .doc(widget.squadId)
          .snapshots(includeMetadataChanges: true)
          .listen((snapshot) {
            if (snapshot.metadata.isFromCache) return;
            final data = snapshot.data();
            if (data == null ||
                !(data['membersUid'] as List? ?? []).contains(session.userId)) {
              unawaited(_leave());
            }
          }, onError: (Object _) => unawaited(_leave()));
      final joined = await call.join(
        connectOptions: CallConnectOptions(
          camera: _camera ? TrackOption.enabled() : TrackOption.disabled(),
          microphone: _microphone
              ? TrackOption.enabled()
              : TrackOption.disabled(),
          speakerDefaultOn: true,
        ),
      );
      if (!mounted || _closed) {
        await call.leave();
        return;
      }
      if (joined.isFailure) {
        throw const GroupVideoException(
          'Could not join the call. Check your connection and try again.',
        );
      }
      _status = call.partialState((state) => state.status).listen((status) {
        if (status.isDisconnected) unawaited(_leave());
      });
      setState(() => _joining = false);
      if (_notice != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_notice!),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
      if (widget.notifyMembers) {
        try {
          final signaling = GroupCallSignaling(FirebaseFirestore.instance);
          final invitation = await signaling.invite(
            widget.squadId,
            user.uid,
            user.displayName ?? 'Group member',
          );
          if (_closed) {
            await signaling.end(widget.squadId, user.uid, invitation);
          } else {
            _invitationId = invitation;
            _invitationOwner = user.uid;
            await _api.notifyMembers(widget.squadId, invitation);
          }
        } catch (_) {
          if (mounted && !_closed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Connected, but members could not be notified. They can still join from the group.',
                ),
              ),
            );
          }
        }
      }
    } catch (error) {
      await _release();
      _cleanup = null;
      if (mounted && !_closed) {
        setState(() {
          _joining = false;
          _error = error is GroupVideoException
              ? error.message
              : 'Could not connect. Check your connection and try again.';
        });
      }
    }
  }

  Future<void> _release() => _cleanup ??= () async {
    final invitation = _invitationId;
    final owner = _invitationOwner;
    _invitationId = null;
    _invitationOwner = null;
    if (invitation != null && owner != null) {
      // Do not hold camera cleanup or leaving the screen on a network write.
      unawaited(
        GroupCallSignaling(FirebaseFirestore.instance)
            .end(widget.squadId, owner, invitation)
            .catchError((Object _) {}),
      );
    }
    await _membership?.cancel();
    _membership = null;
    await _auth?.cancel();
    _auth = null;
    await _status?.cancel();
    _status = null;
    final call = _call;
    _call = null;
    final client = _client;
    _client = null;
    try {
      await call?.leave();
    } catch (_) {
      // Still release the client and its media resources after a leave failure.
    } finally {
      try {
        await client?.dispose();
      } catch (_) {
        // Cleanup must not strand the user on the call screen.
      }
    }
  }();

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    _closed = true;
    await _release();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Camera/audio are foreground-only; returning to the app lets the user rejoin.
    if (state == AppLifecycleState.paused && _call != null) unawaited(_leave());
  }

  @override
  void dispose() {
    _closed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_release().whenComplete(_api.dispose));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_joining && _call == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.squadName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        bottomNavigationBar: _call != null && !_joining
            ? SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Center(
                  heightFactor: 1,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      minimumSize: const Size(160, 56),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => unawaited(_leave()),
                    icon: const Icon(Icons.call_end_rounded),
                    label: const Text('End call'),
                  ),
                ),
              )
            : null,
        body: _call != null && !_joining
            ? StreamCallContent(
                call: _call!,
                callAppBarWidgetBuilder: (_, _) => const PreferredSize(
                  preferredSize: Size.zero,
                  child: SizedBox.shrink(),
                ),
                onBackPressed: () => unawaited(_leave()),
                onLeaveCallTap: () => unawaited(_leave()),
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIconWell(
                          icon: Icons.videocam_outlined,
                          size: 36,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Group video call',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Group members with notifications enabled receive an incoming-call alert. Camera and microphone access are requested when you connect.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SwitchListTile(
                          title: const Text('Camera on'),
                          value: _camera,
                          onChanged: _joining
                              ? null
                              : (value) => setState(() => _camera = value),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        if (_joining)
                          const CircularProgressIndicator()
                        else
                          FilledButton.icon(
                            onPressed: _join,
                            icon: const Icon(Icons.video_call),
                            label: const Text('Join group call'),
                          ),
                        if (_error != null)
                          TextButton(
                            onPressed: openAppSettings,
                            child: const Text('Open permission settings'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
