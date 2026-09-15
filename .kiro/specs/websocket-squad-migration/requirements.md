# Requirements Document: WebSocket Squad Migration

## Introduction

This document specifies the requirements for migrating the Puja Parikrama app's squad (group) feature from Firebase Realtime Database to WebSockets, and removing all demo/test code. The migration maintains existing squad functionality (create, join, live location sharing, member visibility) while replacing the real-time communication layer with WebSockets for better control, reduced vendor lock-in, and alignment with the open-source goals of the project.

## Glossary

- **Squad_Service**: The Flutter service class managing squad state, membership, and location updates
- **WebSocket_Client**: The Flutter WebSocket client component that maintains persistent connections to the backend
- **WebSocket_Server**: The backend server that handles WebSocket connections and message routing between squad members
- **Squad_Member**: A user who has joined a squad and shares location data
- **Squad_Code**: An 8-character alphanumeric identifier (format: PUJA####) used to join a squad
- **Location_Update**: A message containing a member's GPS coordinates, timestamp, and metadata
- **Connection_Manager**: Component responsible for WebSocket lifecycle, reconnection logic, and health checks
- **Message_Protocol**: The JSON-based message format for client-server communication
- **Demo_Code**: Test functionality that creates fake squad members with simulated data
- **Group_Screen**: The Flutter UI screen displaying squad information and member list
- **Auth_Token**: Authentication credential passed during WebSocket handshake
- **Heartbeat**: Periodic ping/pong messages to detect connection health
- **Presence_State**: Real-time tracking of which squad members are currently connected

## Requirements

### Requirement 1: WebSocket Server Implementation

**User Story:** As a backend developer, I want a WebSocket server that handles squad connections, so that squad members can share location data in real-time without Firebase dependency.

#### Acceptance Criteria

1. THE WebSocket_Server SHALL listen for incoming WebSocket connections on a configurable port
2. WHEN a client connects, THE WebSocket_Server SHALL authenticate the connection using an Auth_Token
3. WHEN authentication succeeds, THE WebSocket_Server SHALL maintain the connection in an active connections pool
4. THE WebSocket_Server SHALL support at least 1000 concurrent WebSocket connections without performance degradation
5. WHEN a client sends a message, THE WebSocket_Server SHALL parse the Message_Protocol, and IF parsing fails, THE WebSocket_Server SHALL drop the malformed message silently and continue processing other messages
6. THE WebSocket_Server SHALL implement rate limiting of 10 location updates per second per client
7. WHEN the WebSocket_Server receives a Location_Update, THE WebSocket_Server SHALL broadcast it to all members in the same Squad_Code
8. THE WebSocket_Server SHALL persist squad metadata (squad name, meetup point, host ID) in a database
9. THE WebSocket_Server SHALL clean up stale squad data after 7 days of inactivity
10. THE WebSocket_Server SHALL log all connection events, errors, and message routing for debugging

### Requirement 2: Message Protocol Definition

**User Story:** As a developer, I want a standardized message protocol, so that client and server can communicate unambiguously.

#### Acceptance Criteria

1. THE Message_Protocol SHALL use JSON format for all messages
2. THE Message_Protocol SHALL include a "type" field identifying the message category (join_squad, location_update, squad_meta_update, member_left, heartbeat)
3. THE Message_Protocol SHALL include a "timestamp" field with Unix milliseconds for all messages
4. WHEN message type is "location_update", THE Message_Protocol SHALL include fields: squad_code, member_id, latitude, longitude, status, battery_level, photo_url
5. WHEN message type is "join_squad", THE Message_Protocol SHALL include fields: squad_code, member_id, member_name, is_host, initial_latitude, initial_longitude
6. WHEN message type is "squad_meta_update", THE Message_Protocol SHALL include fields: squad_code, squad_name, meetup_point_name, meetup_latitude, meetup_longitude
7. WHEN message type is "member_left", THE Message_Protocol SHALL include fields: squad_code, member_id
8. THE Message_Protocol SHALL include an optional "error" field with human-readable error descriptions
9. THE Message_Protocol SHALL validate all numeric coordinates, and IF any component of a coordinate pair is invalid (latitude not in -90 to 90 or longitude not in -180 to 180), THEN THE Message_Protocol SHALL reject the entire coordinate pair, accept the message with a coordinate validation error flag, and continue processing
10. FOR ALL messages sent by the server, THE Message_Protocol SHALL include a "server_timestamp" field for clock synchronization

### Requirement 3: Flutter WebSocket Client Integration

**User Story:** As a mobile developer, I want a WebSocket client in the Flutter app, so that the app can establish and maintain real-time connections.

#### Acceptance Criteria

1. THE WebSocket_Client SHALL use the "web_socket_channel" Dart package for WebSocket communication
2. WHEN Squad_Service creates or joins a squad, THE WebSocket_Client SHALL initiate a connection to the WebSocket_Server
3. THE WebSocket_Client SHALL include the Auth_Token in the initial connection handshake as a query parameter
4. WHEN connection is established, THE WebSocket_Client SHALL send a "join_squad" message with current user details immediately upon handshake completion
5. THE WebSocket_Client SHALL listen for incoming messages and parse them according to Message_Protocol
6. WHEN a "location_update" message arrives for a companion member, THE WebSocket_Client SHALL update Squad_Service member state
7. WHEN a "squad_meta_update" message arrives, THE WebSocket_Client SHALL update squad name and meetup point in Squad_Service
8. WHEN a "member_left" message arrives, THE WebSocket_Client SHALL remove that member from Squad_Service
9. THE WebSocket_Client SHALL expose a stream of connection states (connecting, connected, disconnected, error)
10. THE WebSocket_Client SHALL close the connection cleanly when Squad_Service.leaveSquad() is called

### Requirement 4: Connection Lifecycle Management

**User Story:** As a user, I want the app to automatically reconnect if my connection drops, so that I don't lose squad functionality during poor network conditions.

#### Acceptance Criteria

1. THE Connection_Manager SHALL detect connection failures through WebSocket error callbacks
2. WHEN a connection fails, THE Connection_Manager SHALL attempt reconnection with exponential backoff starting at 1 second
3. THE Connection_Manager SHALL limit reconnection attempts to a maximum delay of 30 seconds between attempts
4. THE Connection_Manager SHALL stop reconnection attempts immediately when exactly 5 consecutive failures occur and notify the user
5. WHEN automatic reconnection succeeds, THE Connection_Manager SHALL re-send the "join_squad" message to restore session state
6. THE Connection_Manager SHALL implement Heartbeat messages every 15 seconds to detect stale connections
7. WHEN a Heartbeat response is not received within 5 seconds, THE Connection_Manager SHALL treat the connection as dead and reconnect
8. THE Connection_Manager SHALL preserve unsent Location_Update messages during disconnection and send them after reconnection
9. THE Connection_Manager SHALL limit the unsent message buffer to 10 messages to prevent memory issues
10. WHILE the app is in background, THE Connection_Manager SHALL maintain the WebSocket connection if location sharing is active

### Requirement 5: Location Update Transmission

**User Story:** As a squad member, I want my location updates sent efficiently, so that my friends can see my position without draining my battery.

#### Acceptance Criteria

1. WHEN Squad_Service.isSharingLocation is true, THE Squad_Service SHALL send Location_Update messages through WebSocket_Client
2. THE Squad_Service SHALL throttle location updates to a maximum of one message per 5 seconds when deciding whether to send an update
3. WHEN location changes by less than 10 meters, THE Squad_Service SHALL skip sending an update unless 30 seconds have elapsed
4. THE Location_Update SHALL include member_id, latitude, longitude, status, battery_level, photo_url, and timestamp
5. WHEN Squad_Service.isBatterySaver is true AND isSharingLocation is true, THE Squad_Service SHALL reduce update frequency to one message per 15 seconds
6. THE Squad_Service SHALL NOT send location updates when WebSocket_Client is disconnected
7. WHEN WebSocket_Client reconnects, THE Squad_Service SHALL immediately send the current location as a catch-up update
8. THE Squad_Service SHALL include the current device battery level in every Location_Update
9. THE Squad_Service SHALL update the local user's lastSeen timestamp with each location update
10. WHEN location permission is revoked, THE Squad_Service SHALL send a final Location_Update with status "Location Disabled"

### Requirement 6: Squad Creation Over WebSocket

**User Story:** As a user, I want to create a squad using WebSockets, so that I can start a hopping group without Firebase.

#### Acceptance Criteria

1. WHEN Squad_Service.createSquad() is called, THE Squad_Service SHALL generate a unique Squad_Code with format PUJA#### (4 random alphanumeric characters)
2. THE Squad_Service SHALL establish a WebSocket connection before sending any squad data
3. THE Squad_Service SHALL send a "join_squad" message with is_host set to true
4. THE Squad_Service SHALL send a "squad_meta_update" message with squad name, meetup point, and coordinates
5. WHEN the server acknowledges squad creation, THE Squad_Service SHALL persist the Squad_Code locally using SharedPreferences
6. THE Squad_Service SHALL initialize the members list with only the local user as host
7. THE Squad_Service SHALL NOT add any demo or test companions during squad creation
8. WHEN WebSocket_Server returns an error, THE Squad_Service SHALL retry on any recoverable error condition (network timeout, duplicate code, transient server error), and IF a new Squad_Code was not generated for the retry, THE Squad_Service SHALL allow retry with the same Squad_Code
9. THE Squad_Service SHALL set isSharingLocation to true by default upon squad creation
10. THE Squad_Service SHALL use the current real GPS coordinates from LocationService as the initial location

### Requirement 7: Squad Joining Over WebSocket

**User Story:** As a user, I want to join an existing squad with an invite code, so that I can see my friends' locations.

#### Acceptance Criteria

1. WHEN Squad_Service.joinSquad(code) is called, THE Squad_Service SHALL validate the code format matches PUJA####
2. THE Squad_Service SHALL establish a WebSocket connection to WebSocket_Server
3. THE Squad_Service SHALL send a "join_squad" message with the provided Squad_Code and is_host set to false
4. WHEN WebSocket_Server sends explicit confirmation that the squad exists, THE Squad_Service SHALL set the Squad_Code locally
5. WHEN WebSocket_Server sends existing squad metadata, THE Squad_Service SHALL update squad name, meetup point name, and meetup point coordinates together as a single atomic update
6. WHEN WebSocket_Server sends current member locations, THE Squad_Service SHALL populate the members list with companion members
7. IF the Squad_Code does not exist on the server, THE Squad_Service SHALL return false and set lastError to "Squad not found"
8. THE Squad_Service SHALL persist the Squad_Code locally after successful join
9. THE Squad_Service SHALL start sending location updates immediately after joining
10. THE Squad_Service SHALL receive a complete member roster within 2 seconds of joining

### Requirement 8: Real-Time Member Updates

**User Story:** As a squad member, I want to see real-time updates when companions move, so that I can track them on the map.

#### Acceptance Criteria

1. WHEN WebSocket_Client receives a "location_update" message, THE Squad_Service SHALL update the corresponding Squad_Member in the members list
2. IF the member_id does not exist in members list, THE Squad_Service SHALL create a new Squad_Member with isUser set to false
3. THE Squad_Service SHALL update member latitude, longitude, status, battery_level, and lastSeen timestamp
4. WHEN member data actually changes, THE Squad_Service SHALL call notifyListeners() to trigger UI updates
5. THE Squad_Service SHALL preserve companion member properties (name, photo_url, is_host) across location updates
6. THE Squad_Service SHALL ignore incoming WebSocket "location_update" messages where member_id matches the local user, and SHALL NOT overwrite the local user member data
7. WHEN a "member_left" message is received, THE Squad_Service SHALL remove that companion from the members list
8. THE Squad_Service SHALL calculate relative distance between user and each companion using haversine formula
9. THE Squad_Service SHALL sort companion members by distance from user in ascending order
10. WHEN focused member coordinates change, THE Squad_Service SHALL maintain the focusedMemberId without clearing it

### Requirement 9: Squad Metadata Synchronization

**User Story:** As a squad host, I want metadata changes (squad name, meetup point) to sync to all members, so that everyone has consistent information.

#### Acceptance Criteria

1. WHEN Squad_Service.setMeetupPoint() is called, THE Squad_Service SHALL send a "squad_meta_update" message through WebSocket_Client
2. THE "squad_meta_update" message SHALL include the Squad_Code, meetup_point_name, meetup_latitude, and meetup_longitude
3. WHEN WebSocket_Client receives a "squad_meta_update" from another member, THE Squad_Service SHALL update local metadata
4. THE Squad_Service SHALL persist updated metadata to SharedPreferences
5. THE Squad_Service SHALL notify listeners after metadata updates to refresh the UI
6. WHEN a non-host member tries to update metadata, THE WebSocket_Server SHALL allow the update (no role-based restrictions)
7. THE Squad_Service SHALL always enforce timestamp comparison when handling conflicting metadata updates, accepting the update with the most recent timestamp
8. THE Squad_Service SHALL preserve meetup coordinates when only the name is updated
9. THE Squad_Service SHALL preserve the squad name when only meetup point is updated
10. WHEN squad_name is empty in an update, THE Squad_Service SHALL keep the existing squad name unchanged

### Requirement 10: Demo Code Removal

**User Story:** As a developer, I want all demo/test code removed from the production app, so that users only see real squad members.

#### Acceptance Criteria

1. THE Group_Screen SHALL NOT include any method named addDemoCompanions or similar test member creation functions
2. THE Group_Screen SHALL NOT display any UI buttons or controls for adding demo companions
3. THE Squad_Service SHALL NOT include any methods that generate fake or simulated Squad_Member objects
4. THE Squad_Service SHALL initialize squads with zero companion members (only the local user)
5. WHEN a squad has zero companions, THE Group_Screen SHALL display an empty state prompting users to invite real friends
6. THE Squad_Service SHALL NOT include any hardcoded member data with fake names, coordinates, or profile pictures
7. THE Squad_Service._initMembers() SHALL create exactly one Squad_Member representing the local authenticated user
8. THE Group_Screen empty state SHALL provide actionable buttons: "Invite Friends" (share) and "Enter Invite Code" (join)
9. THE Group_Screen SHALL remove all references to demo companion names like "Priya", "Rohan", or similar test identifiers
10. THE Squad_Service.companionMembers getter SHALL return an empty list immediately after squad creation until real members join

### Requirement 11: Backend WebSocket Server Technology Stack

**User Story:** As a DevOps engineer, I want a lightweight WebSocket server implementation, so that I can deploy it on free-tier infrastructure.

#### Acceptance Criteria

1. THE WebSocket_Server SHALL be implemented using Node.js with the "ws" library or Python with "websockets" library
2. THE WebSocket_Server SHALL use an in-memory data structure (Map or Dictionary) for active connection tracking
3. THE WebSocket_Server SHALL optionally integrate with PostgreSQL or SQLite for squad metadata persistence
4. THE WebSocket_Server SHALL be deployable on free-tier platforms (Railway, Render, Fly.io) without modification
5. THE WebSocket_Server SHALL consume less than 512MB RAM with 100 concurrent connections
6. THE WebSocket_Server SHALL expose a health check HTTP endpoint at /health for monitoring
7. THE WebSocket_Server SHALL support environment variable configuration for port, database URL, and auth secret
8. THE WebSocket_Server SHALL run as a single process without requiring Redis or external message queues for MVP
9. THE WebSocket_Server SHALL implement graceful shutdown, closing all WebSocket connections with proper close frames
10. THE WebSocket_Server SHALL log structured JSON logs to stdout for easy aggregation

### Requirement 12: Authentication Integration

**User Story:** As a security-conscious developer, I want WebSocket connections authenticated, so that only legitimate users can join squads.

#### Acceptance Criteria

1. THE WebSocket_Client SHALL actively request an Auth_Token from Auth_Service before establishing a connection
2. IF Auth_Service.currentUser is null, THE WebSocket_Client SHALL use the guest user ID as Auth_Token
3. THE WebSocket_Client SHALL append the Auth_Token as a query parameter "?token=<Auth_Token>" in the WebSocket URL
4. THE WebSocket_Server SHALL validate the Auth_Token format (non-empty string, minimum 8 characters)
5. IF the Auth_Token is invalid or missing, THE WebSocket_Server SHALL immediately close the connection with code 4001
6. THE WebSocket_Server SHALL extract the user ID from the Auth_Token payload for message routing
7. THE WebSocket_Server SHALL NOT verify tokens against Firebase or external services for MVP (trust client-provided IDs)
8. THE WebSocket_Server SHALL rate-limit connection attempts to 5 per minute per IP address
9. WHEN a user has multiple WebSocket connections (multiple devices), THE WebSocket_Server SHALL route messages to all connections
10. THE WebSocket_Server SHALL include user_id in server logs for audit and debugging purposes

### Requirement 13: Error Handling and User Feedback

**User Story:** As a user, I want clear error messages when squad features fail, so that I understand what went wrong and how to fix it.

#### Acceptance Criteria

1. WHEN WebSocket connection fails, THE Squad_Service SHALL set lastError to a human-readable message
2. THE Group_Screen SHALL display Squad_Service.lastError in a SnackBar when non-null
3. WHEN squad creation fails, THE Squad_Service SHALL set lastError to "Failed to create squad. Check your internet connection."
4. WHEN joining a non-existent squad, THE Squad_Service SHALL set lastError to "Squad code not found. Please verify and try again."
5. WHEN WebSocket connection is lost, THE Squad_Service SHALL set lastError to "Connection lost. Reconnecting..."
6. WHEN reconnection succeeds, THE Squad_Service SHALL clear lastError
7. THE Group_Screen SHALL show a connection status indicator (green dot for connected, yellow for reconnecting, red for error)
8. WHEN location permission is denied, THE Squad_Service SHALL set lastError to "Location access required to share position with squad."
9. THE Squad_Service SHALL clear lastError when any operation succeeds, regardless of whether other operations are still failing
10. WHEN server returns a rate limit error, THE Squad_Service SHALL set lastError to "Too many updates. Please wait a moment."

### Requirement 14: WebSocket URL Configuration

**User Story:** As a developer, I want the WebSocket server URL configurable, so that I can switch between development and production environments.

#### Acceptance Criteria

1. THE WebSocket_Client SHALL read the server URL from a Dart environment variable "WEBSOCKET_SERVER_URL"
2. WHEN "WEBSOCKET_SERVER_URL" is not defined, THE WebSocket_Client SHALL use a default development URL "ws://localhost:8080"
3. THE WebSocket_Client SHALL support both "ws://" and "wss://" (secure WebSocket) protocols
4. THE build configuration SHALL pass the production WebSocket URL via --dart-define flag
5. THE WebSocket_Client SHALL construct the full URL by appending "/squad" path to the base server URL
6. THE WebSocket_Client SHALL validate the URL format before attempting connection
7. IF the URL format is malformed, THE WebSocket_Client SHALL throw an exception with a descriptive error message without attempting connection
8. THE WebSocket_Client SHALL log the connection URL (without Auth_Token) for debugging purposes
9. THE README SHALL document how to configure the WebSocket server URL for different environments
10. THE WebSocket_Client SHALL support IPv4 and IPv6 addresses in the server URL

### Requirement 15: Backward Compatibility and Migration Path

**User Story:** As a product manager, I want a smooth migration from Firebase to WebSockets, so that existing users don't experience disruption.

#### Acceptance Criteria

1. THE Squad_Service SHALL remove all Firebase Realtime Database import statements
2. THE Squad_Service SHALL remove the _database getter and _isFirebaseAvailable check
3. THE Squad_Service SHALL remove all Firebase ServerValue.timestamp references
4. THE Squad_Service SHALL remove _pushUserToCloud(), _pushMetaToCloud(), and _listenToCloud() methods that use Firebase RTDB
5. THE Squad_Service SHALL maintain the existing public API (createSquad, joinSquad, leaveSquad, updateUserLocation) signatures
6. THE Group_Screen SHALL NOT require any changes to its Squad_Service usage patterns
7. THE SharedPreferences persistence format SHALL remain unchanged (saved_group_code, saved_group_name, saved_meetup_point)
8. THE Squad_Service SHALL clear any cached Firebase RTDB listeners during initialization
9. THE app SHALL NOT display Firebase-specific error messages to users
10. THE migration SHALL NOT require users to recreate squads or rejoin with new codes (new squads start fresh in WebSocket system)

### Requirement 16: Performance and Scalability

**User Story:** As a performance engineer, I want the WebSocket implementation to be efficient, so that the app remains responsive during real-time updates.

#### Acceptance Criteria

1. THE WebSocket_Client SHALL parse incoming JSON messages in less than 10 milliseconds for typical payloads
2. THE Squad_Service SHALL batch UI updates when receiving multiple location updates simultaneously
3. THE Squad_Service SHALL continuously use a debounce mechanism to limit notifyListeners() calls to once per 100 milliseconds
4. THE WebSocket_Server SHALL handle message routing for a 10-member squad with latency strictly less than 50 milliseconds
5. THE WebSocket_Server SHALL broadcast location updates to squad members within 100 milliseconds of receipt
6. THE Squad_Service SHALL NOT block the main UI thread when processing WebSocket messages
7. THE WebSocket_Client SHALL use Dart isolates for JSON serialization if payloads exceed 10KB
8. THE Squad_Service SHALL limit the members list to a maximum of 50 members to prevent performance degradation
9. WHEN a squad exceeds 50 members, THE WebSocket_Server SHALL reject new join requests with error "Squad is full"
10. THE Group_Screen member list SHALL use ListView.builder for efficient rendering of large member lists

### Requirement 17: WebSocket Message Parsing and Validation

**User Story:** As a developer, I want robust message parsing, so that malformed messages don't crash the app.

#### Acceptance Criteria

1. THE WebSocket_Client SHALL wrap all JSON parsing in try-catch blocks
2. WHEN JSON parsing fails, THE WebSocket_Client SHALL log the error and discard the message without crashing
3. THE WebSocket_Client SHALL validate that required fields exist before accessing them
4. WHEN a "location_update" message is missing latitude or longitude, THE WebSocket_Client SHALL discard the message
5. THE WebSocket_Client SHALL validate that latitude is between -90 and 90 degrees
6. THE WebSocket_Client SHALL validate that longitude is between -180 and 180 degrees
7. THE WebSocket_Client SHALL validate that timestamps are positive integers
8. WHEN a message has an unknown "type" field, THE WebSocket_Client SHALL log a warning and ignore the message
9. THE WebSocket_Client SHALL convert numeric fields to doubles even if they arrive as integers
10. THE WebSocket_Client SHALL treat missing optional fields (photo_url, status) as null without errors

### Requirement 18: Testing and Validation

**User Story:** As a QA engineer, I want comprehensive tests for the WebSocket migration, so that I can verify correctness.

#### Acceptance Criteria

1. THE project SHALL include unit tests for WebSocket_Client message parsing with valid and invalid JSON payloads
2. THE project SHALL include unit tests for Squad_Service WebSocket integration methods
3. THE project SHALL include integration tests that connect to a test WebSocket_Server and exchange messages
4. THE project SHALL include tests verifying that demo code is fully removed from Squad_Service and Group_Screen
5. THE project SHALL include tests for Connection_Manager reconnection logic with simulated connection failures
6. THE project SHALL include tests for location update throttling (5-second minimum interval)
7. THE project SHALL include property-based tests for Message_Protocol field validation using valid latitude/longitude ranges
8. THE Pretty_Printer SHALL format Message_Protocol JSON messages with 2-space indentation for debugging
9. FOR ALL valid Squad_Member states, serializing to JSON then parsing back SHALL produce equivalent objects (round-trip property)
10. THE tests SHALL always require Squad_Service.companionMembers to return an empty list immediately after squad creation until real members join via WebSocket

### Requirement 19: WebSocket Server Squad Management

**User Story:** As a backend developer, I want the server to manage squad state, so that members can discover each other.

#### Acceptance Criteria

1. THE WebSocket_Server SHALL maintain an in-memory Map of Squad_Code to squad state (name, meetup, host_id, member_ids)
2. WHEN a "join_squad" message arrives with is_host true, THE WebSocket_Server SHALL create a new squad entry
3. WHEN a "join_squad" message arrives with is_host false, THE WebSocket_Server SHALL verify the squad exists
4. IF a non-existent Squad_Code is joined, THE WebSocket_Server SHALL send an error message with code "SQUAD_NOT_FOUND"
5. THE WebSocket_Server SHALL add the joining member's connection to the squad's connection list
6. WHEN a member joins, THE WebSocket_Server SHALL always broadcast a "member_joined" message to all existing squad members, even if the recipient list is empty
7. THE "member_joined" message SHALL include the new member's ID, name, and initial location
8. WHEN a WebSocket connection closes, THE WebSocket_Server SHALL send "member_left" messages to remaining squad members
9. THE WebSocket_Server SHALL remove the member from the squad's connection list on disconnect
10. WHEN a squad has zero members, THE WebSocket_Server SHALL remove the squad entry from memory after 5 minutes

### Requirement 20: Documentation and Deployment

**User Story:** As a new developer joining the project, I want clear documentation, so that I can understand and deploy the WebSocket system.

#### Acceptance Criteria

1. THE README SHALL include a "WebSocket Server Setup" section with installation and running instructions
2. THE README SHALL document the WebSocket Message_Protocol with example JSON payloads for each message type
3. THE README SHALL include environment variable configuration instructions for both client and server
4. THE README SHALL provide example --dart-define commands for building the Flutter app with production WebSocket URL
5. THE README SHALL document the WebSocket_Server deployment process for free-tier platforms (Railway, Render, Fly.io)
6. THE README SHALL include a troubleshooting section for common WebSocket connection issues
7. THE README SHALL document the authentication mechanism and Auth_Token format
8. THE repository SHALL include a docker-compose.yml file for running the WebSocket_Server locally
9. THE WebSocket_Server code SHALL include inline comments explaining connection lifecycle and message routing
10. THE README SHALL include a migration guide explaining what changed from Firebase RTDB to WebSockets

