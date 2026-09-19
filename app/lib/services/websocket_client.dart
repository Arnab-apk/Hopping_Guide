import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Robust, low-latency WebSocket client for Kolkata Puja hopping squads.
/// Supports exponential backoff reconnection (1s..30s), automatic heartbeats,
/// scoped squad channels (`squad:<squad_id>`), and standardized event envelopes.
class WebSocketClient {
  WebSocketClient({String? serverUrl}) : _configuredServerUrl = serverUrl;

  final String? _configuredServerUrl;
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  final _stateController = StreamController<WebSocketConnectionState>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  WebSocketConnectionState _currentState = WebSocketConnectionState.disconnected;

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  String? _lastAuthToken;
  String? _lastSquadId;
  bool _intentionalClose = false;

  final List<Map<String, dynamic>> _messageBuffer = [];
  static const int _maxBufferedMessages = 20;

  Stream<WebSocketConnectionState> get connectionState => _stateController.stream;
  WebSocketConnectionState get currentState => _currentState;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _currentState == WebSocketConnectionState.connected;

  String get defaultServerUrl {
    final customUrl = _configuredServerUrl;
    if (customUrl != null && customUrl.isNotEmpty) {
      return customUrl;
    }

    const envUrl = String.fromEnvironment('WEBSOCKET_SERVER_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'ws://10.0.2.2:8080/ws';
    }

    return 'ws://localhost:8080/ws';
  }

  void _setState(WebSocketConnectionState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
      debugPrint('[WebSocketClient] State changed -> $newState');
    }
  }

  /// Construct standard channel URI with token & squadId query parameters
  Uri buildChannelUri({String? token, String? squadId}) {
    final base = defaultServerUrl;
    final params = <String>[];
    if (token != null && token.isNotEmpty) {
      params.add('token=${Uri.encodeComponent(token)}');
    }
    if (squadId != null && squadId.isNotEmpty) {
      params.add('squadId=${Uri.encodeComponent(squadId)}');
    }

    final queryString = params.isNotEmpty
        ? (base.contains('?') ? '&${params.join('&')}' : '?${params.join('&')}')
        : '';
    return Uri.parse('$base$queryString');
  }

  /// Establish WebSocket connection with user authentication token & squadId
  Future<void> connect([String? authToken, String? squadId]) async {
    _lastAuthToken = authToken ?? _lastAuthToken;
    _lastSquadId = squadId ?? _lastSquadId;
    _intentionalClose = false;
    _reconnectTimer?.cancel();

    final fullUri = buildChannelUri(token: _lastAuthToken, squadId: _lastSquadId);

    debugPrint('[WebSocketClient] Connecting to $fullUri');
    _setState(_reconnectAttempts > 0
        ? WebSocketConnectionState.reconnecting
        : WebSocketConnectionState.connecting);

    try {
      _cleanupChannel();
      _channel = WebSocketChannel.connect(fullUri);

      _channel!.ready.then((_) {
        _setState(WebSocketConnectionState.connected);
        _reconnectAttempts = 0; // Reset backoff upon successful connection
        _startHeartbeat();
        _flushBuffer();
      }).catchError((e) {
        debugPrint('[WebSocketClient] Channel ready note: $e');
        _onError(e);
      });

      // Listen for events
      _channelSubscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[WebSocketClient] Connect error: $e');
      _setState(WebSocketConnectionState.error);
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is Map<String, dynamic>) {
        if (decoded['type'] == 'heartbeat_ack') {
          return;
        }
        _messageController.add(decoded);
      }
    } catch (e) {
      debugPrint('[WebSocketClient] JSON parse error: $e (payload: $raw)');
    }
  }

  void _onError(dynamic error) {
    debugPrint('[WebSocketClient] Stream error: $error');
    _setState(WebSocketConnectionState.error);
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[WebSocketClient] Stream disconnected (done)');
    if (!_intentionalClose) {
      _setState(WebSocketConnectionState.disconnected);
      _scheduleReconnect();
    } else {
      _setState(WebSocketConnectionState.disconnected);
    }
  }

  /// Sends a raw message or standardized envelope, buffering it if temporarily disconnected
  Future<void> sendMessage(Map<String, dynamic> message) async {
    message.putIfAbsent('timestamp', () => DateTime.now().millisecondsSinceEpoch);

    if (_channel != null && isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message));
        return;
      } catch (e) {
        debugPrint('[WebSocketClient] Send failed: $e');
      }
    }

    // Buffer up to limit
    if (_messageBuffer.length >= _maxBufferedMessages) {
      _messageBuffer.removeAt(0);
    }
    _messageBuffer.add(message);
  }

  /// Standardized Realtime Envelope helper (Section 22)
  Future<Map<String, dynamic>> sendEnvelope({
    required String type,
    required String squadId,
    required String senderId,
    required Map<String, dynamic> payload,
    String? eventId,
  }) async {
    final envelope = <String, dynamic>{
      'type': type,
      'eventId': eventId ?? 'evt_${DateTime.now().millisecondsSinceEpoch}',
      'squadId': squadId,
      'senderId': senderId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'payload': payload,
    };
    await sendMessage(envelope);
    return envelope;
  }

  void _flushBuffer() {
    if (_messageBuffer.isEmpty || !isConnected || _channel == null) return;
    final pending = List<Map<String, dynamic>>.from(_messageBuffer);
    _messageBuffer.clear();

    for (final msg in pending) {
      try {
        _channel!.sink.add(jsonEncode(msg));
      } catch (e) {
        debugPrint('[WebSocketClient] Flush error: $e');
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({
            'type': 'heartbeat',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }));
        } catch (_) {}
      }
    });
  }

  /// Exponential backoff reconnect: 1s, 2s, 4s, 8s, up to 30s max (Sections 42-43)
  void _scheduleReconnect() {
    if (_intentionalClose) return;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    _reconnectAttempts++;
    final delaySeconds = min(pow(2, _reconnectAttempts - 1).toInt(), 30);
    debugPrint('[WebSocketClient] Reconnect attempt #$_reconnectAttempts in ${delaySeconds}s');

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      connect(_lastAuthToken, _lastSquadId);
    });
  }

  void _cleanupChannel() {
    _heartbeatTimer?.cancel();
    _channelSubscription?.cancel();
    _channelSubscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  /// Close connection intentionally
  Future<void> close() async {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _cleanupChannel();
    _setState(WebSocketConnectionState.disconnected);
  }

  void dispose() {
    close();
    _stateController.close();
    _messageController.close();
  }
}
