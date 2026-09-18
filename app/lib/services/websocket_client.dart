import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Robust, low-latency WebSocket client for squad live-tracking.
/// Supports exponential backoff reconnection, automatic heartbeats,
/// and message streams.
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
  bool _intentionalClose = false;

  final List<Map<String, dynamic>> _messageBuffer = [];
  static const int _maxBufferedMessages = 10;

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

    return 'ws://localhost:8080/squad';
  }

  void _setState(WebSocketConnectionState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
      debugPrint('[WebSocketClient] State changed -> $newState');
    }
  }

  /// Establish WebSocket connection with user authentication token
  Future<void> connect([String? authToken]) async {
    _lastAuthToken = authToken;
    _intentionalClose = false;
    _reconnectTimer?.cancel();

    final base = defaultServerUrl;
    final tokenParam = authToken != null && authToken.isNotEmpty
        ? (base.contains('?') ? '&token=$authToken' : '?token=$authToken')
        : '';
    final fullUri = Uri.parse('$base$tokenParam');

    debugPrint('[WebSocketClient] Connecting to $fullUri');
    _setState(_reconnectAttempts > 0
        ? WebSocketConnectionState.reconnecting
        : WebSocketConnectionState.connecting);

    try {
      _cleanupChannel();
      _channel = WebSocketChannel.connect(fullUri);

      _channel!.ready.then((_) {
        _setState(WebSocketConnectionState.connected);
        _reconnectAttempts = 0;
        _startHeartbeat();
        _flushBuffer();
      }).catchError((e) {
        debugPrint('[WebSocketClient] Channel ready note: $e');
        _onError(e);
      });

      // Wait for channel readiness or first stream event
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
        // If it's a heartbeat ack, silence it or log
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

  /// Sends a message, or buffers it if temporarily disconnected
  Future<void> sendMessage(Map<String, dynamic> message) async {
    message['timestamp'] = DateTime.now().millisecondsSinceEpoch;

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

  void _scheduleReconnect() {
    if (_intentionalClose) return;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    if (_reconnectAttempts >= 3) {
      debugPrint('[WebSocketClient] Max reconnect attempts reached, standing by');
      return;
    }

    _reconnectAttempts++;
    final delaySeconds = 1 << (_reconnectAttempts - 1);
    debugPrint('[WebSocketClient] Scheduling reconnect attempt #$_reconnectAttempts in ${delaySeconds}s');

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      connect(_lastAuthToken);
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
