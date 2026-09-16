"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendJson = sendJson;
exports.sendError = sendError;
exports.handleClientMessage = handleClientMessage;
const ws_1 = require("ws");
// Rate limiter: Map<userId, timestamp[]>
const rateLimiter = new Map();
function checkRateLimit(userId, maxPerSecond = 10) {
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
function sendJson(ws, payload) {
    if (ws.readyState === ws_1.WebSocket.OPEN) {
        ws.send(JSON.stringify(payload));
    }
}
function sendError(ws, code, message) {
    sendJson(ws, {
        type: 'error',
        code,
        message,
        server_timestamp: Date.now(),
    });
}
function handleClientMessage(ws, userId, rawMessage, manager) {
    let message;
    try {
        message = JSON.parse(rawMessage);
    }
    catch (e) {
        console.error(`[Handlers] JSON parse error from ${userId}:`, e);
        sendError(ws, 'MALFORMED_JSON', 'Could not parse JSON message');
        return;
    }
    if (!message.type) {
        sendError(ws, 'MISSING_TYPE', 'Message must contain a "type" field');
        return;
    }
    switch (message.type) {
        case 'join_squad':
            handleJoinSquad(ws, userId, message, manager);
            break;
        case 'location_update':
            handleLocationUpdate(ws, userId, message, manager);
            break;
        case 'squad_meta_update':
            handleSquadMetaUpdate(ws, userId, message, manager);
            break;
        case 'leave_squad':
            handleLeaveSquad(ws, userId, message, manager);
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
function handleJoinSquad(ws, userId, msg, manager) {
    const code = (msg.squad_code || '').trim().toUpperCase();
    if (!code.match(/^PUJA[A-Z0-9]{4}$/)) {
        sendError(ws, 'INVALID_CODE', 'Squad code must follow the format PUJA#### (e.g. PUJAX4K9)');
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
    }
    else {
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
        // Notify other members of new joiner
        manager.broadcast(code, {
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
        }, userId);
        // Send full roster to the joining member
        sendJson(ws, {
            type: 'member_list',
            squad_code: code,
            members: manager.getMemberListDTO(code),
            server_timestamp: Date.now(),
        });
    }
}
function handleLocationUpdate(ws, userId, msg, manager) {
    if (!checkRateLimit(userId, 10)) {
        sendError(ws, 'RATE_LIMITED', 'Too many location updates, throttled to 10/s');
        return;
    }
    const code = (msg.squad_code || '').trim().toUpperCase();
    const lat = Number(msg.latitude);
    const lng = Number(msg.longitude);
    if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        return; // Drop silently
    }
    const ok = manager.updateMemberLocation(code, userId, lat, lng, msg.status, msg.battery_level, msg.photo_url);
    if (!ok) {
        sendError(ws, 'NOT_IN_SQUAD', 'Member not registered in this squad');
        return;
    }
    // Ultra-low latency in-memory broadcast to room
    manager.broadcast(code, {
        type: 'location_update',
        squad_code: code,
        member_id: userId,
        latitude: lat,
        longitude: lng,
        status: msg.status || 'Active',
        battery_level: msg.battery_level ?? 100,
        photo_url: msg.photo_url,
        server_timestamp: Date.now(),
    }, userId // Omit echo to sender
    );
}
function handleSquadMetaUpdate(ws, _userId, msg, manager) {
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
function handleLeaveSquad(_ws, userId, msg, manager) {
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
