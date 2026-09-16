# Design Document: WebSocket Squad Migration

## Overview

This design specifies the technical implementation for migrating the Puja Parikrama app's squad (group) feature from Firebase Realtime Database to a custom WebSocket-based real-time communication system. The migration maintains all existing squad functionality while replacing the Firebase dependency with a self-hosted WebSocket server, enabling better control, reduced vendor lock-in, and alignment with the project's open-source goals.

The design also includes complete removal of all demo/test code that generates fake squad members, ensuring production users only interact with real squad participants.

### Design Goals

1. **Functional Equivalence**: Maintain all existing squad features (create, join, live location sharing, member visibility, metadata sync)
2. **Real-Time Performance**: Achieve sub-100ms latency for location updates within a squad
3. **Reliability**: Implement robust reconnection logic and error handling for mobile network conditions
4. **Simplicity**: Use straightforward message protocols and state management suitable for a 2-3 person team
5. **Zero Cost**: Deploy on free-tier infrastructure (Railway, Render, Fly.io)
6. **Production Ready**: Remove all demo/test code and implement proper validation

### Key Requirements Addressed

This design addresses all 20 requirements from the requirements document:
- **R1-R2**: WebSocket Server implementation and message protocol
- **R3-R5**: Flutter client integration and connection lifecycle
- **R6-R9**: Squad operations (create, join, location updates, metadata sync)
- **R10**: Demo code removal
- **R11-R12**: Server technology stack and authentication
- **R13-R14**: Error handling and configuration
- **R15-R20**: Migration path, performance, validation, testing, and documentation

---

## Architecture

### System Components

The WebSocket-based squad system consists of four main components:

```mermaid
graph TB
    subgraph "Flutter App"
        A[Squad Service] --> B[WebSocket Client]
        B --> C[Connection Manager]
        A --> D[Location Service]
        A --> E[Auth Service]
    end
    
    subgraph "WebSocket Server"
        F[Connection Handler] --> G[Message Router]
        G --> H[Squad State Manager]
        H --> I[Database]
    end
    
    C -->|WSS Connection| F
    G -->|Broadcast| C
    
    style A fill:#e1f5ff
    style B fill:#e1f5ff
    style C fill:#e1f5ff
    style F fill:#ffe1e1
    style G fill:#ffe1e1
    style H fill:#ffe1e1
```

**Component Responsibilities:**

1. **Squad Service** (Flutter): Business logic layer managing squad state, member list, and coordination between services
2. **WebSocket Client** (Flutter): Low-level WebSocket communication, message serialization/deserialization
3. **Connection Manager** (Flutter): Connection lifecycle, reconnection logic, heartbeat monitoring
4. **Location Service** (Flutter): GPS position updates (existing component, unchanged)
5. **Auth Service** (Flutter): User authentication (existing component, unchanged)
6. **Connection Handler** (Server): Accept WebSocket connections, authenticate, maintain active connection pool
7. **Message Router** (Server): Parse incoming messages, route to appropriate handlers, broadcast to squad members
8. **Squad State Manager** (Server): In-memory squad state, member tracking, metadata persistence
9. **Database** (Server): Optional PostgreSQL/SQLite for squad metadata persistence

### Data Flow

#### Location Update Flow

```mermaid
sequenceDiagram
    participant LS as Location Service
    participant SS as Squad Service
    participant WSC as WebSocket Client
    participant Server as WebSocket Server
    participant Members as Other Squad Members
    
    LS->>SS: Position changed (lat, lng)
    SS->>SS: Check throttle (5s interval)
    SS->>WSC: Send location_update message
    WSC->>Server: JSON over WebSocket
    Server->>Server: Validate & parse message
    Server->>Server: Route to squad by code
    Server->>Members: Broadcast to squad connections
    Members->>Members: Update member state
    Members->>Members: Render on map
```

**Validates: Requirements 1.1-1.10, 3.1-3.10, 5.1-5.10**

#### Squad Creation Flow

```mermaid
sequenceDiagram
    participant User
    participant SS as Squad Service
    participant WSC as WebSocket Client
    participant Server as WebSocket Server
    participant DB as Database
    
    User->>SS: createSquad(name, meetup)
    SS->>SS: Generate PUJA#### code
    SS->>WSC: Connect to WebSocket Server
    WSC->>Server: Handshake with auth token
    Server->>Server: Authenticate token
    Server->>DB: Create squad entry
    SS->>WSC: Send join_squad (is_host: true)
    Server->>Server: Register member in squad
    Server->>WSC: Acknowledge squad creation
    SS->>WSC: Send squad_meta_update
    Server->>DB: Persist metadata
    Server->>WSC: Confirm metadata saved
    SS->>SS: Persist locally (SharedPreferences)
    SS->>User: Squad ready, show invite code
```

**Validates: Requirements 6.1-6.10**

#### Squad Joining Flow

```mermaid
sequenceDiagram
    participant User
    participant SS as Squad Service
    participant WSC as WebSocket Client
    participant Server as WebSocket Server
    participant Host as Squad Host & Members
    
    User->>SS: joinSquad(code)
    SS->>SS: Validate code format PUJA####
    SS->>WSC: Connect to WebSocket Server
    WSC->>Server: Handshake with auth token
    Server->>Server: Authenticate token
    SS->>WSC: Send join_squad (is_host: false)
    Server->>Server: Verify squad exists
    alt Squad exists
        Server->>Server: Add member to squad
        Server->>Host: Broadcast member_joined
        Server->>WSC: Send squad metadata
        Server->>WSC: Send current member list
        SS->>SS: Populate members, set metadata
        SS->>SS: Persist locally
        SS->>User: Joined successfully
    else Squad not found
        Server->>WSC: Error SQUAD_NOT_FOUND
        SS->>User: Squad code not found
    end
```

**Validates: Requirements 7.1-7.10**

---

## Components and Interfaces

### WebSocket Client (Flutter)

**File**: `app/lib/services/websocket_client.dart`

The WebSocket Client is a thin communication layer responsible for establishing and maintaining the WebSocket connection, serializing/deserializing messages, and exposing message streams.

#### Interface

```dart
class WebSocketClient {
  /// Stream of connection states
  Stream<ConnectionState> get connectionState;
  
  /// Current connection status
  ConnectionState get currentState;
  
  /// Connect to WebSocket server
  Future<void> connect(String authToken);
  
  /// Send a message
  Future<void> sendMessage(Map<String, dynamic> message);
  
  /// Close connection
  Future<void> close();
  
  /// Stream of incoming messages
  Stream<Map<String, dynamic>> get messages;
}

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}
```

#### Implementation Details

**Dependencies**:
- `web_socket_channel` package for WebSocket communication
- `dart:convert` for JSON encoding/decoding
- Environment variable `WEBSOCKET_SERVER_URL` for server endpoint

**Message Handling**:
```dart
Future<void> sendMessage(Map<String, dynamic> message) async {
  if (_channel == null || currentState != ConnectionState.connected) {
    throw WebSocketException('Not connected');
  }
  
  // Add timestamp to all outgoing messages
  message['timestamp'] = DateTime.now().millisecondsSinceEpoch;
  
  final json = jsonEncode(message);
  _channel!.sink.add(json);
}
```

**Connection Establishment**:
```dart
Future<void> connect(String authToken) async {
  final serverUrl = const String.fromEnvironment(
    'WEBSOCKET_SERVER_URL',
    defaultValue: 'ws://localhost:8080',
  );
  
  final uri = Uri.parse('$serverUrl/squad?token=$authToken');
  
  try {
    _stateController.add(ConnectionState.connecting);
    _channel = WebSocketChannel.connect(uri);
    _stateController.add(ConnectionState.connected);
    
    // Listen for incoming messages
    _channel!.stream.listen(
      _handleMessage,
      onError: _handleError,
      onDone: _handleDisconnect,
    );
  } catch (e) {
    _stateController.add(ConnectionState.error);
    rethrow;
  }
}
```

**Message Parsing** (with error handling):
```dart
void _handleMessage(dynamic data) {
  try {
    final json = jsonDecode(data as String) as Map<String, dynamic>;
    
    // Validate required fields
    if (!json.containsKey('type')) {
      debugPrint('[WebSocketClient] Message missing type field: $json');
      return;
    }
    
    if (!json.containsKey('timestamp')) {
      debugPrint('[WebSocketClient] Message missing timestamp field: $json');
      return;
    }
    
    _messageController.add(json);
  } catch (e) {
    debugPrint('[WebSocketClient] JSON parse error: $e, data: $data');
  }
}
```

**Validates: Requirements 3.1-3.10, 17.1-17.10**

---

### Connection Manager (Flutter)

**File**: `app/lib/services/connection_manager.dart`

The Connection Manager handles connection lifecycle, implements reconnection logic with exponential backoff, manages heartbeat monitoring, and buffers unsent messages during disconnections.

#### Reconnection Strategy

```dart
class ConnectionManager {
  static const _initialBackoff = Duration(seconds: 1);
  static const _maxBackoff = Duration(seconds: 30);
  static const _maxConsecutiveFailures = 5;
  static const _heartbeatInterval = Duration(seconds: 15);
  static const _heartbeatTimeout = Duration(seconds: 5);
  static const _maxBufferedMessages = 10;
  
  int _consecutiveFailures = 0;
  Duration _currentBackoff = _initialBackoff;
  final List<Map<String, dynamic>> _messageBuffer = [];
  Timer? _heartbeatTimer;
  Timer? _heartbeatTimeoutTimer;
  
  Future<void> _attemptReconnection() async {
    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      _notifyUserMaxRetriesReached();
      return;
    }
    
    await Future.delayed(_currentBackoff);
    
    try {
      await _websocketClient.connect(_authToken);
      _consecutiveFailures = 0;
      _currentBackoff = _initialBackoff;
      await _resendJoinSquad();
      await _flushMessageBuffer();
      _startHeartbeat();
    } catch (e) {
      _consecutiveFailures++;
      _currentBackoff = Duration(
        seconds: min(_currentBackoff.inSeconds * 2, _maxBackoff.inSeconds),
      );
      _attemptReconnection();
    }
  }
}
```

#### Heartbeat Monitoring

```dart
void _startHeartbeat() {
  _heartbeatTimer?.cancel();
  _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
    _sendHeartbeat();
    
    // Start timeout timer
    _heartbeatTimeoutTimer?.cancel();
    _heartbeatTimeoutTimer = Timer(_heartbeatTimeout, () {
      debugPrint('[ConnectionManager] Heartbeat timeout, reconnecting');
      _handleConnectionDead();
    });
  });
}

Future<void> _sendHeartbeat() async {
  await _websocketClient.sendMessage({'type': 'heartbeat'});
}

void _handleHeartbeatResponse() {
  _heartbeatTimeoutTimer?.cancel();
}

void _handleConnectionDead() {
  _websocketClient.close();
  _attemptReconnection();
}
```

#### Message Buffering

```dart
Future<void> bufferMessage(Map<String, dynamic> message) async {
  if (_messageBuffer.length >= _maxBufferedMessages) {
    _messageBuffer.removeAt(0); // Drop oldest message
  }
  _messageBuffer.add(message);
}

Future<void> _flushMessageBuffer() async {
  final messages = List<Map<String, dynamic>>.from(_messageBuffer);
  _messageBuffer.clear();
  
  for (final message in messages) {
    try {
      await _websocketClient.sendMessage(message);
    } catch (e) {
      debugPrint('[ConnectionManager] Failed to flush message: $e');
    }
  }
}
```

**Validates: Requirements 4.1-4.10**

---

### Squad Service Modifications

**File**: `app/lib/services/squad_service.dart`

The Squad Service requires significant modifications to replace Firebase RTDB calls with WebSocket communication.

#### Removed Methods

The following Firebase-specific methods will be **completely removed**:

```dart
// REMOVE: Firebase RTDB accessor
FirebaseDatabase? get _database { ... }

// REMOVE: Firebase availability check
bool get _isFirebaseAvailable { ... }

// REMOVE: Firebase data push methods
Future<void> _pushUserToCloud() async { ... }
Future<void> _pushMetaToCloud() async { ... }
void _listenToCloud() { ... }
```

#### New Dependencies

```dart
class SquadService extends ChangeNotifier {
  final WebSocketClient _wsClient;
  final ConnectionManager _connectionManager;
  
  // Remove Firebase imports completely
  // Add WebSocket-specific state
  bool _isWebSocketConnected = false;
  DateTime? _lastLocationUpdate;
  static const _minUpdateInterval = Duration(seconds: 5);
  static const _batteryMinUpdateInterval = Duration(seconds: 15);
}
```

#### Modified: createSquad()

```dart
Future<void> createSquad(String name, String meetup, [LatLng? meetupCoords]) async {
  _lastError = null;
  await _ensureUser();

  final suffix = List.generate(4, (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)]).join();
  final code = 'PUJA$suffix';
  _squadCode = code;
  _squadName = name.trim().isEmpty ? 'My Puja Squad' : name.trim();
  _meetupPointName = meetup.trim().isEmpty ? 'Main Entrance Gate' : meetup.trim();

  // Get real GPS coordinates
  final currentPos = LocationService.instance.currentPositionSync;
  final realLat = currentPos?.latitude ?? LocationService.instance.currentCoordinates.latitude;
  final realLng = currentPos?.longitude ?? LocationService.instance.currentCoordinates.longitude;
  _meetupPointCoords = meetupCoords ?? LatLng(realLat, realLng);

  // Initialize with ONLY local user (ZERO companions)
  _initMembers(isHost: true, userLat: realLat, userLng: realLng);
  await _persistState();

  // Establish WebSocket connection
  try {
    final authToken = AuthService.instance.currentUserModel?.uid ?? 'guest';
    await _connectionManager.connect(authToken);
    
    // Send join_squad message as host
    await _wsClient.sendMessage({
      'type': 'join_squad',
      'squad_code': code,
      'member_id': _members[0].id,
      'member_name': _members[0].name,
      'is_host': true,
      'initial_latitude': realLat,
      'initial_longitude': realLng,
    });
    
    // Send squad metadata
    await _wsClient.sendMessage({
      'type': 'squad_meta_update',
      'squad_code': code,
      'squad_name': _squadName,
      'meetup_point_name': _meetupPointName,
      'meetup_latitude': _meetupPointCoords.latitude,
      'meetup_longitude': _meetupPointCoords.longitude,
    });
    
    _listenToWebSocketMessages();
    notifyListeners();
  } catch (e) {
    _lastError = 'Failed to create squad. Check your internet connection.';
    debugPrint('[SquadService] createSquad error: $e');
    rethrow;
  }
}
```

#### Modified: updateUserLocation()

```dart
void updateUserLocation(double lat, double lng) {
  if (!_isSharingLocation || !_isWebSocketConnected) return;
  
  // Throttle updates based on battery saver mode
  final minInterval = _batterySaver ? _batteryMinUpdateInterval : _minUpdateInterval;
  final now = DateTime.now();
  
  if (_lastLocationUpdate != null) {
    final elapsed = now.difference(_lastLocationUpdate!);
    if (elapsed < minInterval) {
      // Check if distance moved is significant (> 10 meters)
      final idx = _members.indexWhere((m) => m.isUser);
      if (idx != -1) {
        final oldMember = _members[idx];
        final distance = haversineMeters(
          oldMember.latitude,
          oldMember.longitude,
          lat,
          lng,
        );
        
        // Skip update if moved less than 10m and less than 30s elapsed
        if (distance < 10 && elapsed < const Duration(seconds: 30)) {
          return;
        }
      }
    }
  }
  
  final idx = _members.indexWhere((m) => m.isUser);
  if (idx != -1) {
    final batteryLevel = _members[idx].batteryLevel; // Get from platform
    
    _members[idx] = _members[idx].copyWith(
      latitude: lat,
      longitude: lng,
      lastSeen: now,
      batteryLevel: batteryLevel,
    );
    
    _lastLocationUpdate = now;
    
    // Send location update via WebSocket
    _wsClient.sendMessage({
      'type': 'location_update',
      'squad_code': _squadCode,
      'member_id': _members[idx].id,
      'latitude': lat,
      'longitude': lng,
      'status': _members[idx].status,
      'battery_level': batteryLevel,
      'photo_url': _members[idx].photoUrl,
    });
    
    notifyListeners();
  }
}
```

#### New: _listenToWebSocketMessages()

```dart
void _listenToWebSocketMessages() {
  _wsClient.messages.listen((message) {
    final type = message['type'] as String?;
    
    switch (type) {
      case 'location_update':
        _handleLocationUpdate(message);
        break;
      case 'squad_meta_update':
        _handleMetadataUpdate(message);
        break;
      case 'member_left':
        _handleMemberLeft(message);
        break;
      case 'member_joined':
        _handleMemberJoined(message);
        break;
      case 'error':
        _handleError(message);
        break;
    }
  });
}

void _handleLocationUpdate(Map<String, dynamic> message) {
  try {
    final memberId = message['member_id'] as String;
    
    // Ignore updates for local user
    if (memberId == (AuthService.instance.currentUserModel?.uid ?? 'user_self')) {
      return;
    }
    
    final lat = (message['latitude'] as num).toDouble();
    final lng = (message['longitude'] as num).toDouble();
    final status = message['status'] as String? ?? 'Active';
    final batteryLevel = (message['battery_level'] as num?)?.toInt() ?? 85;
    final photoUrl = message['photo_url'] as String?;
    
    // Validate coordinates
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      debugPrint('[SquadService] Invalid coordinates: ($lat, $lng)');
      return;
    }
    
    final idx = _members.indexWhere((m) => m.id == memberId);
    if (idx != -1) {
      // Update existing member
      _members[idx] = _members[idx].copyWith(
        latitude: lat,
        longitude: lng,
        status: status,
        batteryLevel: batteryLevel,
        lastSeen: DateTime.now(),
      );
    } else {
      // Create new member (companion)
      _members.add(SquadMember(
        id: memberId,
        name: message['member_name'] as String? ?? 'Squad Member',
        latitude: lat,
        longitude: lng,
        status: status,
        batteryLevel: batteryLevel,
        photoUrl: photoUrl,
        isHost: false,
        isUser: false,
        lastSeen: DateTime.now(),
      ));
    }
    
    notifyListeners();
  } catch (e) {
    debugPrint('[SquadService] Error handling location update: $e');
  }
}
```

#### Removed: addDemoCompanions()

**This method MUST be completely removed**:

```dart
// REMOVE COMPLETELY - No demo companions in production
void addDemoCompanions() { ... }
```

**Validates: Requirements 6.1-6.10, 8.1-8.10, 10.1-10.10, 15.1-15.10**

---

### Group Screen Modifications

**File**: `app/lib/screens/group_screen.dart`

#### Removed UI Elements

Remove all demo companion functionality:

```dart
// REMOVE: Demo companion button from empty state
FilledButton.tonalIcon(
  icon: const Icon(Icons.group_add, size: 16),
  label: const Text('Add Demo Companions'),
  onPressed: () {
    HapticFeedback.lightImpact();
    squadService.addDemoCompanions();
    // ...
  },
),

// REMOVE: Demo companion button from at-a-glance section
FilledButton.tonal(
  // ...
  onPressed: () {
    HapticFeedback.lightImpact();
    squadService.addDemoCompanions();
    // ...
  },
  child: const Text('Add Demo', style: TextStyle(fontSize: 12)),
),
```

#### Modified Empty State

```dart
if (squadService.companionMembers.isEmpty)
  Card(
    // ... existing styling ...
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PujaColors.festivalGold.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.group_add_outlined,
              size: 36,
              color: PujaColors.festivalGold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No Companions Yet',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your squad starts with only you as host. Share squad code "${squadService.squadCode}" with friends so they can join with their real devices.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Invite Friends'),
              onPressed: () {
                HapticFeedback.lightImpact();
                _shareInvite(context, squadService);
              },
            ),
          ),
        ],
      ),
    ),
  )
```

#### Added: Connection Status Indicator

```dart
// Add connection status indicator to AppBar
AppBar(
  title: Row(
    children: [
      const Text('Hopping Squad (Groups)'),
      const SizedBox(width: 8),
      Consumer<SquadService>(
        builder: (ctx, squad, _) {
          final state = squad.connectionState;
          Color dotColor;
          switch (state) {
            case ConnectionState.connected:
              dotColor = Colors.green;
              break;
            case ConnectionState.reconnecting:
              dotColor = Colors.yellow;
              break;
            case ConnectionState.error:
              dotColor = Colors.red;
              break;
            default:
              dotColor = Colors.grey;
          }
          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          );
        },
      ),
    ],
  ),
  // ... rest of AppBar
)
```

**Validates: Requirements 10.1-10.10, 13.1-13.10**

---

## WebSocket Server Design

### Technology Stack

**Language**: Node.js with TypeScript
**WebSocket Library**: `ws` (npm package)
**Database**: PostgreSQL (optional, for squad metadata persistence)
**Deployment**: Railway, Render, or Fly.io free tier

**Rationale**:
- Node.js: Excellent WebSocket support, minimal resource usage, strong ecosystem
- TypeScript: Type safety prevents message protocol errors
- `ws` library: Battle-tested, minimal overhead, supports 1000+ concurrent connections
- PostgreSQL: Free tier on Railway/Render, good for structured squad metadata
- Can run as single process without Redis/message queues for MVP

**Alternative**: Python with `websockets` library (similar characteristics)

**Validates: Requirements 11.1-11.10**

### Server Architecture

```mermaid
graph TB
    subgraph "WebSocket Server Process"
        A[HTTP Server<br>/health endpoint] --> B[WebSocket Server<br>Port 8080]
        B --> C[Connection Handler]
        C --> D{Authenticate}
        D -->|Valid| E[Connection Pool]
        D -->|Invalid| F[Close 4001]
        E --> G[Message Handler]
        G --> H{Parse & Validate}
        H -->|Valid| I[Route by Type]
        H -->|Invalid| J[Log & Drop]
        I --> K[Squad State Manager]
        K --> L[(In-Memory<br>Squad Map)]
        K --> M[(PostgreSQL<br>Optional)]
        K --> N[Broadcast Engine]
        N --> E
    end
    
    style B fill:#ffe1e1
    style L fill:#e1ffe1
    style M fill:#e1ffe1
```

### Squad State Manager

**In-Memory Data Structure**:

```typescript
interface MemberConnection {
  userId: string;
  userName: string;
  photoUrl?: string;
  isHost: boolean;
  lastSeen: number;
  websocket: WebSocket;
}

interface SquadMetadata {
  code: string;
  name: string;
  meetupPointName: string;
  meetupLat: number;
  meetupLng: number;
  createdAt: number;
  updatedAt: number;
}

interface SquadState {
  metadata: SquadMetadata;
  members: Map<string, MemberConnection>;
}

// Global state
const squads = new Map<string, SquadState>();
```

### Message Handler Implementation

```typescript
function handleMessage(ws: WebSocket, userId: string, data: string): void {
  let message: any;
  
  try {
    message = JSON.parse(data);
  } catch (e) {
    console.error('[Server] JSON parse error:', e);
    return; // Drop malformed message silently
  }
  
  // Validate required fields
  if (!message.type || !message.timestamp) {
    console.error('[Server] Missing required fields:', message);
    return;
  }
  
  // Route by message type
  switch (message.type) {
    case 'join_squad':
      handleJoinSquad(ws, userId, message);
      break;
    case 'location_update':
      handleLocationUpdate(ws, userId, message);
      break;
    case 'squad_meta_update':
      handleMetadataUpdate(ws, userId, message);
      break;
    case 'heartbeat':
      handleHeartbeat(ws);
      break;
    default:
      console.warn('[Server] Unknown message type:', message.type);
  }
}
```

### Join Squad Handler

```typescript
function handleJoinSquad(
  ws: WebSocket,
  userId: string,
  message: JoinSquadMessage
): void {
  const { squad_code, member_name, is_host, initial_latitude, initial_longitude } = message;
  
  // Validate squad code format
  if (!squad_code.match(/^PUJA[A-Z0-9]{4}$/)) {
    sendError(ws, 'INVALID_CODE', 'Squad code must be in format PUJA####');
    return;
  }
  
  // Validate coordinates
  if (initial_latitude < -90 || initial_latitude > 90 ||
      initial_longitude < -180 || initial_longitude > 180) {
    sendError(ws, 'INVALID_COORDS', 'Invalid coordinates');
    return;
  }
  
  let squad = squads.get(squad_code);
  
  if (is_host) {
    // Create new squad
    if (squad) {
      sendError(ws, 'SQUAD_EXISTS', 'Squad code already exists');
      return;
    }
    
    squad = {
      metadata: {
        code: squad_code,
        name: 'New Squad',
        meetupPointName: 'Main Entrance',
        meetupLat: initial_latitude,
        meetupLng: initial_longitude,
        createdAt: Date.now(),
        updatedAt: Date.now(),
      },
      members: new Map(),
    };
    
    squads.set(squad_code, squad);
    console.log(`[Server] Created squad ${squad_code}`);
  } else {
    // Join existing squad
    if (!squad) {
      sendError(ws, 'SQUAD_NOT_FOUND', 'Squad code not found');
      return;
    }
  }
  
  // Add member to squad
  squad.members.set(userId, {
    userId,
    userName: member_name,
    photoUrl: message.photo_url,
    isHost: is_host,
    lastSeen: Date.now(),
    websocket: ws,
  });
  
  // Send acknowledgment with metadata
  ws.send(JSON.stringify({
    type: 'squad_joined',
    squad_code,
    metadata: squad.metadata,
    server_timestamp: Date.now(),
  }));
  
  // Broadcast member_joined to other members
  broadcastToSquad(squad_code, userId, {
    type: 'member_joined',
    squad_code,
    member_id: userId,
    member_name,
    photo_url: message.photo_url,
    latitude: initial_latitude,
    longitude: initial_longitude,
    server_timestamp: Date.now(),
  });
  
  // Send current member list to new member
  const memberList = Array.from(squad.members.values()).map(m => ({
    member_id: m.userId,
    member_name: m.userName,
    photo_url: m.photoUrl,
    is_host: m.isHost,
  }));
  
  ws.send(JSON.stringify({
    type: 'member_list',
    squad_code,
    members: memberList,
    server_timestamp: Date.now(),
  }));
}
```

### Location Update Handler

```typescript
const rateLimiter = new Map<string, number[]>();

function handleLocationUpdate(
  ws: WebSocket,
  userId: string,
  message: LocationUpdateMessage
): void {
  const { squad_code, latitude, longitude, status, battery_level, photo_url } = message;
  
  // Rate limiting: 10 updates per second per client
  const now = Date.now();
  const userRequests = rateLimiter.get(userId) || [];
  const recentRequests = userRequests.filter(t => now - t < 1000);
  
  if (recentRequests.length >= 10) {
    sendError(ws, 'RATE_LIMIT', 'Too many updates. Please wait a moment.');
    return;
  }
  
  recentRequests.push(now);
  rateLimiter.set(userId, recentRequests);
  
  // Validate coordinates
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    console.error('[Server] Invalid coordinates:', { latitude, longitude });
    return; // Drop silently
  }
  
  const squad = squads.get(squad_code);
  if (!squad) {
    sendError(ws, 'SQUAD_NOT_FOUND', 'Squad not found');
    return;
  }
  
  // Update member's last seen
  const member = squad.members.get(userId);
  if (member) {
    member.lastSeen = now;
  }
  
  // Broadcast to all squad members
  broadcastToSquad(squad_code, null, {
    type: 'location_update',
    squad_code,
    member_id: userId,
    latitude,
    longitude,
    status,
    battery_level,
    photo_url,
    server_timestamp: now,
  });
}
```

### Broadcast Engine

```typescript
function broadcastToSquad(
  squadCode: string,
  excludeUserId: string | null,
  message: any
): void {
  const squad = squads.get(squadCode);
  if (!squad) return;
  
  const json = JSON.stringify(message);
  let broadcastCount = 0;
  
  for (const [userId, member] of squad.members) {
    if (excludeUserId && userId === excludeUserId) continue;
    
    try {
      if (member.websocket.readyState === WebSocket.OPEN) {
        member.websocket.send(json);
        broadcastCount++;
      }
    } catch (e) {
      console.error(`[Server] Broadcast error to ${userId}:`, e);
    }
  }
  
  console.log(`[Server] Broadcasted to ${broadcastCount} members in squad ${squadCode}`);
}
```

### Connection Cleanup

```typescript
function handleDisconnect(ws: WebSocket, userId: string): void {
  // Find and remove member from all squads
  for (const [squadCode, squad] of squads) {
    if (squad.members.has(userId)) {
      squad.members.delete(userId);
      
      // Broadcast member_left
      broadcastToSquad(squadCode, null, {
        type: 'member_left',
        squad_code: squadCode,
        member_id: userId,
        server_timestamp: Date.now(),
      });
      
      console.log(`[Server] User ${userId} left squad ${squadCode}`);
      
      // Clean up empty squads after 5 minutes
      if (squad.members.size === 0) {
        setTimeout(() => {
          if (squads.get(squadCode)?.members.size === 0) {
            squads.delete(squadCode);
            console.log(`[Server] Cleaned up empty squad ${squadCode}`);
          }
        }, 5 * 60 * 1000);
      }
    }
  }
}
```

**Validates: Requirements 1.1-1.10, 19.1-19.10**

---

## Message Protocol

### Protocol Specification

All messages use JSON format with the following common fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Message category identifier |
| `timestamp` | number | Yes | Unix milliseconds (client time) |
| `server_timestamp` | number | Server messages only | Unix milliseconds (server time) |

### Message Types

#### 1. join_squad

**Direction**: Client → Server

**Purpose**: Create a new squad (if host) or join an existing squad

```json
{
  "type": "join_squad",
  "timestamp": 1729234567890,
  "squad_code": "PUJAX4K9",
  "member_id": "user_abc123",
  "member_name": "Arnab (You)",
  "is_host": true,
  "initial_latitude": 22.5958,
  "initial_longitude": 88.3725,
  "photo_url": "https://example.com/photo.jpg"
}
```

**Field Validation**:
- `squad_code`: Matches regex `/^PUJA[A-Z0-9]{4}$/`
- `member_id`: Non-empty string, minimum 3 characters
- `member_name`: Non-empty string
- `is_host`: Boolean
- `initial_latitude`: Number in range [-90, 90]
- `initial_longitude`: Number in range [-180, 180]
- `photo_url`: Optional string (URL)

**Server Response** (success):
```json
{
  "type": "squad_joined",
  "timestamp": 1729234567900,
  "server_timestamp": 1729234567895,
  "squad_code": "PUJAX4K9",
  "metadata": {
    "name": "Bagbazar Hoppers",
    "meetup_point_name": "Main Gate",
    "meetup_latitude": 22.5958,
    "meetup_longitude": 88.3725
  }
}
```

**Server Response** (error):
```json
{
  "type": "error",
  "timestamp": 1729234567900,
  "server_timestamp": 1729234567895,
  "error_code": "SQUAD_NOT_FOUND",
  "error_message": "Squad code not found. Please verify and try again."
}
```

---

#### 2. location_update

**Direction**: Client → Server → Other Clients

**Purpose**: Broadcast real-time GPS position to squad members

```json
{
  "type": "location_update",
  "timestamp": 1729234570000,
  "squad_code": "PUJAX4K9",
  "member_id": "user_abc123",
  "latitude": 22.5962,
  "longitude": 88.3728,
  "status": "Active • Pandal Hopping",
  "battery_level": 87,
  "photo_url": "https://example.com/photo.jpg"
}
```

**Field Validation**:
- `latitude`: Number in range [-90, 90]
- `longitude`: Number in range [-180, 180]
- `status`: String, max 50 characters
- `battery_level`: Integer in range [0, 100]
- `photo_url`: Optional string (URL)

**Server Broadcast** (to all squad members except sender):
```json
{
  "type": "location_update",
  "timestamp": 1729234570000,
  "server_timestamp": 1729234570005,
  "squad_code": "PUJAX4K9",
  "member_id": "user_abc123",
  "latitude": 22.5962,
  "longitude": 88.3728,
  "status": "Active • Pandal Hopping",
  "battery_level": 87,
  "photo_url": "https://example.com/photo.jpg"
}
```

---

#### 3. squad_meta_update

**Direction**: Client → Server → All Clients

**Purpose**: Update squad name, meetup point name, or meetup coordinates

```json
{
  "type": "squad_meta_update",
  "timestamp": 1729234575000,
  "squad_code": "PUJAX4K9",
  "squad_name": "Bagbazar Pandal Hoppers",
  "meetup_point_name": "Under Gariahat Flyover",
  "meetup_latitude": 22.5975,
  "meetup_longitude": 88.3742
}
```

**Field Validation**:
- `squad_name`: Optional string, max 100 characters
- `meetup_point_name`: Optional string, max 100 characters
- `meetup_latitude`: Optional number in range [-90, 90]
- `meetup_longitude`: Optional number in range [-180, 180]

**Server Broadcast** (to all squad members):
```json
{
  "type": "squad_meta_update",
  "timestamp": 1729234575000,
  "server_timestamp": 1729234575003,
  "squad_code": "PUJAX4K9",
  "squad_name": "Bagbazar Pandal Hoppers",
  "meetup_point_name": "Under Gariahat Flyover",
  "meetup_latitude": 22.5975,
  "meetup_longitude": 88.3742
}
```

---

#### 4. member_left

**Direction**: Server → All Clients

**Purpose**: Notify squad members when another member disconnects

```json
{
  "type": "member_left",
  "timestamp": 1729234580000,
  "server_timestamp": 1729234580001,
  "squad_code": "PUJAX4K9",
  "member_id": "user_xyz789"
}
```

---

#### 5. member_joined

**Direction**: Server → All Clients

**Purpose**: Notify existing members when a new member joins

```json
{
  "type": "member_joined",
  "timestamp": 1729234585000,
  "server_timestamp": 1729234585002,
  "squad_code": "PUJAX4K9",
  "member_id": "user_new456",
  "member_name": "Priya",
  "photo_url": "https://example.com/priya.jpg",
  "latitude": 22.5965,
  "longitude": 88.3730
}
```

---

#### 6. heartbeat

**Direction**: Client → Server

**Purpose**: Detect stale connections

```json
{
  "type": "heartbeat",
  "timestamp": 1729234590000
}
```

**Server Response**:
```json
{
  "type": "heartbeat_ack",
  "timestamp": 1729234590000,
  "server_timestamp": 1729234590001
}
```

---

#### 7. error

**Direction**: Server → Client

**Purpose**: Communicate validation errors or operational failures

```json
{
  "type": "error",
  "timestamp": 1729234595000,
  "server_timestamp": 1729234595002,
  "error_code": "RATE_LIMIT",
  "error_message": "Too many updates. Please wait a moment."
}
```

**Error Codes**:
- `INVALID_CODE`: Squad code format invalid
- `SQUAD_NOT_FOUND`: Attempted to join non-existent squad
- `SQUAD_EXISTS`: Attempted to create duplicate squad code
- `INVALID_COORDS`: Coordinates out of valid range
- `RATE_LIMIT`: Exceeded 10 updates per second
- `AUTH_FAILED`: Authentication token invalid
- `INVALID_MESSAGE`: Message parsing or validation failed

**Validates: Requirements 2.1-2.10**

---

## Data Models

### Squad Member Model (Flutter)

**File**: `app/lib/models/squad_member.dart`

**No changes required** - existing model already supports WebSocket data.

```dart
class SquadMember {
  const SquadMember({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.lastSeen,
    this.photoUrl,
    this.isHost = false,
    this.isUser = false,
    this.batteryLevel = 90,
    this.avatarColorHex = 0xFFFFB300,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime lastSeen;
  final String? photoUrl;
  final bool isHost;
  final bool isUser;
  final int batteryLevel;
  final int avatarColorHex;

  // Existing methods: copyWith, toJson, fromJson, initials, avatarColor
}
```

### Connection State Model (Flutter)

**New File**: `app/lib/models/connection_state.dart`

```dart
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class ConnectionStatus {
  const ConnectionStatus({
    required this.state,
    this.errorMessage,
    this.lastConnectedAt,
    this.consecutiveFailures = 0,
  });

  final ConnectionState state;
  final String? errorMessage;
  final DateTime? lastConnectedAt;
  final int consecutiveFailures;

  bool get isConnected => state == ConnectionState.connected;
  bool get canRetry => consecutiveFailures < 5;

  ConnectionStatus copyWith({
    ConnectionState? state,
    String? errorMessage,
    DateTime? lastConnectedAt,
    int? consecutiveFailures,
  }) {
    return ConnectionStatus(
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
    );
  }
}
```

### Server Squad State (TypeScript)

```typescript
// server/src/models/squad.ts

interface SquadMetadata {
  code: string;
  name: string;
  meetupPointName: string;
  meetupLat: number;
  meetupLng: number;
  createdAt: number;
  updatedAt: number;
}

interface MemberConnection {
  userId: string;
  userName: string;
  photoUrl?: string;
  isHost: boolean;
  lastSeen: number;
  websocket: WebSocket;
}

interface SquadState {
  metadata: SquadMetadata;
  members: Map<string, MemberConnection>;
}

// Optional: Database persistence schema (PostgreSQL)
interface SquadRecord {
  id: string; // Primary key
  code: string; // Unique, indexed
  name: string;
  meetup_point_name: string;
  meetup_lat: number;
  meetup_lng: number;
  created_at: Date;
  updated_at: Date;
  last_active_at: Date;
}
```

---

## Error Handling

### Error Handling Strategy

```mermaid
graph TB
    A[Error Occurs] --> B{Error Type?}
    B -->|Network| C[Connection Manager]
    B -->|Parse/Validation| D[Drop & Log]
    B -->|Business Logic| E[Squad Service]
    B -->|User Action| F[UI Feedback]
    
    C --> G{Recoverable?}
    G -->|Yes| H[Exponential Backoff Retry]
    G -->|No| I[Notify User]
    
    H --> J{Max Retries?}
    J -->|Not Reached| K[Reconnect Attempt]
    J -->|Exceeded| I
    
    D --> L[Console Log]
    E --> M[Set lastError]
    M --> N[SnackBar Message]
    F --> N
    I --> N
    
    style C fill:#ffe1e1
    style D fill:#fff3cd
    style E fill:#e1f5ff
    style N fill:#d1ecf1
```

### Error Categories and Handling

| Error Category | Handling Strategy | User Feedback | Recovery |
|----------------|-------------------|---------------|----------|
| **Network Connection Failed** | Automatic reconnection with exponential backoff | "Connection lost. Reconnecting..." (yellow status dot) | Reconnect automatically |
| **WebSocket Closed** | Trigger reconnection immediately | "Connection lost. Reconnecting..." | Reconnect automatically |
| **Authentication Failed** | Close connection, do not retry | "Authentication failed. Please sign in again." | Manual sign-in |
| **Squad Not Found** | No retry, clear state | "Squad code not found. Please verify and try again." | User re-enters code |
| **Invalid Message** | Drop message, log error | None (silent) | Continue processing |
| **Rate Limit Exceeded** | Buffer message, delay send | "Too many updates. Please wait a moment." | Automatic after cooldown |
| **Max Retries Exceeded** | Stop reconnection | "Connection failed. Please check your internet and try again." | Manual retry via button |
| **Location Permission Denied** | Disable sharing | "Location access required to share position with squad." | User grants permission |

### Client Error Handling Implementation

```dart
// Error handling in WebSocket Client
void _handleError(Object error) {
  debugPrint('[WebSocketClient] Error: $error');
  _stateController.add(ConnectionState.error);
  _connectionManager.handleError(error);
}

// Error handling in Squad Service
void _handleError(Map<String, dynamic> message) {
  final errorCode = message['error_code'] as String?;
  final errorMessage = message['error_message'] as String?;
  
  switch (errorCode) {
    case 'SQUAD_NOT_FOUND':
      _lastError = 'Squad code not found. Please verify and try again.';
      leaveSquad(); // Clear invalid state
      break;
    case 'RATE_LIMIT':
      _lastError = 'Too many updates. Please wait a moment.';
      break;
    case 'AUTH_FAILED':
      _lastError = 'Authentication failed. Please sign in again.';
      _connectionManager.stopReconnection();
      break;
    default:
      _lastError = errorMessage ?? 'An error occurred. Please try again.';
  }
  
  notifyListeners();
}

// Automatic error clearing on success
Future<void> _clearErrorOnSuccess() async {
  if (_lastError != null) {
    _lastError = null;
    notifyListeners();
  }
}
```

### Server Error Response

```typescript
function sendError(
  ws: WebSocket,
  code: string,
  message: string
): void {
  ws.send(JSON.stringify({
    type: 'error',
    timestamp: Date.now(),
    server_timestamp: Date.now(),
    error_code: code,
    error_message: message,
  }));
}

// Validation error example
function validateCoordinates(lat: number, lng: number): boolean {
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return false;
  }
  return true;
}
```

**Validates: Requirements 13.1-13.10, 17.1-17.10**

---

## Testing Strategy

### Unit Tests (Flutter)

**File**: `app/test/services/websocket_client_test.dart`

```dart
void main() {
  group('WebSocketClient', () {
    test('should parse valid location_update message', () {
      final client = WebSocketClient();
      final json = {
        'type': 'location_update',
        'timestamp': 1729234567890,
        'squad_code': 'PUJAX4K9',
        'member_id': 'user123',
        'latitude': 22.5958,
        'longitude': 88.3725,
        'status': 'Active',
        'battery_level': 85,
      };
      
      expect(() => client.parseMessage(jsonEncode(json)), returnsNormally);
    });
    
    test('should drop message with invalid JSON', () {
      final client = WebSocketClient();
      final invalid = '{invalid json}';
      
      // Should not throw, should log and drop
      expect(() => client.handleIncomingData(invalid), returnsNormally);
    });
    
    test('should validate latitude range', () {
      final json = {
        'type': 'location_update',
        'timestamp': 1729234567890,
        'latitude': 91.0, // Invalid
        'longitude': 88.3725,
      };
      
      expect(
        () => validateLocationUpdate(json),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```

### Integration Tests (Flutter)

**File**: `app/test/integration/websocket_squad_test.dart`

```dart
void main() {
  group('WebSocket Squad Integration', () {
    late MockWebSocketServer mockServer;
    late SquadService squadService;
    
    setUp(() async {
      mockServer = await MockWebSocketServer.start(port: 8080);
      squadService = await SquadService.create();
    });
    
    tearDown(() async {
      await mockServer.stop();
      await squadService.dispose();
    });
    
    test('should create squad and establish connection', () async {
      await squadService.createSquad('Test Squad', 'Main Gate');
      
      await expectLater(
        squadService.connectionState,
        emits(ConnectionState.connected),
      );
      
      expect(squadService.squadCode, matches(RegExp(r'^PUJA[A-Z0-9]{4}$')));
      expect(squadService.companionMembers, isEmpty);
    });
    
    test('should receive location updates from companion', () async {
      await squadService.createSquad('Test Squad', 'Main Gate');
      
      // Simulate companion joining
      await mockServer.simulateJoin(
        squadCode: squadService.squadCode!,
        memberId: 'companion1',
        memberName: 'Test Companion',
      );
      
      // Simulate location update from companion
      await mockServer.simulateLocationUpdate(
        squadCode: squadService.squadCode!,
        memberId: 'companion1',
        lat: 22.5960,
        lng: 88.3728,
      );
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(squadService.companionMembers.length, 1);
      expect(squadService.companionMembers[0].latitude, 22.5960);
    });
  });
}
```

### Property-Based Tests

**File**: `app/test/property/message_protocol_test.dart`

```dart
import 'package:test/test.dart';
import 'package:fast_check/fast_check.dart';

void main() {
  group('Message Protocol Properties', () {
    test('Property: Round-trip serialization preserves data', () {
      property(
        'For any valid SquadMember, serializing to JSON then parsing back produces equivalent object',
        forAll(
          squadMemberArbitrary(),
          (SquadMember member) {
            final json = member.toJson();
            final parsed = SquadMember.fromJson(json);
            
            return member.id == parsed.id &&
                   member.name == parsed.name &&
                   (member.latitude - parsed.latitude).abs() < 0.000001 &&
                   (member.longitude - parsed.longitude).abs() < 0.000001 &&
                   member.status == parsed.status &&
                   member.batteryLevel == parsed.batteryLevel &&
                   member.isHost == parsed.isHost &&
                   member.isUser == parsed.isUser;
          },
        ),
      ).check(numRuns: 100);
    });
    
    test('Property: Coordinates validation rejects invalid ranges', () {
      property(
        'For any latitude outside [-90, 90], validation should fail',
        forAll(
          invalidLatitudeArbitrary(),
          (double lat) {
            return !validateLatitude(lat);
          },
        ),
      ).check(numRuns: 100);
    });
    
    test('Property: Message parsing handles malformed input gracefully', () {
      property(
        'For any string, message parser should not throw',
        forAll(
          stringArbitrary(),
          (String input) {
            try {
              parseMessage(input);
              return true;
            } catch (e) {
              return false; // Should not throw, should return null or log
            }
          },
        ),
      ).check(numRuns: 100);
    });
  });
}

// Arbitrary generators for property-based testing
Arbitrary<SquadMember> squadMemberArbitrary() {
  return combine4(
    stringArbitrary(minLength: 3, maxLength: 20),
    doubleArbitrary(min: -90, max: 90),
    doubleArbitrary(min: -180, max: 180),
    intArbitrary(min: 0, max: 100),
    (String name, double lat, double lng, int battery) {
      return SquadMember(
        id: 'member_${name.hashCode}',
        name: name,
        latitude: lat,
        longitude: lng,
        status: 'Active',
        batteryLevel: battery,
        lastSeen: DateTime.now(),
      );
    },
  );
}

Arbitrary<double> invalidLatitudeArbitrary() {
  return frequency([
    (1, doubleArbitrary(min: -1000, max: -90.01)),
    (1, doubleArbitrary(min: 90.01, max: 1000)),
  ]);
}
```

### Server Tests (Node.js)

**File**: `server/test/message-handler.test.ts`

```typescript
import { expect } from 'chai';
import { handleJoinSquad, handleLocationUpdate } from '../src/message-handler';
import { MockWebSocket } from './mocks/websocket';

describe('Message Handler', () => {
  describe('handleJoinSquad', () => {
    it('should create squad when is_host is true', async () => {
      const ws = new MockWebSocket();
      const message = {
        type: 'join_squad',
        timestamp: Date.now(),
        squad_code: 'PUJAX4K9',
        member_id: 'user123',
        member_name: 'Test User',
        is_host: true,
        initial_latitude: 22.5958,
        initial_longitude: 88.3725,
      };
      
      await handleJoinSquad(ws, 'user123', message);
      
      expect(ws.sentMessages).to.have.lengthOf(1);
      expect(ws.sentMessages[0].type).to.equal('squad_joined');
    });
    
    it('should reject invalid squad code format', async () => {
      const ws = new MockWebSocket();
      const message = {
        type: 'join_squad',
        timestamp: Date.now(),
        squad_code: 'INVALID',
        member_id: 'user123',
        member_name: 'Test User',
        is_host: false,
        initial_latitude: 22.5958,
        initial_longitude: 88.3725,
      };
      
      await handleJoinSquad(ws, 'user123', message);
      
      expect(ws.sentMessages[0].type).to.equal('error');
      expect(ws.sentMessages[0].error_code).to.equal('INVALID_CODE');
    });
  });
  
  describe('handleLocationUpdate', () => {
    it('should broadcast location to squad members', async () => {
      // Setup squad with 2 members
      const ws1 = new MockWebSocket();
      const ws2 = new MockWebSocket();
      
      await setupSquad('PUJAX4K9', [
        { ws: ws1, userId: 'user1' },
        { ws: ws2, userId: 'user2' },
      ]);
      
      const message = {
        type: 'location_update',
        timestamp: Date.now(),
        squad_code: 'PUJAX4K9',
        member_id: 'user1',
        latitude: 22.5960,
        longitude: 88.3728,
        status: 'Active',
        battery_level: 85,
      };
      
      await handleLocationUpdate(ws1, 'user1', message);
      
      // user2 should receive broadcast (user1 excluded)
      expect(ws2.sentMessages).to.have.lengthOf(1);
      expect(ws2.sentMessages[0].type).to.equal('location_update');
      expect(ws2.sentMessages[0].latitude).to.equal(22.5960);
    });
  });
});
```

**Validates: Requirements 18.1-18.10**

---

## Demo Code Removal Plan

### Methods to Remove

1. **SquadService.addDemoCompanions()**
   - **Location**: `app/lib/services/squad_service.dart`
   - **Action**: Delete entire method
   - **Impact**: No longer possible to create fake squad members

2. **Firebase RTDB Methods**
   - `_database` getter
   - `_isFirebaseAvailable` getter
   - `_pushUserToCloud()`
   - `_pushMetaToCloud()`
   - `_listenToCloud()`
   - **Action**: Delete all methods, remove Firebase RTDB imports
   - **Impact**: Complete removal of Firebase dependency

### UI Elements to Remove

1. **Group Screen Empty State Demo Button**
   - **Location**: `app/lib/screens/group_screen.dart`, line ~450
   - **Element**: `FilledButton.tonalIcon` with label "Add Demo Companions"
   - **Action**: Remove entire button and its onPressed handler
   - **Impact**: Empty state only shows "Invite Friends" option

2. **At-A-Glance Demo Button**
   - **Location**: `app/lib/screens/group_screen.dart`, line ~720
   - **Element**: `FilledButton.tonal` with label "Add Demo"
   - **Action**: Remove entire button
   - **Impact**: At-a-glance section only allows real companion interactions

### Verification Tests

**File**: `app/test/demo_removal_test.dart`

```dart
void main() {
  group('Demo Code Removal Verification', () {
    test('SquadService should not have addDemoCompanions method', () {
      final squadService = SquadService.instance;
      
      // This should fail to compile if method exists
      expect(
        () => (squadService as dynamic).addDemoCompanions(),
        throwsNoSuchMethodError,
      );
    });
    
    test('Newly created squad should have zero companions', () async {
      final squadService = await SquadService.create();
      await squadService.createSquad('Test Squad', 'Main Gate');
      
      expect(squadService.companionMembers, isEmpty);
      expect(squadService.members.length, 1); // Only local user
      expect(squadService.members[0].isUser, true);
    });
    
    test('Squad members should only increase via WebSocket join', () async {
      final squadService = await SquadService.create();
      await squadService.createSquad('Test Squad', 'Main Gate');
      
      final initialCount = squadService.members.length;
      
      // Simulate 5 seconds passing - no companions should appear
      await Future.delayed(const Duration(seconds: 5));
      
      expect(squadService.members.length, initialCount);
      expect(squadService.companionMembers, isEmpty);
    });
  });
}
```

**Validates: Requirements 10.1-10.10**

---

## Migration Strategy

### Phase 1: Setup (Week 1)

**Goal**: Establish WebSocket infrastructure without breaking existing Firebase functionality

**Tasks**:
1. Create WebSocket server repository (`puja-pandal-websocket-server`)
2. Implement basic WebSocket server with authentication
3. Create `WebSocketClient` class in Flutter app
4. Create `ConnectionManager` class
5. Add environment variable `WEBSOCKET_SERVER_URL` configuration
6. Deploy WebSocket server to Railway/Render free tier
7. Write unit tests for message parsing and serialization

**Validation**:
- WebSocket server accepts connections
- Flutter app can establish WebSocket connection
- Messages can be sent and received (test harness)
- No changes to existing Firebase code yet

### Phase 2: Parallel Implementation (Week 2)

**Goal**: Implement WebSocket-based squad operations alongside Firebase (feature flag)

**Tasks**:
1. Add feature flag `USE_WEBSOCKET` (default: false)
2. Implement WebSocket versions of:
   - `createSquad()`
   - `joinSquad()`
   - `updateUserLocation()`
   - `setMeetupPoint()`
3. Implement message handlers in `SquadService`:
   - `_handleLocationUpdate()`
   - `_handleMetadataUpdate()`
   - `_handleMemberJoined()`
   - `_handleMemberLeft()`
4. Add reconnection logic to `ConnectionManager`
5. Implement heartbeat monitoring

**Validation**:
- With `USE_WEBSOCKET=true`, squads work via WebSocket
- With `USE_WEBSOCKET=false`, squads work via Firebase (unchanged)
- Integration tests pass for both modes

### Phase 3: Demo Code Removal (Week 2)

**Goal**: Remove all demo/test code before production deployment

**Tasks**:
1. Delete `SquadService.addDemoCompanions()` method
2. Remove demo companion buttons from `GroupScreen`
3. Update empty state messaging
4. Verify `companionMembers` starts empty after squad creation
5. Add verification tests

**Validation**:
- No method named `addDemoCompanions` exists
- UI has no "Add Demo" buttons
- New squads have zero companions
- Tests confirm demo code removal

### Phase 4: Testing & Bug Fixes (Week 3)

**Goal**: Comprehensive testing with real devices and network conditions

**Tasks**:
1. Test squad creation and joining on 2+ physical devices
2. Test location updates with poor network conditions
3. Test reconnection logic (airplane mode toggle)
4. Test with multiple squads simultaneously
5. Load test server with 50+ concurrent connections
6. Fix identified bugs

**Validation**:
- Location updates appear within 2 seconds
- Reconnection succeeds after network recovery
- No crashes or data loss
- Server remains stable under load

### Phase 5: Firebase Removal (Week 3)

**Goal**: Complete migration to WebSocket-only

**Tasks**:
1. Set `USE_WEBSOCKET=true` as default (remove flag)
2. Delete all Firebase RTDB methods from `SquadService`
3. Remove Firebase Realtime Database dependency from `pubspec.yaml`
4. Remove Firebase RTDB initialization from `main.dart`
5. Update documentation (README, architecture doc)
6. Remove Firebase RTDB from Firebase Console (optional)

**Validation**:
- No Firebase RTDB imports remain
- App compiles and runs without Firebase RTDB
- All squad features work via WebSocket
- Regression tests pass

### Phase 6: Production Deployment (Week 4)

**Goal**: Ship WebSocket-based squad feature to users

**Tasks**:
1. Deploy WebSocket server to production URL (wss://)
2. Update `WEBSOCKET_SERVER_URL` in Flutter build configuration
3. Build release APK with production WebSocket URL
4. Submit to Play Store internal testing track
5. Monitor server logs and user feedback
6. Hotfix any critical issues

**Validation**:
- Production server is reachable and stable
- Users can create and join squads
- Location sharing works reliably
- No critical bugs reported

### Rollback Plan

If critical issues arise during Phase 5-6:

1. **Immediate**: Revert `WEBSOCKET_SERVER_URL` to point to old server
2. **Short-term**: Restore Firebase RTDB code from git history
3. **Medium-term**: Fix WebSocket issues in separate branch, re-test, re-deploy

**Validates: Requirements 15.1-15.10, 20.1-20.10**

---

## Configuration

### Flutter App Configuration

**Environment Variables** (via `--dart-define`):

```bash
# Development
flutter run --dart-define=WEBSOCKET_SERVER_URL=ws://localhost:8080

# Production
flutter build apk --release --dart-define=WEBSOCKET_SERVER_URL=wss://puja-squad.railway.app
```

**Reading in Code**:

```dart
class Config {
  static const websocketServerUrl = String.fromEnvironment(
    'WEBSOCKET_SERVER_URL',
    defaultValue: 'ws://localhost:8080',
  );
}
```

### WebSocket Server Configuration

**Environment Variables**:

```bash
# .env file
PORT=8080
DATABASE_URL=postgresql://user:pass@host:5432/puja_squads
AUTH_SECRET=your_secret_here
NODE_ENV=production
LOG_LEVEL=info
```

**Reading in Code**:

```typescript
import dotenv from 'dotenv';
dotenv.config();

const config = {
  port: parseInt(process.env.PORT || '8080'),
  databaseUrl: process.env.DATABASE_URL,
  authSecret: process.env.AUTH_SECRET,
  nodeEnv: process.env.NODE_ENV || 'development',
  logLevel: process.env.LOG_LEVEL || 'info',
};
```

### Deployment Configuration

**Railway.app** (recommended):

```toml
# railway.toml
[build]
builder = "NIXPACKS"

[deploy]
startCommand = "npm start"
healthcheckPath = "/health"
healthcheckTimeout = 30
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10
```

**Render.com**:

```yaml
# render.yaml
services:
  - type: web
    name: puja-squad-websocket
    env: node
    buildCommand: npm install && npm run build
    startCommand: npm start
    healthCheckPath: /health
    envVars:
      - key: PORT
        value: 8080
      - key: NODE_ENV
        value: production
```

**Validates: Requirements 14.1-14.10**

---

## Performance Considerations

### Latency Targets

| Operation | Target Latency | Measurement Point |
|-----------|----------------|-------------------|
| Location update broadcast | < 100ms | Server receives to members receive |
| Message parsing | < 10ms | JSON parse + validation |
| WebSocket reconnection | < 5s | Disconnect to reconnect success |
| Squad creation | < 500ms | Client call to server acknowledgment |

### Memory Management

**Flutter App**:
- Message buffer: Max 10 messages during disconnection
- Member list: Max 50 members per squad
- Connection state: Single active WebSocket per squad

**Server**:
- Target: < 512MB RAM for 100 concurrent connections
- In-memory squad state only (no message history)
- Stale squad cleanup after 7 days inactivity
- Rate limiting prevents memory exhaustion

### Optimization Techniques

**Throttling**:
```dart
// Squad Service location update throttling
static const _minUpdateInterval = Duration(seconds: 5);
static const _minSignificantDistance = 10.0; // meters

bool _shouldSendLocationUpdate(double newLat, double newLng) {
  if (_lastLocationUpdate != null) {
    final elapsed = DateTime.now().difference(_lastLocationUpdate!);
    if (elapsed < _minUpdateInterval) {
      final distance = haversineMeters(/* ... */);
      return distance >= _minSignificantDistance;
    }
  }
  return true;
}
```

**Batching** (not implemented in MVP, future optimization):
```typescript
// Server: Batch multiple location updates into single broadcast
const pendingUpdates = new Map<string, LocationUpdate[]>();

function queueUpdate(squadCode: string, update: LocationUpdate) {
  if (!pendingUpdates.has(squadCode)) {
    pendingUpdates.set(squadCode, []);
    setTimeout(() => flushUpdates(squadCode), 100); // 100ms batch window
  }
  pendingUpdates.get(squadCode)!.push(update);
}
```

**Debouncing**:
```dart
// Squad Service UI update debouncing
Timer? _notifyDebouncer;
static const _notifyDebounce = Duration(milliseconds: 100);

void _debouncedNotifyListeners() {
  _notifyDebouncer?.cancel();
  _notifyDebouncer = Timer(_notifyDebounce, notifyListeners);
}
```

**Validates: Requirements 16.1-16.10**

---

## Security Considerations

### Authentication

**Token Format**:
- Client sends Firebase Auth UID as token
- Server validates format (non-empty, min 8 characters)
- MVP: No signature verification (trust client-provided ID)
- Future: Verify Firebase ID token signature server-side

**Connection Security**:
- Production: WSS (WebSocket Secure) only
- Development: WS allowed for localhost testing
- Rate limiting: 5 connection attempts per minute per IP

### Input Validation

**All numeric inputs validated**:
- Latitude: [-90, 90]
- Longitude: [-180, 180]
- Battery level: [0, 100]
- Timestamp: Positive integer

**String inputs sanitized**:
- Squad code: Alphanumeric only, max 8 characters
- Member name: Max 100 characters
- Status: Max 50 characters

### Rate Limiting

```typescript
const rateLimiter = new Map<string, number[]>();
const maxRequestsPerSecond = 10;

function checkRateLimit(userId: string): boolean {
  const now = Date.now();
  const userRequests = rateLimiter.get(userId) || [];
  const recentRequests = userRequests.filter(t => now - t < 1000);
  
  if (recentRequests.length >= maxRequestsPerSecond) {
    return false; // Rate limit exceeded
  }
  
  recentRequests.push(now);
  rateLimiter.set(userId, recentRequests);
  return true;
}
```

**Validates: Requirements 12.1-12.10**

---

## Deployment

### Server Deployment (Railway)

1. **Create Railway Project**:
   ```bash
   # Install Railway CLI
   npm install -g @railway/cli
   
   # Login
   railway login
   
   # Create project
   railway init
   ```

2. **Deploy**:
   ```bash
   # Deploy from git repository
   railway up
   
   # Or connect GitHub repo for auto-deploy
   railway link
   ```

3. **Environment Variables**:
   ```bash
   railway variables set PORT=8080
   railway variables set NODE_ENV=production
   ```

4. **Custom Domain** (optional):
   - Railway provides `*.railway.app` domain
   - Update `WEBSOCKET_SERVER_URL` in Flutter app

### Flutter App Build

**Development**:
```bash
flutter run --dart-define=WEBSOCKET_SERVER_URL=ws://localhost:8080
```

**Production**:
```bash
flutter build apk --release \
  --dart-define=WEBSOCKET_SERVER_URL=wss://puja-squad.railway.app \
  --dart-define=ORS_API_KEY=your_ors_key
```

### Health Check Endpoint

```typescript
// server/src/health.ts
app.get('/health', (req, res) => {
  const uptime = process.uptime();
  const memoryUsage = process.memoryUsage();
  const activeSquads = squads.size;
  const totalConnections = Array.from(squads.values())
    .reduce((sum, squad) => sum + squad.members.size, 0);
  
  res.json({
    status: 'healthy',
    uptime,
    memoryUsageMB: Math.round(memoryUsage.heapUsed / 1024 / 1024),
    activeSquads,
    totalConnections,
    timestamp: Date.now(),
  });
});
```

**Validates: Requirements 11.6, 20.5-20.10**

---

## Documentation Updates

### README.md

Add new section:

```markdown
## WebSocket Squad Feature

The squad (group) feature uses a custom WebSocket server for real-time location sharing.

### Development Setup

1. Start WebSocket server:
   ```bash
   cd websocket-server
   npm install
   npm run dev
   ```

2. Run Flutter app with local WebSocket:
   ```bash
   cd app
   flutter run --dart-define=WEBSOCKET_SERVER_URL=ws://localhost:8080
   ```

### Production Build

```bash
flutter build apk --release \
  --dart-define=WEBSOCKET_SERVER_URL=wss://puja-squad.railway.app
```

### Message Protocol

See `docs/websocket-protocol.md` for complete message format specification.
```

### New File: docs/websocket-protocol.md

```markdown
# WebSocket Message Protocol

This document specifies the JSON message format for squad real-time communication.

## Common Fields

All messages include:
- `type`: Message category (string, required)
- `timestamp`: Unix milliseconds (number, required)
- `server_timestamp`: Server time, server messages only (number)

## Message Types

### join_squad
[Include full specification from design doc]

### location_update
[Include full specification from design doc]

[... etc for all message types]
```

**Validates: Requirements 20.1-20.10**

---

## Appendix: File Structure

### New Files

```
app/
├── lib/
│   ├── services/
│   │   ├── websocket_client.dart          [NEW]
│   │   ├── connection_manager.dart        [NEW]
│   │   └── squad_service.dart             [MODIFIED]
│   └── models/
│       └── connection_state.dart          [NEW]
└── test/
    ├── services/
    │   ├── websocket_client_test.dart     [NEW]
    │   └── connection_manager_test.dart   [NEW]
    ├── integration/
    │   └── websocket_squad_test.dart      [NEW]
    ├── property/
    │   └── message_protocol_test.dart     [NEW]
    └── demo_removal_test.dart             [NEW]

websocket-server/                          [NEW REPOSITORY]
├── src/
│   ├── index.ts
│   ├── connection-handler.ts
│   ├── message-handler.ts
│   ├── squad-state.ts
│   └── models/
│       └── squad.ts
├── test/
│   └── message-handler.test.ts
├── package.json
├── tsconfig.json
└── railway.toml

docs/
└── websocket-protocol.md                  [NEW]
```

### Modified Files

```
app/
├── lib/
│   ├── services/
│   │   └── squad_service.dart
│   └── screens/
│       └── group_screen.dart
├── pubspec.yaml                           [Add web_socket_channel]
└── README.md                              [Add WebSocket section]
```

### Deleted Code

- `SquadService._database` getter
- `SquadService._isFirebaseAvailable` getter
- `SquadService._pushUserToCloud()`
- `SquadService._pushMetaToCloud()`
- `SquadService._listenToCloud()`
- `SquadService.addDemoCompanions()`
- `GroupScreen` demo companion buttons (2 locations)

---

## Requirements Traceability Matrix

| Requirement ID | Design Section | Validation Method |
|----------------|----------------|-------------------|
| R1.1-R1.10 | WebSocket Server Design | Server tests |
| R2.1-R2.10 | Message Protocol | Unit tests + property tests |
| R3.1-R3.10 | WebSocket Client | Unit tests |
| R4.1-R4.10 | Connection Manager | Integration tests |
| R5.1-R5.10 | Squad Service - Location Updates | Integration tests |
| R6.1-R6.10 | Squad Service - Squad Creation | Integration tests |
| R7.1-R7.10 | Squad Service - Squad Joining | Integration tests |
| R8.1-R8.10 | Squad Service - Member Updates | Unit tests |
| R9.1-R9.10 | Squad Service - Metadata Sync | Integration tests |
| R10.1-R10.10 | Demo Code Removal Plan | Verification tests |
| R11.1-R11.10 | WebSocket Server Design | Deployment validation |
| R12.1-R12.10 | Authentication Integration | Security tests |
| R13.1-R13.10 | Error Handling | Unit tests |
| R14.1-R14.10 | Configuration | Deployment docs |
| R15.1-R15.10 | Migration Strategy | Phase validation |
| R16.1-R16.10 | Performance Considerations | Load tests |
| R17.1-R17.10 | Message Parsing & Validation | Property tests |
| R18.1-R18.10 | Testing Strategy | Test suite |
| R19.1-R19.10 | Server Squad Management | Server tests |
| R20.1-R20.10 | Documentation | README, protocol docs |

---

*End of Design Document*
