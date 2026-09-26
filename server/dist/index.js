"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const http_1 = __importDefault(require("http"));
const url_1 = require("url");
const ws_1 = require("ws");
const dotenv_1 = __importDefault(require("dotenv"));
const firebase_admin_1 = require("firebase-admin");
const auth_1 = require("firebase-admin/auth");
const squad_manager_1 = require("./squad-manager");
const db = __importStar(require("./db"));
const handlers_1 = require("./handlers");
const uuid_1 = require("uuid");
dotenv_1.default.config();
const PORT = parseInt(process.env.PORT || '8080', 10);
const HOST = process.env.HOST || '0.0.0.0';
const manager = new squad_manager_1.SquadManager();
// --- Firebase Admin SDK Initialization ---
let firebaseApp = null;
try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
        // Initialize from service account JSON (production)
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
        firebaseApp = (0, firebase_admin_1.initializeApp)({
            credential: (0, firebase_admin_1.cert)(serviceAccount),
        });
        console.log('[Server] Firebase Admin SDK initialized with service account');
    }
    else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
        // Initialize from file path (Cloud Run, Cloud Functions, etc.)
        firebaseApp = (0, firebase_admin_1.initializeApp)({
            credential: (0, firebase_admin_1.applicationDefault)(),
        });
        console.log('[Server] Firebase Admin SDK initialized with ADC');
    }
    else {
        // Initialize without credentials (emulator / local dev)
        firebaseApp = (0, firebase_admin_1.initializeApp)({ projectId: process.env.FIREBASE_PROJECT_ID || 'demo-project' });
        console.log('[Server] Firebase Admin SDK initialized in emulator mode');
    }
}
catch (err) {
    console.error('[Server] Failed to initialize Firebase Admin SDK:', err.message);
    firebaseApp = null;
}
const authInstance = firebaseApp ? (0, auth_1.getAuth)(firebaseApp) : null;
// Simple in-memory Firebase token cache (validated tokens only)
const firebaseTokenCache = new Map();
async function verifyFirebaseToken(token) {
    // Check cache first
    const cached = firebaseTokenCache.get(token);
    if (cached && cached.expires > Date.now()) {
        return cached.uid;
    }
    if (!authInstance) {
        console.warn('[Server] Firebase Admin SDK not available, token verification skipped');
        return null;
    }
    try {
        const decoded = await authInstance.verifyIdToken(token, true); // checkRevoked = true
        const uid = decoded.uid;
        firebaseTokenCache.set(token, { uid, expires: Date.now() + 3600000 }); // 1 hour cache
        return uid;
    }
    catch (err) {
        console.warn('[Server] Invalid Firebase ID token:', err.code || err.message);
        return null;
    }
}
function extractUserId(req) {
    const authHeader = req.headers['authorization'];
    if (authHeader && authHeader.startsWith('Bearer ')) {
        const token = authHeader.slice(7).trim();
        // This will be async in real implementation; for sync compat, return token as fallback
        return token;
    }
    const customHeader = req.headers['x-user-id'];
    if (customHeader && typeof customHeader === 'string') {
        return customHeader.trim();
    }
    return `guest_${Math.random().toString(36).substring(2, 9)}`;
}
async function extractUserIdAsync(req) {
    const authHeader = req.headers['authorization'];
    if (authHeader && authHeader.startsWith('Bearer ')) {
        const token = authHeader.slice(7).trim();
        const uid = await verifyFirebaseToken(token);
        if (uid)
            return uid;
    }
    const customHeader = req.headers['x-user-id'];
    if (customHeader && typeof customHeader === 'string') {
        return customHeader.trim();
    }
    return `guest_${Math.random().toString(36).substring(2, 9)}`;
}
// --- Security: Rate Limiting & Helmet-style headers ---
// Simple in-memory rate limiter (per IP)
const httpRateLimiter = new Map();
const RATE_LIMIT_WINDOW_MS = 60000; // 1 minute
const RATE_LIMIT_MAX_REQUESTS = 100; // 100 requests per minute per IP
function checkHttpRateLimit(ip) {
    const now = Date.now();
    const entry = httpRateLimiter.get(ip);
    if (!entry || now > entry.resetTime) {
        httpRateLimiter.set(ip, { count: 1, resetTime: now + RATE_LIMIT_WINDOW_MS });
        return true;
    }
    if (entry.count >= RATE_LIMIT_MAX_REQUESTS) {
        return false;
    }
    entry.count++;
    return true;
}
// Clean up old rate limit entries periodically
setInterval(() => {
    const now = Date.now();
    for (const [ip, entry] of httpRateLimiter.entries()) {
        if (now > entry.resetTime) {
            httpRateLimiter.delete(ip);
        }
    }
}, 300000); // every 5 minutes
// Helper to parse JSON body
function parseBody(req) {
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
            }
            catch (err) {
                reject(err);
            }
        });
        req.on('error', reject);
    });
}
function sendHttpJson(res, statusCode, data) {
    res.writeHead(statusCode, {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': process.env.ALLOWED_ORIGIN || 'https://sharodiya.com',
        'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-user-id',
    });
    res.end(JSON.stringify(data));
}
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// HTTP Server (Health, Stats & Neon REST API)
// ------------------------------------------------------------------------------
const server = http_1.default.createServer(async (req, res) => {
    // Rate limiting
    const ip = req.socket.remoteAddress || 'unknown';
    if (!checkHttpRateLimit(ip)) {
        res.writeHead(429, {
            'Content-Type': 'application/json',
            'Retry-After': '60',
        });
        res.end(JSON.stringify({ error: { code: 'RATE_LIMITED', message: 'Too many requests, please slow down' } }));
        return;
    }
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        res.writeHead(204, {
            'Access-Control-Allow-Origin': process.env.ALLOWED_ORIGIN || 'https://sharodiya.com',
            'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-user-id',
        });
        res.end();
        return;
    }
    const reqUrl = req.url || '/';
    const parsed = new url_1.URL(reqUrl, `http://${req.headers.host || 'localhost'}`);
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
            const userId = body.hostUserId || await extractUserIdAsync(req);
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
            const userId = body.userId || await extractUserIdAsync(req);
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
            const userId = body.userId || await extractUserIdAsync(req);
            await db.leaveSquad(id, userId);
            sendHttpJson(res, 200, { success: true });
            return;
        }
        // PATCH /api/squads/:id/meetup
        const meetupMatch = pathname.match(/^\/api\/squads\/([a-zA-Z0-9_-]+)\/meetup$/);
        if (meetupMatch && method === 'PATCH') {
            const id = meetupMatch[1];
            const body = await parseBody(req);
            const hostUserId = body.hostUserId || await extractUserIdAsync(req);
            const squad = await db.updateMeetup(id, hostUserId, {
                lat: body.lat,
                lng: body.lng,
                label: body.label || 'Meetup Point',
            });
            // Broadcast meetup change to squad
            (0, handlers_1.broadcastToSquad)(id, {
                type: 'meetup_changed',
                eventId: (0, uuid_1.v4)(),
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
            const hostUserId = body.hostUserId || await extractUserIdAsync(req);
            const squad = await db.updateSettings(id, hostUserId, {
                name: body.name,
                separationRadiusM: body.separationRadiusM,
            });
            if (body.separationRadiusM != null) {
                (0, handlers_1.broadcastToSquad)(id, {
                    type: 'radius_changed',
                    eventId: (0, uuid_1.v4)(),
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
            const userId = body.senderUserId || await extractUserIdAsync(req);
            const saved = await db.saveMessage({
                squadId: id,
                senderUserId: userId,
                message: body.message,
                messageType: body.messageType || 'text',
                mediaUrl: body.mediaUrl,
            });
            // Broadcast chat message
            (0, handlers_1.broadcastToSquad)(id, {
                type: 'chat_message',
                eventId: (0, uuid_1.v4)(),
                squadId: id,
                senderId: userId,
                timestamp: saved.created_at,
                payload: saved,
            }, userId);
            sendHttpJson(res, 201, saved);
            return;
        }
        // 404 Not Found
        sendHttpJson(res, 404, { error: { code: 'NOT_FOUND', message: 'Endpoint not found' } });
    }
    catch (err) {
        console.error('[Server] HTTP Error:', err);
        sendHttpJson(res, 500, { error: { code: 'INTERNAL_ERROR', message: err.message || 'Internal server error' } });
    }
});
// ------------------------------------------------------------------------------
// WebSocket Server (Realtime Presence, GPS Fan-out, Separation Alerts, Chat)
// ------------------------------------------------------------------------------
const wss = new ws_1.WebSocketServer({ noServer: true });
server.on('upgrade', (request, socket, head) => {
    const reqUrl = request.url || '/';
    const parsed = new url_1.URL(reqUrl, `http://${request.headers.host || 'localhost'}`);
    if (parsed.pathname !== '/squad' && parsed.pathname !== '/ws') {
        socket.write('HTTP/1.1 404 Not Found\r\n\r\n');
        socket.destroy();
        return;
    }
    // Extract auth/user token & squad ID
    const token = parsed.searchParams.get('token') || parsed.searchParams.get('userId');
    const squadId = parsed.searchParams.get('squadId') || '';
    const userId = token ? token.trim() : `guest_${Math.random().toString(36).substring(2, 9)}`;
    if (!squadId) {
        socket.write('HTTP/1.1 400 Bad Request\r\nContent-Type: application/json\r\n\r\n{"error":"squadId required"}');
        socket.destroy();
        return;
    }
    wss.handleUpgrade(request, socket, head, (ws) => {
        wss.emit('connection', ws, request, userId, squadId);
    });
});
wss.on('connection', (ws, _request, userId, squadId) => {
    console.log(`[Server] WebSocket connected for user: ${userId} (squad: ${squadId || 'unassigned'})`);
    manager.registerConnection(userId, ws);
    if (squadId) {
        (0, handlers_1.subscribeToSquadChannel)(squadId, userId, ws);
        // Broadcast member presence online
        (0, handlers_1.broadcastToSquad)(squadId, {
            type: 'presence',
            eventId: (0, uuid_1.v4)(),
            squadId,
            senderId: userId,
            timestamp: new Date().toISOString(),
            payload: { state: 'online' },
        });
    }
    // Send connection ack
    (0, handlers_1.sendJson)(ws, {
        type: 'connection_established',
        user_id: userId,
        squad_id: squadId,
        server_timestamp: Date.now(),
    });
    ws.on('message', (data) => {
        (0, handlers_1.handleClientMessage)(ws, userId, data.toString(), manager, squadId);
    });
    ws.on('error', (err) => {
        console.error(`[Server] WebSocket Error for user ${userId}:`, err);
    });
    ws.on('close', (code, reason) => {
        console.log(`[Server] Connection closed for user ${userId} (code: ${code}, reason: ${reason.toString()})`);
        if (squadId) {
            (0, handlers_1.unsubscribeFromSquadChannel)(squadId, userId);
            // Broadcast member presence offline
            (0, handlers_1.broadcastToSquad)(squadId, {
                type: 'presence',
                eventId: (0, uuid_1.v4)(),
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
function shutdown(signal) {
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
