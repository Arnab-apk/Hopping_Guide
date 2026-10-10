import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../services/group_video_api.dart';

/// A foreground group room. Every join and token renewal verifies membership.
class GroupVideoCallScreen extends StatefulWidget {
  const GroupVideoCallScreen({
    super.key,
    required this.squadId,
    required this.squadName,
  });
  final String squadId, squadName;

  static void open(
    BuildContext context, {
    required String squadId,
    required String squadName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            GroupVideoCallScreen(squadId: squadId, squadName: squadName),
      ),
    );
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
  bool _leaving = false;
  bool _closed = false;
  String? _error;
  Future<void>? _cleanup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _join() async {
    if (_joining || _call != null) return;
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      final session = await _api.session(widget.squadId);
      if (!mounted || _closed) return;
      final user = firebase.FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != session.userId) {
        throw const GroupVideoException(
          'Sign in again before joining this call.',
        );
      }
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        throw const GroupVideoException(
          'Allow microphone access in Settings to join the call.',
        );
      }
      if (_camera && !(await Permission.camera.request()).isGranted) {
        throw const GroupVideoException(
          'Allow camera access in Settings, or turn off video to join with audio.',
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
          microphone: TrackOption.enabled(),
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
        appBar: AppBar(title: Text(widget.squadName)),
        body: _call != null && !_joining
            ? StreamCallContent(
                call: _call!,
                onBackPressed: () => unawaited(_leave()),
                onLeaveCallTap: () => unawaited(_leave()),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.video_call_rounded, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Group video call',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Members of this group join the same room.\nOpen the group call on another device to meet here.',
                        textAlign: TextAlign.center,
                      ),
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
    );
  }
}
