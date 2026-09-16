import { WebSocket } from 'ws';

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

// Client message payloads
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
