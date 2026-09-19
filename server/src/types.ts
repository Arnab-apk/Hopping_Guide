import { WebSocket } from 'ws';

// ------------------------------------------------------------------------------
// Database & Domain Models (Neon Postgres)
// ------------------------------------------------------------------------------

export interface ProfileDTO {
  user_id: string;
  display_name: string;
  avatar_url?: string | null;
  is_guest: boolean;
  created_at: string;
  updated_at: string;
}

export interface SquadDTO {
  id: string;
  code: string;
  name: string;
  host_user_id: string;
  meetup_lat: number | null;
  meetup_lng: number | null;
  meetup_label: string | null;
  separation_radius_m: number;
  status: 'active' | 'closed';
  created_at: string;
  updated_at: string;
}

export interface NeonMemberDTO {
  squad_id: string;
  user_id: string;
  role: 'host' | 'member';
  share_location: boolean;
  joined_at: string;
  last_seen_at: string;
  display_name?: string;
  avatar_url?: string | null;
  is_guest?: boolean;
}

export interface SquadLocationDTO {
  squad_id: string;
  user_id: string;
  latitude: number;
  longitude: number;
  accuracy_m?: number | null;
  heading_deg?: number | null;
  speed_mps?: number | null;
  updated_at: string;
  display_name?: string;
}

export interface SquadMessageDTO {
  id: string;
  squad_id: string;
  sender_user_id: string;
  message_type: 'text' | 'image' | 'location' | 'system';
  message: string | null;
  media_url: string | null;
  created_at: string;
  sender_name?: string;
}

// ------------------------------------------------------------------------------
// Realtime Envelope & Payloads (Section 22 of Architecture)
// ------------------------------------------------------------------------------

export interface RealtimeEnvelope<T = any> {
  type: string;
  eventId: string;
  squadId: string;
  senderId: string;
  timestamp: string;
  payload: T;
}

export interface PresencePayload {
  state: 'online' | 'background' | 'offline';
}

export interface LocationUpdatePayload {
  lat: number;
  lng: number;
  accuracy?: number;
  heading?: number;
  speed?: number;
}

export interface ChatMessagePayload {
  clientMessageId?: string;
  message: string;
  messageType?: 'text' | 'image' | 'location' | 'system';
  mediaUrl?: string;
}

export interface MessageAckPayload {
  clientMessageId: string;
  serverMessageId: string;
  createdAt: string;
}

export interface SeparationAlertPayload {
  memberId: string;
  memberName?: string;
  distanceMeters: number;
  thresholdMeters: number;
  isCleared?: boolean;
}

export interface MeetupChangedPayload {
  lat: number;
  lng: number;
  label: string;
}

export interface RadiusChangedPayload {
  radiusMeters: number;
}

export interface MemberJoinedPayload {
  userId: string;
  displayName: string;
  role: 'host' | 'member';
  avatarUrl?: string | null;
}

export interface MemberLeftPayload {
  userId: string;
  reason?: string;
}

// ------------------------------------------------------------------------------
// Legacy WebSocket Types & Compatibility
// ------------------------------------------------------------------------------

export interface MemberConnection {
  userId: string;
  userName: string;
  photoUrl?: string;
  isHost: boolean;
  latitude: number;
  longitude: number;
  status: string;
  batteryLevel: number;
  lastSeen: number;
  websocket: WebSocket;
}

export interface SquadMetadata {
  code: string;
  name: string;
  meetupPointName: string;
  meetupLat: number;
  meetupLng: number;
  createdAt: number;
  updatedAt: number;
}

export interface SquadRoom {
  metadata: SquadMetadata;
  members: Map<string, MemberConnection>;
}

export interface SquadMemberDTO {
  member_id: string;
  member_name: string;
  photo_url?: string;
  is_host: boolean;
  latitude: number;
  longitude: number;
  status: string;
  battery_level: number;
  last_seen: number;
}

export interface BaseClientMessage {
  type: string;
  timestamp: number;
}

export interface JoinSquadMessage extends BaseClientMessage {
  type: 'join_squad';
  squad_code: string;
  member_name: string;
  is_host: boolean;
  initial_latitude: number;
  initial_longitude: number;
  photo_url?: string;
}

export interface LocationUpdateMessage extends BaseClientMessage {
  type: 'location_update';
  squad_code: string;
  latitude: number;
  longitude: number;
  status?: string;
  battery_level?: number;
  photo_url?: string;
}

export interface SquadMetaUpdateMessage extends BaseClientMessage {
  type: 'squad_meta_update';
  squad_code: string;
  name?: string;
  meetup_name?: string;
  meetup_lat?: number;
  meetup_lng?: number;
}

export interface LeaveSquadMessage extends BaseClientMessage {
  type: 'leave_squad';
  squad_code: string;
}

export interface HeartbeatMessage extends BaseClientMessage {
  type: 'heartbeat';
}

export type ClientMessage =
  | JoinSquadMessage
  | LocationUpdateMessage
  | SquadMetaUpdateMessage
  | LeaveSquadMessage
  | HeartbeatMessage;
