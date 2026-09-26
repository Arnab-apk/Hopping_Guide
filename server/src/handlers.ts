import { WebSocket } from 'ws';
import { v4 as uuidv4 } from 'uuid';
import { SquadManager } from './squad-manager';
import * as db from './db';
import {
  RealtimeEnvelope,
  PresencePayload,
  LocationUpdatePayload,
  ChatMessagePayload,
  SeparationAlertPayload,
  ClientMessage,
  JoinSquadMessage,
  LocationUpdateMessage,
  SquadMetaUpdateMessage,
  LeaveSquadMessage,
} from './types';

// ------------------------------------------------------------------------------
// Rate Limiter
// ------------------------------------------------------------------------------
const rateLimiter = new Map<string, number[]>();

function checkRateLimit(userId: string, maxPerSecond = 15): boolean {
  const now = Date.now();
  const timestamps = rateLimiter.get(userId) || [];
  const recent = timestamps.filter((t) => now - t < 1000);
  if (recent.length >= maxPerSecond) {
    return false;
  }
  recent.push(now);
  rateLimiter.set(userId, recent);
  return true;
}

// ------------------------------------------------------------------------------
// Scoped Realtime Squad Channels: squad:<squad_id>
// ------------------------------------------------------------------------------
// Map<squadId, Map<userId, WebSocket>>
const squadChannels = new Map<string, Map<string, WebSocket>>();

export function subscribeToSquadChannel(squadId: string, userId: string, ws: WebSocket): void {
  if (!squadChannels.has(squadId)) {
    squadChannels.set(squadId, new Map());
  }
  squadChannels.get(squadId)!.set(userId, ws);
  console.log(`[Realtime] User ${userId} subscribed to squad:${squadId}`);
}

export function unsubscribeFromSquadChannel(squadId: string, userId: string): void {
  const channel = squadChannels.get(squadId);
  if (channel) {
    channel.delete(userId);
    if (channel.size === 0) {
      squadChannels.delete(squadId);
    }
  }
}

export function broadcastToSquad<T>(
  squadId: string,
  envelope: RealtimeEnvelope<T>,
  excludeUserId?: string
): void {
  const channel = squadChannels.get(squadId);
  if (!channel) return;

  const data = JSON.stringify(envelope);
  for (const [uid, ws] of channel.entries()) {
    if (excludeUserId && uid === excludeUserId) continue;
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(data);
    }
  }
}

// ------------------------------------------------------------------------------
// Utilities & Haversine Distance
// ------------------------------------------------------------------------------
export function sendJson(ws: WebSocket, payload: any): void {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(payload));
  }
}

export function sendError(ws: WebSocket, code: string, message: string): void {
  sendJson(ws, {
    type: 'error',
    code,
    message,
    server_timestamp: Date.now(),
  });
}

export function haversineDistanceMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371000; // Earth radius in meters
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// ------------------------------------------------------------------------------
// Separation Alert State Machine with Hysteresis & Cooldown (Sections 31-33, 59)
// ------------------------------------------------------------------------------
interface SeparationState {
  isAlerted: boolean;
  lastAlertSentAt: number;
}
const separationStates = new Map<string, SeparationState>(); // `${squadId}:${userId}` -> state

// Throttle DB location updates: at most once every 15 seconds per user
const lastLocationDbSave = new Map<string, number>();

// ------------------------------------------------------------------------------
// Main WebSocket Message Handler
// ------------------------------------------------------------------------------
export async function handleClientMessage(
  ws: WebSocket,
  userId: string,
  rawMessage: string,
  manager: SquadManager,
  currentSquadId?: string
): Promise<void> {
  let message: any;
  try {
    message = JSON.parse(rawMessage);
  } catch (e) {
    console.error(`[Handlers] JSON parse error from ${userId}:`, e);
    sendError(ws, 'MALFORMED_JSON', 'Could not parse JSON message');
    return;
  }

  if (!message.type) {
    sendError(ws, 'MISSING_TYPE', 'Message must contain a "type" field');
    return;
  }

  // 1. Standardized Realtime Envelope Check
  const squadId = message.squadId || currentSquadId;

  switch (message.type) {
    case 'presence':
      handlePresence(ws, userId, squadId, message.payload as PresencePayload);
      break;

    case 'location_update':
      // Check whether this is legacy or envelope format
      if (message.payload && message.payload.lat !== undefined) {
        await handleStandardLocationUpdate(ws, userId, squadId, message.payload as LocationUpdatePayload);
      } else {
        handleLegacyLocationUpdate(ws, userId, message as LocationUpdateMessage, manager);
      }
      break;

    case 'chat_message':
      await handleChatMessage(ws, userId, squadId, message.payload as ChatMessagePayload);
      break;

    case 'join_squad':
      handleLegacyJoinSquad(ws, userId, message as JoinSquadMessage, manager);
      break;

    case 'squad_meta_update':
      handleLegacySquadMetaUpdate(ws, userId, message as SquadMetaUpdateMessage, manager);
      break;

    case 'leave_squad':
      handleLegacyLeaveSquad(ws, userId, message as LeaveSquadMessage, manager);
      break;

    case 'heartbeat':
      sendJson(ws, {
        type: 'heartbeat_ack',
        server_timestamp: Date.now(),
      });
      break;

    default:
      console.warn(`[Handlers] Unknown message type: ${message.type}`);
      sendError(ws, 'UNKNOWN_TYPE', `Unknown message type: ${message.type}`);
      break;
  }
}

// ------------------------------------------------------------------------------
// Realtime Handlers (Standard Envelope)
// ------------------------------------------------------------------------------

function handlePresence(
  _ws: WebSocket,
  userId: string,
  squadId: string | undefined,
  payload: PresencePayload
): void {
  if (!squadId) return;

  const envelope: RealtimeEnvelope<PresencePayload> = {
    type: 'presence',
    eventId: uuidv4(),
    squadId,
    senderId: userId,
    timestamp: new Date().toISOString(),
    payload: {
      state: payload?.state || 'online',
    },
  };

  broadcastToSquad(squadId, envelope);
}

async function handleStandardLocationUpdate(
  ws: WebSocket,
  userId: string,
  squadId: string | undefined,
  payload: LocationUpdatePayload
): Promise<void> {
  if (!squadId) {
    sendError(ws, 'MISSING_SQUAD_ID', 'Squad ID is required for location update');
    return;
  }

  if (!checkRateLimit(userId, 15)) {
    return; // Throttle excessive GPS bursts
  }

  const { lat, lng, accuracy, heading, speed } = payload;
  if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return; // Drop invalid GPS
  }

  const now = Date.now();
  const nowIso = new Date(now).toISOString();

  // 1. Broadcast live transient GPS fan-out to all connected members in squad:<squadId>
  const envelope: RealtimeEnvelope<LocationUpdatePayload> = {
    type: 'location_update',
    eventId: uuidv4(),
    squadId,
    senderId: userId,
    timestamp: nowIso,
    payload: {
      lat,
      lng,
      accuracy,
      heading,
      speed,
    },
  };

  broadcastToSquad(squadId, envelope, userId); // omit echo to sender

  // 2. Server-side Separation Detection (Authoritative, with 500m threshold, 450m clear, 60s cooldown)
  try {
    const squad = await db.getSquadById(squadId);
    if (squad && squad.meetup_lat != null && squad.meetup_lng != null) {
      const distance = haversineDistanceMeters(
        lat,
        lng,
        squad.meetup_lat,
        squad.meetup_lng
      );
      const threshold = squad.separation_radius_m || 500;
      const hysteresisThreshold = Math.max(threshold - 50, 0); // e.g. 450m

      const stateKey = `${squadId}:${userId}`;
      const state = separationStates.get(stateKey) || { isAlerted: false, lastAlertSentAt: 0 };

      if (distance > threshold) {
        // Outside radius! Trigger alert if not alerted or cooldown elapsed (60s)
        if (!state.isAlerted || (now - state.lastAlertSentAt > 60000)) {
          state.isAlerted = true;
          state.lastAlertSentAt = now;
          separationStates.set(stateKey, state);

          const alertEnvelope: RealtimeEnvelope<SeparationAlertPayload> = {
            type: 'separation_alert',
            eventId: uuidv4(),
            squadId,
            senderId: 'system',
            timestamp: nowIso,
            payload: {
              memberId: userId,
              distanceMeters: Math.round(distance),
              thresholdMeters: threshold,
              isCleared: false,
            },
          };

          broadcastToSquad(squadId, alertEnvelope);
        }
      } else if (distance < hysteresisThreshold && state.isAlerted) {
        // Back inside safe zone! Clear alert state
        state.isAlerted = false;
        separationStates.set(stateKey, state);

        const clearEnvelope: RealtimeEnvelope<SeparationAlertPayload> = {
          type: 'separation_alert',
          eventId: uuidv4(),
          squadId,
          senderId: 'system',
          timestamp: nowIso,
          payload: {
            memberId: userId,
            distanceMeters: Math.round(distance),
            thresholdMeters: threshold,
            isCleared: true,
          },
        };

        broadcastToSquad(squadId, clearEnvelope);
      }
    }
  } catch (err) {
    console.error('[Handlers] Separation detection error:', err);
  }

  // 3. Persist latest location to Neon Postgres throttled to once every 15 seconds
  const saveKey = `${squadId}:${userId}`;
  const lastSave = lastLocationDbSave.get(saveKey) || 0;
  if (now - lastSave >= 15000) {
    lastLocationDbSave.set(saveKey, now);
    db.upsertLocation(squadId, userId, {
      latitude: lat,
      longitude: lng,
      accuracyM: accuracy,
      headingDeg: heading,
      speedMps: speed,
    }).catch((err) => {
      console.error('[Handlers] Failed to persist location to DB:', err);
    });
  }
}

async function handleChatMessage(
  ws: WebSocket,
  userId: string,
  squadId: string | undefined,
  payload: ChatMessagePayload
): Promise<void> {
  if (!squadId) {
    sendError(ws, 'MISSING_SQUAD_ID', 'Squad ID is required for chat message');
    return;
  }

  if (!payload.message || !payload.message.trim()) {
    sendError(ws, 'INVALID_MESSAGE', 'Message text cannot be empty');
    return;
  }

  const text = payload.message.trim().slice(0, 2000); // Server-side anti-abuse character limit
  const clientMessageId = payload.clientMessageId || uuidv4();
  const nowIso = new Date().toISOString();

  try {
    // 1. Persist to Neon Postgres
    const saved = await db.saveMessage({
      squadId,
      senderUserId: userId,
      message: text,
      messageType: payload.messageType || 'text',
      mediaUrl: payload.mediaUrl,
    });

    // 2. Return optimistic ACK to sender (Section 41)
    sendJson(ws, {
      type: 'message_ack',
      eventId: uuidv4(),
      squadId,
      senderId: 'system',
      timestamp: nowIso,
      payload: {
        clientMessageId,
        serverMessageId: saved.id,
        createdAt: saved.created_at,
      },
    });

    // 3. Broadcast message envelope to other connected squad members
    const broadcastEnvelope: RealtimeEnvelope = {
      type: 'chat_message',
      eventId: uuidv4(),
      squadId,
      senderId: userId,
      timestamp: saved.created_at,
      payload: {
        id: saved.id,
        senderUserId: userId,
        message: saved.message,
        messageType: saved.message_type,
        mediaUrl: saved.media_url,
        createdAt: saved.created_at,
      },
    };

    broadcastToSquad(squadId, broadcastEnvelope, userId);
  } catch (err: any) {
    console.error('[Handlers] Error saving chat message:', err);
    sendJson(ws, {
      type: 'message_error',
      clientMessageId,
      error: err.message || 'Failed to save message',
    });
  }
}

// ------------------------------------------------------------------------------
// Legacy WebSocket Handlers (Maintained for Backward Compatibility)
// ------------------------------------------------------------------------------

function handleLegacyJoinSquad(
  ws: WebSocket,
  userId: string,
  msg: JoinSquadMessage,
  manager: SquadManager
): void {
  const code = (msg.squad_code || '').trim().toUpperCase();
  if (!code.match(/^PUJA[2-9A-HJ-NP-Z]{4}$/)) {
    sendError(ws, 'INVALID_CODE', 'Squad code must follow format PUJAXXXX (e.g. PUJAX4K9)');
    return;
  }

  const lat = Number(msg.initial_latitude);
  const lng = Number(msg.initial_longitude);
  if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    sendError(ws, 'INVALID_COORDS', 'Invalid GPS coordinates');
    return;
  }

  const memberName = (msg.member_name || '').trim() || 'Pilgrim';

  if (msg.is_host) {
    if (manager.hasSquad(code)) {
      sendError(ws, 'SQUAD_EXISTS', `Squad code ${code} is already active`);
      return;
    }

    const room = manager.createSquad(code, userId, memberName, lat, lng, ws, msg.photo_url);

    sendJson(ws, {
      type: 'squad_joined',
      squad_code: code,
      metadata: room.metadata,
      is_host: true,
      server_timestamp: Date.now(),
    });

    sendJson(ws, {
      type: 'member_list',
      squad_code: code,
      members: manager.getMemberListDTO(code),
      server_timestamp: Date.now(),
    });
  } else {
    if (!manager.hasSquad(code)) {
      sendError(ws, 'SQUAD_NOT_FOUND', `Squad ${code} not found. Please verify the invite code.`);
      return;
    }

    const room = manager.joinSquad(code, userId, memberName, lat, lng, ws, msg.photo_url);
    if (!room) {
      sendError(ws, 'JOIN_FAILED', 'Failed to join squad');
      return;
    }

    sendJson(ws, {
      type: 'squad_joined',
      squad_code: code,
      metadata: room.metadata,
      is_host: false,
      server_timestamp: Date.now(),
    });

    manager.broadcast(
      code,
      {
        type: 'member_joined',
        squad_code: code,
        member_id: userId,
        member_name: memberName,
        photo_url: msg.photo_url,
        is_host: false,
        latitude: lat,
        longitude: lng,
        status: 'Active',
        battery_level: 100,
        server_timestamp: Date.now(),
      },
      userId
    );

    sendJson(ws, {
      type: 'member_list',
      squad_code: code,
      members: manager.getMemberListDTO(code),
      server_timestamp: Date.now(),
    });
  }
}

function handleLegacyLocationUpdate(
  ws: WebSocket,
  userId: string,
  msg: LocationUpdateMessage,
  manager: SquadManager
): void {
  if (!checkRateLimit(userId, 15)) {
    sendError(ws, 'RATE_LIMITED', 'Too many location updates, throttled to 15/s');
    return;
  }

  const code = (msg.squad_code || '').trim().toUpperCase();
  const lat = Number(msg.latitude);
  const lng = Number(msg.longitude);

  if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return;
  }

  const ok = manager.updateMemberLocation(
    code,
    userId,
    lat,
    lng,
    msg.status,
    msg.battery_level,
    msg.photo_url
  );

  if (!ok) {
    sendError(ws, 'NOT_IN_SQUAD', 'Member not registered in this squad');
    return;
  }

  manager.broadcast(
    code,
    {
      type: 'location_update',
      squad_code: code,
      member_id: userId,
      latitude: lat,
      longitude: lng,
      status: msg.status || 'Active',
      battery_level: msg.battery_level ?? 100,
      photo_url: msg.photo_url,
      server_timestamp: Date.now(),
    },
    userId
  );
}

function handleLegacySquadMetaUpdate(
  ws: WebSocket,
  _userId: string,
  msg: SquadMetaUpdateMessage,
  manager: SquadManager
): void {
  const code = (msg.squad_code || '').trim().toUpperCase();
  const updatedMeta = manager.updateMetadata(code, {
    name: msg.name,
    meetup_name: msg.meetup_name,
    meetup_lat: msg.meetup_lat,
    meetup_lng: msg.meetup_lng,
  });

  if (!updatedMeta) {
    sendError(ws, 'SQUAD_NOT_FOUND', `Squad ${code} not found`);
    return;
  }

  manager.broadcast(code, {
    type: 'squad_meta_updated',
    squad_code: code,
    metadata: updatedMeta,
    server_timestamp: Date.now(),
  });
}

function handleLegacyLeaveSquad(
  _ws: WebSocket,
  userId: string,
  msg: LeaveSquadMessage,
  manager: SquadManager
): void {
  const code = (msg.squad_code || '').trim().toUpperCase();
  const ok = manager.leaveSquad(code, userId);
  if (ok) {
    manager.broadcast(code, {
      type: 'member_left',
      squad_code: code,
      member_id: userId,
      server_timestamp: Date.now(),
    });
  }
}
