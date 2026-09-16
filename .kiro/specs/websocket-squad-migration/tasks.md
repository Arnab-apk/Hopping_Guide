# Implementation Plan: WebSocket Squad Migration

## Overview

This implementation plan migrates the Puja Parikrama app's squad (group) feature from Firebase Realtime Database to a custom WebSocket-based real-time communication system. The migration follows a 6-phase approach to ensure zero downtime and complete removal of demo/test code, resulting in a production-ready squad feature with real-time location sharing via WebSockets.

**Key Objectives:**
- Maintain functional equivalence with existing Firebase-based squad features
- Achieve sub-100ms latency for location updates
- Implement robust reconnection logic for mobile network conditions
- Remove all demo/test code for production readiness
- Deploy on free-tier infrastructure (Railway/Render/Fly.io)

**Technology Stack:**
- **Backend:** Node.js with TypeScript, `ws` WebSocket library
- **Frontend:** Flutter with `web_socket_channel` package
- **Database:** PostgreSQL (optional metadata persistence)
- **Deployment:** Railway.app (recommended) or Render.com

---

## Phase 1: Setup & Infrastructure

### 1. WebSocket Server Repository Setup

- [ ] 1.1 Create new Git repository `puja-pandal-websocket-server`
  - Initialize Node.js project with TypeScript configuration
  - Add `.gitignore` for `node_modules/`, `.env`, `dist/`
  - Set up ESLint and Prettier for code formatting
  - Create basic directory structure: `src/`, `test/`, `docs/`
  - _Requirements: R11.1, R11.7_
  - _Design: WebSocket Server Design section_

- [ ] 1.2 Install and configure server dependencies
  - Install core packages: `ws`, `dotenv`, `typescript`, `@types/node`, `@types/ws`
  - Install dev dependencies: `ts-node`, `nodemon`, `eslint`, `prettier`
  - Install test dependencies: `mocha`, `chai`, `@types/mocha`, `@types/chai`
  - Configure `tsconfig.json` with strict mode and ES2020 target
  - Create `package.json` scripts: `dev`, `build`, `start`, `test`
  - _Requirements: R11.1, R11.7_
  - _Design: Technology Stack section_

- [ ] 1.3 Implement basic WebSocket server scaffold
  - Create `src/index.ts` with WebSocket server initialization
  - Implement HTTP health check endpoint at `/health`
  - Configure server to listen on environment variable `PORT` (default: 8080)
  - Add graceful shutdown handler for SIGTERM/SIGINT signals
  - Add structured JSON logging to stdout
  - _Requirements: R1.1, R11.6, R11.10_
  - _Design: Server Architecture section_

- [ ] 1.4 Implement connection handler with authentication
  - Create `src/connection-handler.ts`
  - Parse Auth_Token from WebSocket URL query parameter `?token=`
  - Validate token format (non-empty, minimum 8 characters)
  - Close connection with code 4001 if authentication fails
  - Maintain active connections pool (Map<userId, WebSocket>)
  - Log connection events (connect, authenticate, disconnect)
  - _Requirements: R1.2-R1.3, R12.1-R12.5_
  - _Design: Connection Handler section_

- [ ] 1.5 Implement rate limiting for connections and messages
  - Add IP-based connection rate limiting (5 per minute per IP)
  - Add per-user message rate limiting (10 messages per second)
  - Store rate limit data in Map with automatic cleanup
  - Send error message with code "RATE_LIMIT" when exceeded
  - Log rate limit violations
  - _Requirements: R1.6, R12.8_
  - _Design: Rate Limiting section, Security Considerations_

### 2. Flutter WebSocket Client Implementation

- [ ] 2.1 Add `web_socket_channel` dependency to Flutter project
  - Update `app/pubspec.yaml` with `web_socket_channel: ^2.4.0`
  - Run `flutter pub get` from `app/` directory
  - Verify dependency resolution succeeds
  - _Requirements: R3.1_
  - _Design: WebSocket Client section_

- [ ] 2.2 Create WebSocket client class
  - Create `app/lib/services/websocket_client.dart`
  - Implement `WebSocketClient` class with connection state management
  - Add `Stream<ConnectionState>` exposing connection status
  - Implement `connect(String authToken)` with URL from environment variable
  - Implement `sendMessage(Map<String, dynamic>)` with JSON encoding
  - Implement `close()` for graceful connection closure
  - Add `Stream<Map<String, dynamic>>` for incoming messages
  - _Requirements: R3.1-R3.10_
  - _Design: WebSocket Client Interface & Implementation_

- [ ] 2.3 Implement message parsing with error handling
  - Wrap all JSON parsing in try-catch blocks
  - Validate required fields (`type`, `timestamp`) before processing
  - Log and discard malformed messages without crashing
  - Validate numeric coordinate ranges (lat: [-90, 90], lng: [-180, 180])
  - Convert numeric fields to doubles even if received as integers
  - Handle missing optional fields gracefully (treat as null)
  - _Requirements: R17.1-R17.10_
  - _Design: Message Parsing section_

- [ ] 2.4 Create connection state model
  - Create `app/lib/models/connection_state.dart`
  - Define `ConnectionState` enum (disconnected, connecting, connected, reconnecting, error)
  - Implement `ConnectionStatus` class with state, error message, timestamps
  - Add `isConnected` and `canRetry` getters
  - Implement `copyWith` method for immutable updates
  - _Requirements: R3.9, R4.1_
  - _Design: Connection State Model section_

### 3. Connection Manager Implementation

- [ ] 3.1 Create connection manager class
  - Create `app/lib/services/connection_manager.dart`
  - Define constants: initial backoff (1s), max backoff (30s), max failures (5)
  - Define heartbeat interval (15s) and timeout (5s)
  - Define max buffered messages (10)
  - Initialize connection state tracking variables
  - _Requirements: R4.1-R4.4_
  - _Design: Connection Manager section_

- [ ] 3.2 Implement exponential backoff reconnection logic
  - Detect connection failures through WebSocket error callbacks
  - Implement `_attemptReconnection()` with exponential backoff
  - Double backoff delay after each failure (cap at 30s)
  - Stop reconnection after 5 consecutive failures
  - Reset backoff to 1s on successful reconnection
  - Notify user when max retries reached
  - _Requirements: R4.2-R4.4_
  - _Design: Reconnection Strategy section_

- [ ] 3.3 Implement heartbeat monitoring
  - Send heartbeat message every 15 seconds when connected
  - Start 5-second timeout timer after each heartbeat sent
  - Treat connection as dead if heartbeat response not received
  - Trigger reconnection on heartbeat timeout
  - Cancel timeout timer when heartbeat_ack received
  - _Requirements: R4.6-R4.7_
  - _Design: Heartbeat Monitoring section_

- [ ] 3.4 Implement message buffering during disconnection
  - Buffer location_update messages when disconnected (max 10)
  - Drop oldest message when buffer full (FIFO)
  - Flush buffered messages after successful reconnection
  - Send buffered messages in order with error handling
  - Clear buffer after successful flush
  - _Requirements: R4.8-R4.9_
  - _Design: Message Buffering section_

- [ ] 3.5 Implement session restoration on reconnection
  - Re-send `join_squad` message after reconnection succeeds
  - Include current squad_code, member_id, and is_host status
  - Wait for server acknowledgment before flushing message buffer
  - Update local state with any missed squad metadata updates
  - Resume normal location update transmission
  - _Requirements: R4.5_
  - _Design: Connection Lifecycle section_

---

## Phase 2: Core Squad Operations Implementation

### 4. Message Protocol Implementation

- [ ] 4.1 Define message type constants and interfaces
  - Create `src/models/message-types.ts` with TypeScript interfaces
  - Define interfaces for: JoinSquadMessage, LocationUpdateMessage, SquadMetaUpdateMessage, MemberLeftMessage, HeartbeatMessage, ErrorMessage
  - Add validation helper functions for each message type
  - Export message type constants as enum
  - _Requirements: R2.1-R2.10_
  - _Design: Message Protocol section_

- [ ] 4.2 Implement message validator module
  - Create `src/validators/message-validator.ts`
  - Validate required fields (`type`, `timestamp`) for all messages
  - Validate coordinate ranges (latitude [-90, 90], longitude [-180, 180])
  - Validate squad_code format (regex: `/^PUJA[A-Z0-9]{4}$/`)
  - Validate string length limits (squad_name: 100, status: 50)
  - Validate numeric ranges (battery_level: [0, 100])
  - Return validation errors with descriptive messages
  - _Requirements: R2.9, R17.5-R17.6_
  - _Design: Message Handler Implementation section_

- [ ] 4.3 Implement message router
  - Create `src/message-handler.ts` with message routing logic
  - Parse incoming JSON with try-catch error handling
  - Validate required fields before routing
  - Route messages by type: join_squad, location_update, squad_meta_update, heartbeat
  - Log and drop messages with unknown types
  - Add server_timestamp to all outgoing messages
  - _Requirements: R1.5, R2.10_
  - _Design: Message Handler Implementation section_

### 5. Server Squad State Management

- [ ] 5.1 Implement squad state data structures
  - Create `src/models/squad.ts` with TypeScript interfaces
  - Define `MemberConnection` interface (userId, userName, photoUrl, isHost, lastSeen, websocket)
  - Define `SquadMetadata` interface (code, name, meetupPointName, coordinates, timestamps)
  - Define `SquadState` interface (metadata, members Map)
  - Create global `squads` Map<string, SquadState>
  - _Requirements: R19.1_
  - _Design: Squad State Manager section_

- [ ] 5.2 Implement join_squad message handler
  - Create `handleJoinSquad()` function in message-handler.ts
  - Validate squad_code format and coordinates
  - If is_host=true: create new squad entry
  - If is_host=false: verify squad exists, return SQUAD_NOT_FOUND error if not
  - Add member to squad's connection list
  - Send `squad_joined` acknowledgment with metadata
  - Broadcast `member_joined` to existing squad members
  - Send current member list to new member
  - _Requirements: R6.1-R6.10, R7.1-R7.10, R19.2-R19.7_
  - _Design: Join Squad Handler section_

- [ ] 5.3 Implement location_update message handler
  - Create `handleLocationUpdate()` function
  - Apply rate limiting (10 updates per second per user)
  - Validate coordinate ranges
  - Update member's lastSeen timestamp
  - Broadcast location_update to all squad members except sender
  - Log broadcast count for debugging
  - _Requirements: R5.1-R5.10, R8.1-R8.10_
  - _Design: Location Update Handler section_

- [ ] 5.4 Implement squad_meta_update message handler
  - Create `handleMetadataUpdate()` function
  - Extract squad_name, meetup_point_name, meetup coordinates
  - Update squad metadata in memory
  - Persist metadata to database if configured
  - Broadcast metadata update to all squad members
  - Handle partial updates (preserve existing values for missing fields)
  - _Requirements: R9.1-R9.10_
  - _Design: Squad Metadata Synchronization section_

- [ ] 5.5 Implement broadcast engine
  - Create `broadcastToSquad()` function
  - Look up squad by code
  - Iterate through squad members, excluding optional sender
  - Send JSON message to each member's WebSocket
  - Check WebSocket.OPEN state before sending
  - Log broadcast count and any send errors
  - _Requirements: R1.7_
  - _Design: Broadcast Engine section_

- [ ] 5.6 Implement connection cleanup on disconnect
  - Create `handleDisconnect()` function
  - Find and remove member from all squads
  - Broadcast `member_left` message to remaining members
  - Schedule squad cleanup if no members remain (5 minute delay)
  - Remove empty squads from memory
  - Log disconnect events
  - _Requirements: R19.8-R19.10_
  - _Design: Connection Cleanup section_

### 6. Squad Service WebSocket Integration

- [ ] 6.1 Remove Firebase RTDB dependencies from Squad Service
  - Delete `_database` getter from `app/lib/services/squad_service.dart`
  - Delete `_isFirebaseAvailable` getter
  - Delete `_pushUserToCloud()` method
  - Delete `_pushMetaToCloud()` method
  - Delete `_listenToCloud()` method
  - Remove Firebase Database import statements
  - _Requirements: R15.1-R15.4_
  - _Design: Squad Service Modifications - Removed Methods section_

- [ ] 6.2 Add WebSocket dependencies to Squad Service
  - Add `WebSocketClient` and `ConnectionManager` as constructor parameters
  - Add `_isWebSocketConnected` boolean state variable
  - Add `_lastLocationUpdate` DateTime tracking variable
  - Add connection state stream subscription
  - Update connection state when WebSocket status changes
  - _Requirements: R15.5-R15.6_
  - _Design: Squad Service Modifications - New Dependencies section_

- [ ] 6.3 Implement WebSocket-based createSquad()
  - Generate Squad_Code with format PUJA#### (4 random alphanumeric)
  - Get real GPS coordinates from LocationService (no fake data)
  - Initialize members with ONLY local user (zero companions)
  - Get Auth_Token from AuthService (use guest ID if not authenticated)
  - Establish WebSocket connection via ConnectionManager
  - Send `join_squad` message with is_host=true
  - Send `squad_meta_update` message with squad details
  - Persist state to SharedPreferences
  - Set up WebSocket message listener
  - Handle connection errors with user-friendly messages
  - _Requirements: R6.1-R6.10_
  - _Design: Modified createSquad() section_

- [ ] 6.4 Implement WebSocket-based joinSquad()
  - Validate squad code format (PUJA####)
  - Establish WebSocket connection
  - Send `join_squad` message with is_host=false
  - Wait for server confirmation (squad_joined message)
  - Update squad metadata from server response
  - Populate members list from server-provided member roster
  - Return false with error "Squad not found" if SQUAD_NOT_FOUND error received
  - Persist Squad_Code locally after successful join
  - Start location update transmission
  - _Requirements: R7.1-R7.10_
  - _Design: Squad Joining Flow section_

- [ ] 6.5 Implement WebSocket-based updateUserLocation()
  - Check `_isSharingLocation` and `_isWebSocketConnected` before proceeding
  - Apply throttling: minimum 5 seconds between updates (15s in battery saver)
  - Skip update if moved less than 10 meters and less than 30 seconds elapsed
  - Get current battery level from platform channel
  - Update local user member in members list
  - Send `location_update` message via WebSocket
  - Update `_lastLocationUpdate` timestamp
  - Call notifyListeners() to update UI
  - _Requirements: R5.1-R5.10_
  - _Design: Modified updateUserLocation() section_

- [ ] 6.6 Implement WebSocket message listener
  - Create `_listenToWebSocketMessages()` method
  - Subscribe to WebSocketClient.messages stream
  - Route messages by type: location_update, squad_meta_update, member_left, member_joined, error
  - Call appropriate handler for each message type
  - _Requirements: R3.5, R8.1_
  - _Design: New _listenToWebSocketMessages() section_

- [ ] 6.7 Implement location_update message handler
  - Create `_handleLocationUpdate()` method
  - Extract member_id, coordinates, status, battery_level, photo_url
  - Ignore updates where member_id matches local user
  - Validate coordinate ranges, discard if invalid
  - Update existing member or create new companion member
  - Update lastSeen timestamp
  - Call notifyListeners() if member data changed
  - _Requirements: R8.1-R8.9_
  - _Design: _handleLocationUpdate() section_

- [ ] 6.8 Implement metadata and member event handlers
  - Create `_handleMetadataUpdate()` to update squad name and meetup point
  - Create `_handleMemberLeft()` to remove member from list
  - Create `_handleMemberJoined()` to add new member to list
  - Create `_handleError()` to set lastError based on error_code
  - Clear lastError on successful operations
  - Persist metadata updates to SharedPreferences
  - Call notifyListeners() after each state change
  - _Requirements: R9.1-R9.10, R13.1-R13.10_
  - _Design: Error Handling section_

### 7. Configuration and Environment Setup

- [ ] 7.1 Add WEBSOCKET_SERVER_URL configuration to Flutter
  - Read URL from Dart environment variable `WEBSOCKET_SERVER_URL`
  - Default to `ws://localhost:8080` if not defined
  - Support both `ws://` and `wss://` protocols
  - Validate URL format before connection attempt
  - Throw descriptive exception if URL is malformed
  - Log connection URL (without token) for debugging
  - _Requirements: R14.1-R14.8_
  - _Design: Flutter App Configuration section_

- [ ] 7.2 Add environment variable support to WebSocket server
  - Create `.env.example` file with all required variables
  - Load environment variables using `dotenv` package
  - Read PORT (default: 8080), DATABASE_URL, AUTH_SECRET, NODE_ENV, LOG_LEVEL
  - Validate required environment variables on startup
  - Fail fast with descriptive error if required variables missing
  - _Requirements: R11.7, R14.9_
  - _Design: WebSocket Server Configuration section_

---

## Phase 3: Demo Code Removal

### 8. Remove Demo Companion Functionality

- [ ] 8.1 Delete addDemoCompanions() method from Squad Service
  - Remove entire `addDemoCompanions()` method from `app/lib/services/squad_service.dart`
  - Remove any helper methods used only by demo code
  - Remove hardcoded demo member data (names, coordinates, photos)
  - Verify `companionMembers` returns empty list after squad creation
  - _Requirements: R10.1, R10.3-R10.7_
  - _Design: Demo Code Removal Plan section_

- [ ] 8.2 Remove demo companion buttons from Group Screen empty state
  - Open `app/lib/screens/group_screen.dart`
  - Locate empty state Card (around line 450)
  - Remove `FilledButton.tonalIcon` with label "Add Demo Companions"
  - Remove its onPressed handler that calls `addDemoCompanions()`
  - Update empty state text to guide users to invite real friends
  - _Requirements: R10.2, R10.8-R10.9_
  - _Design: Group Screen Modifications section_

- [ ] 8.3 Remove demo companion button from at-a-glance section
  - Locate at-a-glance section in group_screen.dart (around line 720)
  - Remove `FilledButton.tonal` with label "Add Demo"
  - Remove its onPressed handler
  - _Requirements: R10.2_
  - _Design: Group Screen Modifications section_

- [ ] 8.4 Update empty state UI messaging
  - Display "No Companions Yet" heading
  - Add description: "Your squad starts with only you as host. Share squad code with friends so they can join with their real devices."
  - Show actionable buttons: "Invite Friends" (share) and "Enter Invite Code" (join)
  - Display current squad code prominently
  - Remove any references to demo companion names (Priya, Rohan, etc.)
  - _Requirements: R10.8-R10.9_
  - _Design: Modified Empty State section_

- [ ] 8.5 Add connection status indicator to UI
  - Add connection status dot to AppBar
  - Green dot: ConnectionState.connected
  - Yellow dot: ConnectionState.reconnecting
  - Red dot: ConnectionState.error
  - Grey dot: ConnectionState.disconnected
  - Update dot color reactively using Consumer<SquadService>
  - _Requirements: R13.7_
  - _Design: Added Connection Status Indicator section_

---

## Phase 4: Testing & Quality Assurance

### 9. Unit Tests - WebSocket Client

- [ ]* 9.1 Write unit tests for WebSocket message parsing
  - Test parsing valid location_update message
  - Test parsing valid join_squad message
  - Test parsing valid squad_meta_update message
  - Test handling malformed JSON (should not throw)
  - Test handling missing required fields (should discard)
  - Test handling unknown message types (should log and ignore)
  - _Requirements: R17.1-R17.2, R18.1_
  - _Design: Unit Tests (Flutter) section_

- [ ]* 9.2 Write unit tests for coordinate validation
  - Test latitude range validation [-90, 90]
  - Test longitude range validation [-180, 180]
  - Test rejection of out-of-range coordinates
  - Test conversion of integer coordinates to doubles
  - _Requirements: R17.5-R17.6, R18.7_
  - _Design: Unit Tests (Flutter) section_

- [ ]* 9.3 Write unit tests for message serialization
  - Test encoding outgoing messages to JSON
  - Test timestamp injection in outgoing messages
  - Test handling of optional fields (null/missing)
  - Test preservation of numeric precision
  - _Requirements: R18.1_
  - _Design: Unit Tests (Flutter) section_

### 10. Unit Tests - Connection Manager

- [ ]* 10.1 Write unit tests for exponential backoff logic
  - Test initial backoff starts at 1 second
  - Test backoff doubles after each failure
  - Test backoff caps at 30 seconds
  - Test backoff resets to 1s on successful connection
  - _Requirements: R4.2-R4.3, R18.5_
  - _Design: Connection Manager section_

- [ ]* 10.2 Write unit tests for reconnection limits
  - Test reconnection stops after 5 consecutive failures
  - Test failure counter resets on successful connection
  - Test user notification when max retries exceeded
  - _Requirements: R4.4_
  - _Design: Connection Manager section_

- [ ]* 10.3 Write unit tests for message buffering
  - Test messages buffered when disconnected
  - Test buffer limited to 10 messages (FIFO)
  - Test buffered messages flushed after reconnection
  - Test buffer cleared after successful flush
  - _Requirements: R4.8-R4.9, R18.5_
  - _Design: Message Buffering section_

### 11. Unit Tests - Squad Service

- [ ]* 11.1 Write unit tests for location update throttling
  - Test minimum 5-second interval enforced
  - Test 15-second interval in battery saver mode
  - Test 10-meter distance threshold
  - Test 30-second time override for distance check
  - _Requirements: R5.2-R5.3, R18.6_
  - _Design: Modified updateUserLocation() section_

- [ ]* 11.2 Write unit tests for squad code generation
  - Test generated codes match format PUJA####
  - Test codes contain only alphanumeric characters
  - Test multiple generated codes are unique
  - _Requirements: R6.1_
  - _Design: Modified createSquad() section_

- [ ]* 11.3 Write unit tests for member list management
  - Test local user added on squad creation
  - Test companion members added from location_update
  - Test members removed on member_left message
  - Test member updates preserve existing properties
  - Test local user never overwritten by incoming updates
  - _Requirements: R8.2-R8.6, R18.2_
  - _Design: _handleLocationUpdate() section_

### 12. Property-Based Tests

- [ ]* 12.1 Write property test for round-trip serialization
  - **Property: Round-trip consistency**
  - **Validates: Requirements R18.9**
  - Generate arbitrary valid SquadMember objects
  - Serialize to JSON then parse back
  - Verify all fields preserved (id, name, coordinates, status, battery, flags)
  - Run 100+ test cases with random data
  - _Requirements: R18.9_
  - _Design: Property-Based Tests section_

- [ ]* 12.2 Write property test for coordinate validation
  - **Property: Coordinate range validation**
  - **Validates: Requirements R2.9, R17.5-R17.6**
  - Generate arbitrary latitude/longitude values
  - Verify values in [-90, 90] and [-180, 180] pass validation
  - Verify values outside ranges fail validation
  - Run 100+ test cases
  - _Requirements: R18.7_
  - _Design: Property-Based Tests section_

- [ ]* 12.3 Write property test for message parsing robustness
  - **Property: Parser never crashes**
  - **Validates: Requirements R17.1-R17.2**
  - Generate arbitrary strings (valid JSON, invalid JSON, random bytes)
  - Verify parser never throws exceptions
  - Verify malformed messages logged and discarded
  - Run 100+ test cases
  - _Requirements: R18.7_
  - _Design: Property-Based Tests section_

### 13. Integration Tests

- [ ]* 13.1 Write integration test for squad creation flow
  - Start mock WebSocket server
  - Call SquadService.createSquad()
  - Verify WebSocket connection established
  - Verify join_squad message sent with is_host=true
  - Verify squad_meta_update message sent
  - Verify Squad_Code generated correctly
  - Verify companionMembers empty after creation
  - _Requirements: R6.1-R6.10, R18.3_
  - _Design: Integration Tests (Flutter) section_

- [ ]* 13.2 Write integration test for squad joining flow
  - Create squad on mock server
  - Call SquadService.joinSquad(code)
  - Verify WebSocket connection established
  - Verify join_squad message sent with is_host=false
  - Verify server sends squad metadata
  - Verify server sends member list
  - Verify local state updated with metadata and members
  - Test error case: non-existent squad code
  - _Requirements: R7.1-R7.10, R18.3_
  - _Design: Integration Tests (Flutter) section_

- [ ]* 13.3 Write integration test for location update broadcast
  - Create squad with multiple members on mock server
  - Send location_update from one member
  - Verify server broadcasts to other members
  - Verify receiving member updates local state
  - Verify sending member not overwritten by own update
  - _Requirements: R5.1-R5.10, R8.1-R8.10, R18.3_
  - _Design: Integration Tests (Flutter) section_

- [ ]* 13.4 Write integration test for reconnection logic
  - Establish connection, create squad
  - Simulate connection failure (close WebSocket)
  - Verify automatic reconnection attempt
  - Verify exponential backoff behavior
  - Verify join_squad re-sent after reconnection
  - Verify buffered messages flushed
  - _Requirements: R4.1-R4.10, R18.5_
  - _Design: Integration Tests (Flutter) section_

### 14. Server Tests

- [ ]* 14.1 Write server test for join_squad handler
  - Test squad creation when is_host=true
  - Test joining existing squad when is_host=false
  - Test error when squad code invalid format
  - Test error when joining non-existent squad
  - Test member_joined broadcast to existing members
  - Test member_list sent to new member
  - _Requirements: R6.1-R6.10, R7.1-R7.10, R19.2-R19.7_
  - _Design: Server Tests section_

- [ ]* 14.2 Write server test for location_update handler
  - Test broadcast to squad members excluding sender
  - Test rate limiting (10 per second per user)
  - Test coordinate validation
  - Test lastSeen timestamp update
  - _Requirements: R1.6, R5.1-R5.10, R19.1_
  - _Design: Server Tests section_

- [ ]* 14.3 Write server test for connection cleanup
  - Test member removed from squad on disconnect
  - Test member_left broadcast to remaining members
  - Test empty squad removed after 5 minutes
  - _Requirements: R19.8-R19.10_
  - _Design: Server Tests section_

### 15. Demo Code Removal Verification Tests

- [ ]* 15.1 Write test verifying addDemoCompanions() removed
  - Attempt to call method via dynamic invocation
  - Expect NoSuchMethodError thrown
  - _Requirements: R10.1, R18.4_
  - _Design: Demo Code Removal Verification section_

- [ ]* 15.2 Write test verifying squad starts with zero companions
  - Create new squad
  - Assert companionMembers.isEmpty
  - Assert members.length == 1 (only local user)
  - Assert members[0].isUser == true
  - _Requirements: R10.4, R10.10, R18.4, R18.10_
  - _Design: Demo Code Removal Verification section_

- [ ]* 15.3 Write test verifying companions only added via WebSocket
  - Create squad
  - Wait 5 seconds
  - Assert no companions appeared automatically
  - Simulate WebSocket member_joined message
  - Assert companion added
  - _Requirements: R10.10, R18.4_
  - _Design: Demo Code Removal Verification section_

---

## Phase 5: Migration & Firebase Removal

### 16. Complete Migration to WebSocket

- [ ] 16.1 Verify all Firebase RTDB code removed
  - Search codebase for Firebase Database imports
  - Verify `firebase_database` not in pubspec.yaml dependencies
  - Verify no references to `_database`, `_pushUserToCloud`, `_pushMetaToCloud`, `_listenToCloud`
  - Verify no `ServerValue.timestamp` usage
  - _Requirements: R15.1-R15.4_
  - _Design: Backward Compatibility section_

- [ ] 16.2 Update Squad Service initialization
  - Remove Firebase RTDB initialization from constructor
  - Add WebSocketClient and ConnectionManager as dependencies
  - Update SquadService.instance singleton pattern
  - Ensure backward compatibility with existing SharedPreferences format
  - _Requirements: R15.5-R15.7_
  - _Design: Backward Compatibility section_

- [ ] 16.3 Verify Group Screen requires no usage changes
  - Confirm Group Screen code unchanged except demo removal
  - Verify Consumer<SquadService> widgets still work
  - Verify notifyListeners() calls trigger UI updates
  - Verify error messages display in SnackBars
  - _Requirements: R15.6_
  - _Design: Backward Compatibility section_

---

## Phase 6: Deployment & Documentation

### 17. Server Deployment

- [ ] 17.1 Create Railway deployment configuration
  - Create `railway.toml` with build and deploy settings
  - Configure health check path `/health`
  - Set restart policy (ON_FAILURE, max 10 retries)
  - Configure environment variables in Railway dashboard
  - _Requirements: R11.4, R20.5_
  - _Design: Deployment Configuration section_

- [ ] 17.2 Deploy WebSocket server to Railway
  - Connect GitHub repository to Railway project
  - Configure automatic deploys on git push
  - Set environment variables: PORT, NODE_ENV, AUTH_SECRET
  - Verify deployment succeeds and server starts
  - Test health check endpoint returns 200 OK
  - Note production WebSocket URL (wss://*)
  - _Requirements: R11.4, R20.5_
  - _Design: Server Deployment section_

- [ ] 17.3 Configure production WebSocket URL in Flutter
  - Update build commands to include --dart-define=WEBSOCKET_SERVER_URL
  - Test connection from Flutter app to production server
  - Verify wss:// (secure WebSocket) works correctly
  - Verify authentication and message exchange
  - _Requirements: R14.4-R14.6_
  - _Design: Flutter App Configuration section_

### 18. Testing & Validation

- [ ] 18.1 Perform end-to-end testing on physical devices
  - Test squad creation on Device A
  - Test squad joining on Device B using invite code
  - Verify real-time location updates appear on both devices
  - Test metadata updates (squad name, meetup point) sync
  - Test member leaving and rejoining
  - _Requirements: R20.5_
  - _Design: Testing Strategy section_

- [ ] 18.2 Test under poor network conditions
  - Enable airplane mode during active squad session
  - Verify automatic reconnection after network restored
  - Verify buffered messages sent after reconnection
  - Test with intermittent connectivity (WiFi <-> cellular switching)
  - Verify connection status indicator updates correctly
  - _Requirements: R4.1-R4.10_
  - _Design: Testing Strategy section_

- [ ] 18.3 Perform load testing on production server
  - Simulate 50+ concurrent WebSocket connections
  - Send location updates from all connections simultaneously
  - Verify server memory usage stays below 512MB
  - Verify message broadcast latency stays below 100ms
  - Monitor server logs for errors or performance degradation
  - _Requirements: R1.4, R11.5, R16.1-R16.10_
  - _Design: Performance Considerations section_

### 19. Documentation

- [ ] 19.1 Update README with WebSocket setup instructions
  - Add "WebSocket Squad Feature" section
  - Document development setup: starting server, running app with local server
  - Document production build command with WEBSOCKET_SERVER_URL
  - Add troubleshooting section for common connection issues
  - Document environment variable configuration
  - _Requirements: R20.1, R20.4-R20.6_
  - _Design: README.md section_

- [ ] 19.2 Create WebSocket protocol documentation
  - Create `docs/websocket-protocol.md` file
  - Document all message types with JSON examples
  - Document field validation rules for each message type
  - Document error codes and their meanings
  - Document connection lifecycle and handshake process
  - _Requirements: R20.2, R20.7_
  - _Design: New File: docs/websocket-protocol.md section_

- [ ] 19.3 Document migration from Firebase to WebSockets
  - Create migration guide in README
  - Explain what changed (RTDB → WebSocket)
  - Clarify that existing users start fresh with new squads
  - Document backward incompatibility (old squads in Firebase not migrated)
  - Note that demo code removed for production readiness
  - _Requirements: R20.10_
  - _Design: Migration Strategy section_

- [ ] 19.4 Document deployment process
  - Document Railway deployment steps
  - Document alternative platforms (Render, Fly.io)
  - Document environment variable requirements
  - Document health check endpoint usage
  - Document log aggregation and monitoring setup
  - _Requirements: R20.5_
  - _Design: Deployment section_

- [ ] 19.5 Create inline code documentation
  - Add JSDoc comments to server TypeScript functions
  - Add Dart doc comments to public Flutter methods
  - Explain connection lifecycle and reconnection logic
  - Explain message routing and broadcast mechanism
  - Document rate limiting and security measures
  - _Requirements: R20.9_
  - _Design: Documentation Updates section_

### 20. Final Release Preparation

- [ ] 20.1 Build release APK with production configuration
  - Build with production WebSocket URL
  - Include ORS_API_KEY for routing
  - Enable code obfuscation and shrinking
  - Verify APK size within reasonable limits
  - Test release APK on physical device
  - _Requirements: R14.4_
  - _Design: Flutter App Build section_

- [ ] 20.2 Perform security review
  - Verify no secrets committed to repository
  - Verify .gitignore excludes .env, google-services.json, etc.
  - Verify rate limiting active on production server
  - Verify input validation on all server endpoints
  - Verify WebSocket server uses wss:// in production
  - _Requirements: R12.1-R12.10_
  - _Design: Security Considerations section_

- [ ] 20.3 Monitor production deployment
  - Deploy to Play Store internal testing track
  - Monitor server logs for errors
  - Monitor server resource usage (CPU, memory, connections)
  - Collect user feedback from internal testers
  - Verify no critical bugs reported
  - _Requirements: R20.5_
  - _Design: Production Deployment section_

---

## Notes

### Task Execution Guidelines

- **Required tasks** (without `*`) MUST be implemented by the coding agent
- **Optional tasks** (with `*` suffix) MAY be skipped for faster MVP delivery
- All test-related sub-tasks are marked optional to allow flexible testing strategies
- Each task includes requirement IDs for traceability
- Each task includes design section references for detailed implementation guidance

### Checkpoints

- **Checkpoint 1 (After Phase 1)**: Verify WebSocket server and client can connect and exchange test messages
- **Checkpoint 2 (After Phase 2)**: Verify squad creation, joining, and location updates work end-to-end
- **Checkpoint 3 (After Phase 3)**: Verify no demo code remains and empty state displays correctly
- **Checkpoint 4 (After Phase 4)**: Verify test suite passes and coverage meets quality standards
- **Checkpoint 5 (After Phase 5)**: Verify Firebase RTDB completely removed and app works WebSocket-only
- **Checkpoint 6 (After Phase 6)**: Verify production deployment stable and users can create/join squads

### Testing Strategy

- **Unit tests**: Validate individual components in isolation (message parsing, validation, throttling)
- **Integration tests**: Validate component interactions (client-server communication, state updates)
- **Property-based tests**: Validate universal properties (round-trip serialization, coordinate validation)
- **End-to-end tests**: Validate complete user flows on physical devices

### Performance Targets

- Location update broadcast latency: < 100ms (server receives to members receive)
- Message parsing time: < 10ms per message
- WebSocket reconnection time: < 5 seconds (disconnect to reconnect success)
- Server memory usage: < 512MB with 100 concurrent connections

### Deployment Notes

- **Development**: Use `ws://localhost:8080` for local WebSocket server
- **Production**: Use `wss://` (secure WebSocket) with Railway/Render hosted server
- **Free tier limits**: Railway (512MB RAM, 500 hours/month), Render (512MB RAM, 750 hours/month)
- **Monitoring**: Use server logs (JSON stdout) for debugging and monitoring

### Known Limitations (MVP)

- No JWT signature verification (trust client-provided user IDs)
- No Redis/message queue (single-process server)
- No horizontal scaling (max ~1000 concurrent connections per instance)
- No message history persistence (ephemeral real-time only)
- No offline message delivery (must be connected to receive updates)

### Future Enhancements (Post-MVP)

- JWT token verification with Firebase Admin SDK
- PostgreSQL persistence for squad metadata and message history
- Horizontal scaling with Redis pub/sub
- Offline message delivery when members reconnect
- Analytics and monitoring dashboard

---

## Task Dependency Graph

```json
{
  "waves": [
    {
      "id": 0,
      "tasks": ["1.1", "2.1"]
    },
    {
      "id": 1,
      "tasks": ["1.2", "2.2", "2.4"]
    },
    {
      "id": 2,
      "tasks": ["1.3", "1.4", "2.3", "3.1", "4.1"]
    },
    {
      "id": 3,
      "tasks": ["1.5", "3.2", "3.3", "4.2"]
    },
    {
      "id": 4,
      "tasks": ["3.4", "3.5", "4.3", "5.1"]
    },
    {
      "id": 5,
      "tasks": ["5.2", "5.3", "5.4", "7.1", "7.2"]
    },
    {
      "id": 6,
      "tasks": ["5.5", "5.6", "6.1", "6.2"]
    },
    {
      "id": 7,
      "tasks": ["6.3", "6.4", "6.5"]
    },
    {
      "id": 8,
      "tasks": ["6.6", "6.7", "6.8"]
    },
    {
      "id": 9,
      "tasks": ["8.1", "8.2", "8.3"]
    },
    {
      "id": 10,
      "tasks": ["8.4", "8.5"]
    },
    {
      "id": 11,
      "tasks": ["9.1", "9.2", "9.3", "10.1", "10.2", "10.3", "11.1", "11.2", "11.3"]
    },
    {
      "id": 12,
      "tasks": ["12.1", "12.2", "12.3", "13.1", "13.2"]
    },
    {
      "id": 13,
      "tasks": ["13.3", "13.4", "14.1", "14.2", "14.3"]
    },
    {
      "id": 14,
      "tasks": ["15.1", "15.2", "15.3"]
    },
    {
      "id": 15,
      "tasks": ["16.1", "16.2", "16.3"]
    },
    {
      "id": 16,
      "tasks": ["17.1", "17.2"]
    },
    {
      "id": 17,
      "tasks": ["17.3", "18.1", "18.2"]
    },
    {
      "id": 18,
      "tasks": ["18.3", "19.1", "19.2", "19.3", "19.4", "19.5"]
    },
    {
      "id": 19,
      "tasks": ["20.1", "20.2"]
    },
    {
      "id": 20,
      "tasks": ["20.3"]
    }
  ]
}
```
