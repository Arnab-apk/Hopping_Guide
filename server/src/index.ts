import http from 'http';
import { URL } from 'url';
import { WebSocketServer, WebSocket } from 'ws';
import dotenv from 'dotenv';
import { SquadManager } from './squad-manager';
import * as db from './db';
import {
  handleClientMessage,
  sendJson,
  subscribeToSquadChannel,
  unsubscribeFromSquadChannel,
  broadcastToSquad,
} from './handlers';
import { v4 as uuidv4 } from 'uuid';

dotenv.config();

const PORT = parseInt(process.env.PORT || '8080', 10);
const HOST = process.env.HOST || '0.0.0.0';

const manager = new SquadManager();

// Helper to parse JSON body
function parseBody(req: http.IncomingMessage): Promise<any> {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk;
      if (body.length > 1e6) {
        req.destroy();
        reject(new Error('Body payload too large'));
      }
    });
    req.on('end', () => {
      if (!body.trim()) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(body));
      } catch (err) {
        reject(err);
      }
    });
    req.on('error', reject);
  });
}

function sendHttpJson(res: http.ServerResponse, statusCode: number, data: any): void {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-user-id',
  });
  res.end(JSON.stringify(data));
}

function extractUserId(req: http.IncomingMessage): string {
  const customHeader = req.headers['x-user-id'];
  if (customHeader && typeof customHeader === 'string') {
    return customHeader.trim();
  }
  const authHeader = req.headers['authorization'];
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.slice(7).trim();
    // In production with Firebase Admin SDK, verifyIdToken(token) yields uid.
    // For mobile client identity, pass token/uid cleanly.
    return token;
  }
  return `guest_${Math.random().toString(36).substring(2, 9)}`;
}

// ------------------------------------------------------------------------------
// HTTP Server (Health, Stats & Neon REST API)
// ------------------------------------------------------------------------------
const server = http.createServer(async (req, res) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-user-id',
    });
    res.end();
    return;
  }

  const reqUrl = req.url || '/';
  const parsed = new URL(reqUrl, `http://${req.headers.host || 'localhost'}`);
  const pathname = parsed.pathname;
  const method = req.method || 'GET';

  try {
    // Health & Stats
    if (pathname === '/health') {
      sendHttpJson(res, 200, {
        status: 'ok',
        service: 'puja-squad-neon-realtime-server',
        database: process.env.DATABASE_URL ? 'neon-postgres' : 'in-memory-neon-store',
        uptimeSeconds: Math.floor(process.uptime()),
        timestamp: Date.now(),
      });
      return;
    }

    if (pathname === '/stats') {
      sendHttpJson(res, 200, {
        status: 'ok',
        ...manager.getStats(),
        timestamp: Date.now(),
      });
      return;
    }

    // --------------------------------------------------------------------------
    // REST API: Squads
    // --------------------------------------------------------------------------

    // POST /api/squads (Create Squad)
    if (pathname === '/api/squads' && method === 'POST') {
      const body = await parseBody(req);
      const userId = body.hostUserId || extractUserId(req);
      const result = await db.createSquad({
        name: body.name || 'Hopping Squad',
        hostUserId: userId,
        meetupLat: body.meetupLat,
        meetupLng: body.meetupLng,
        meetupLabel: body.meetupLabel,
        separationRadiusM: body.separationRadiusM,
        hostDisplayName: body.hostDisplayName || 'Hopper Host',
        hostAvatarUrl: body.hostAvatarUrl,
        isGuest: body.isGuest ?? true,
      });
      sendHttpJson(res, 201, result);
      return;
    }

    // POST /api/squads/join (Join Squad by code)
    if (pathname === '/api/squads/join' && method === 'POST') {
      const body = await parseBody(req);
      const userId = body.userId || extractUserId(req);
      const code = (body.code || '').trim().toUpperCase();
      if (!code) {
        sendHttpJson(res, 400, { error: { code: 'INVALID_CODE', message: 'Squad code is required' } });
        return;
      }
      const result = await db.joinSquad({
        code,
        userId,
        displayName: body.displayName || 'Hopper Companion',
        avatarUrl: body.avatarUrl,
        isGuest: body.isGuest ?? true,
      });
      sendHttpJson(res, 200, result);
      return;
    }

    // GET /api/squads/preview/:code (Public Squad Preview - no location data)
    if (pathname.startsWith('/api/squads/preview/') && method === 'GET') {
      const code = pathname.replace('/api/squads/preview/', '').trim().toUpperCase();
      const squad = await db.getSquadByCode(code);
      if (!squad) {
        sendHttpJson(res, 404, { error: { code: 'SQUAD_NOT_FOUND', message: 'Squad not found' } });
        return;
      }
      const members = await db.getSquadMembers(squad.id);
      sendHttpJson(res, 200, {
        id: squad.id,
        code: squad.code,
        name: squad.name,
        meetup_label: squad.meetup_label,
        separation_radius_m: squad.separation_radius_m,
        member_count: members.length,
        host_user_id: squad.host_user_id,
        status: squad.status,
      });
      return;
    }

    // GET /api/squads/:id
    const squadIdMatch = pathname.match(/^\/api\/squads\/([a-zA-Z0-9_-]+)$/);
    if (squadIdMatch && method === 'GET') {
      const id = squadIdMatch[1];
      const squad = await db.getSquadById(id);
      if (!squad) {
        sendHttpJson(res, 404, { error: { code: 'SQUAD_NOT_FOUND', message: 'Squad not found' } });
        return;
      }
      sendHttpJson(res, 200, squad);
      return;
    }

    // GET /api/squads/:id/members
    const membersMatch = pathname.match(/^\/api\/squads\/([a-zA-Z0-9_-]+)\/members$/);
    if (membersMatch && method === 'GET') {
      const id = membersMatch[1];
      const members = await db.getSquadMembers(id);
      sendHttpJson(res, 200, members);
      return;
    }

    // GET /api/squads/:id/locations
    const locationsMatch = pathname.match(/^\/api\/squads\/([a-zA-Z0-9_-]+)\/locations$/);
    if (locationsMatch && method === 'GET') {
      const id = locationsMatch[1];
      const locations = await db.getLatestLocations(id);
      sendHttpJson(res, 200, locations);
      return;
    }

    // POST /api/squads/:id/leave
    const leaveMatch = pathname.match(/^\/api\/squads\/([a-zA-Z0-9_-]+)\/leave$/);
    if (leaveMatch && method === 'POST') {
      const id = leaveMatch[1];
      const body = await parseBody(req);
      const userId = body.userId || extractUserId(req);
      await db.leaveSquad(id, userId);
      sendHttpJson(res, 200, { success: true });
      return;
    }

    // PATCH /api/squads/:id/meetup
    const meetupMatch = pathname.match(/^\/api\/squads\/([a-zA-Z0-9_-]+)\/meetup$/);
    if (meetupMatch && method === 'PATCH') {
      const id = meetupMatch[1];
      const body = await parseBody(req);
      const hostUserId = body.hostUserId || extractUserId(req);
      const squad = await db.updateMeetup(id, hostUserId, {
        lat: body.lat,
        lng: body.lng,
        label: body.label || 'Meetup Point',
      });
      // Broadcast meetup change to squad
      broadcastToSquad(id, {
        type: 'meetup_changed',
        eventId: uuidv4(),
        squadId: id,
        senderId: hostUserId,
        timestamp: new Date().toISOString(),
        payload: { lat: body.lat, lng: body.lng, label: body.label },
      });
      sendHttpJson(res, 200, squad);
      return;
    }

    // PATCH /api/squads/:id/settings
    const settingsMatch = pathname.match(/^\/api\/squads\/([a-zA-Z0-9_-]+)\/settings$/);
    if (settingsMatch && method === 'PATCH') {
      const id = settingsMatch[1];
      const body = await parseBody(req);
      const hostUserId = body.hostUserId || extractUserId(req);
      const squad = await db.updateSettings(id, hostUserId, {
        name: body.name,
        separationRadiusM: body.separationRadiusM,
      });
      if (body.separationRadiusM != null) {
        broadcastToSquad(id, {
          type: 'radius_changed',
          eventId: uuidv4(),
          squadId: id,
          senderId: hostUserId,
          timestamp: new Date().toISOString(),
          payload: { radiusMeters: body.separationRadiusM },
        });
      }
      sendHttpJson(res, 200, squad);
      return;
    }

    // GET /api/squads/:id/messages
    const messagesMatch = pathname.match(/^\/api\/squads\/([a-zA-Z0-9_-]+)\/messages$/);
    if (messagesMatch && method === 'GET') {
      const id = messagesMatch[1];
      const limit = parseInt(parsed.searchParams.get('limit') || '50', 10);
      const messages = await db.getMessages(id, limit);
      sendHttpJson(res, 200, messages);
      return;
    }

    // POST /api/squads/:id/messages
    if (messagesMatch && method === 'POST') {
      const id = messagesMatch[1];
      const body = await parseBody(req);
      const userId = body.senderUserId || extractUserId(req);
      const saved = await db.saveMessage({
        squadId: id,
        senderUserId: userId,
        message: body.message,
        messageType: body.messageType || 'text',
        mediaUrl: body.mediaUrl,
      });
      // Broadcast chat message
      broadcastToSquad(
        id,
        {
          type: 'chat_message',
          eventId: uuidv4(),
          squadId: id,
          senderId: userId,
          timestamp: saved.created_at,
          payload: saved,
        },
        userId
      );
      sendHttpJson(res, 201, saved);
      return;
    }

    // 404 Not Found
    sendHttpJson(res, 404, { error: { code: 'NOT_FOUND', message: 'Endpoint not found' } });
  } catch (err: any) {
    console.error('[Server] HTTP Error:', err);
    sendHttpJson(res, 500, { error: { code: 'INTERNAL_ERROR', message: err.message || 'Internal server error' } });
  }
});

// ------------------------------------------------------------------------------
// WebSocket Server (Realtime Presence, GPS Fan-out, Separation Alerts, Chat)
// ------------------------------------------------------------------------------
const wss = new WebSocketServer({ noServer: true });

server.on('upgrade', (request, socket, head) => {
  const reqUrl = request.url || '/';
  const parsed = new URL(reqUrl, `http://${request.headers.host || 'localhost'}`);

  if (parsed.pathname !== '/squad' && parsed.pathname !== '/ws') {
    socket.write('HTTP/1.1 404 Not Found\r\n\r\n');
    socket.destroy();
    return;
  }

  // Extract auth/user token & squad ID
  const token = parsed.searchParams.get('token') || parsed.searchParams.get('userId');
  const squadId = parsed.searchParams.get('squadId') || '';
  const userId = token ? token.trim() : `guest_${Math.random().toString(36).substring(2, 9)}`;

  wss.handleUpgrade(request, socket, head, (ws) => {
    wss.emit('connection', ws, request, userId, squadId);
  });
});

wss.on('connection', (ws: WebSocket, _request: http.IncomingMessage, userId: string, squadId?: string) => {
  console.log(`[Server] WebSocket connected for user: ${userId} (squad: ${squadId || 'unassigned'})`);
  manager.registerConnection(userId, ws);

  if (squadId) {
    subscribeToSquadChannel(squadId, userId, ws);

    // Broadcast member presence online
    broadcastToSquad(squadId, {
      type: 'presence',
      eventId: uuidv4(),
      squadId,
      senderId: userId,
      timestamp: new Date().toISOString(),
      payload: { state: 'online' },
    });
  }

  // Send connection ack
  sendJson(ws, {
    type: 'connection_established',
    user_id: userId,
    squad_id: squadId,
    server_timestamp: Date.now(),
  });

  ws.on('message', (data: Buffer | string) => {
    handleClientMessage(ws, userId, data.toString(), manager, squadId);
  });

  ws.on('error', (err) => {
    console.error(`[Server] WebSocket Error for user ${userId}:`, err);
  });

  ws.on('close', (code, reason) => {
    console.log(`[Server] Connection closed for user ${userId} (code: ${code}, reason: ${reason.toString()})`);
    if (squadId) {
      unsubscribeFromSquadChannel(squadId, userId);
      // Broadcast member presence offline
      broadcastToSquad(squadId, {
        type: 'presence',
        eventId: uuidv4(),
        squadId,
        senderId: userId,
        timestamp: new Date().toISOString(),
        payload: { state: 'offline' },
      });
    }

    const disc = manager.handleDisconnect(userId);
    if (disc) {
      manager.broadcast(disc.squadCode, {
        type: 'member_left',
        squad_code: disc.squadCode,
        member_id: userId,
        server_timestamp: Date.now(),
      });
    }
  });
});

server.listen(PORT, HOST, () => {
  console.log('====================================================');
  console.log(`🚀 Kolkata Puja Squad Neon & Realtime Server`);
  console.log(`📡 Listening on http://${HOST}:${PORT}`);
  console.log(`🔌 WebSocket Endpoint: ws://${HOST}:${PORT}/ws`);
  console.log(`🩺 Health Check: http://${HOST}:${PORT}/health`);
  console.log('====================================================');
});

// Graceful shutdown
function shutdown(signal: string) {
  console.log(`\n[Server] Received ${signal}, gracefully shutting down...`);
  wss.close(() => {
    server.close(() => {
      console.log('[Server] Server closed successfully');
      process.exit(0);
    });
  });

  setTimeout(() => {
    console.error('[Server] Forceful shutdown timeout');
    process.exit(1);
  }, 5000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
