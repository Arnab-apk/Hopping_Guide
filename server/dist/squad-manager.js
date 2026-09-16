"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SquadManager = void 0;
const ws_1 = require("ws");
const ioredis_1 = __importDefault(require("ioredis"));
class SquadManager {
    squads = new Map();
    userSquadMap = new Map(); // userId -> squadCode
    userConnectionMap = new Map(); // userId -> ws
    redisPub = null;
    redisSub = null;
    isRedisEnabled = false;
    constructor() {
        this.initRedis();
    }
    initRedis() {
        const redisUrl = process.env.REDIS_URL;
        if (redisUrl) {
            try {
                console.log('[SquadManager] Connecting to Redis at', redisUrl);
                this.redisPub = new ioredis_1.default(redisUrl);
                this.redisSub = new ioredis_1.default(redisUrl);
                this.redisSub.psubscribe('squad:*', (err) => {
                    if (err) {
                        console.error('[SquadManager] Redis psubscribe error:', err);
                    }
                    else {
                        console.log('[SquadManager] Subscribed to Redis channel squad:*');
                        this.isRedisEnabled = true;
                    }
                });
                this.redisSub.on('pmessage', (_pattern, channel, messageStr) => {
                    try {
                        const squadCode = channel.replace('squad:', '');
                        const parsed = JSON.parse(messageStr);
                        this.broadcastLocally(squadCode, parsed.payload, parsed.originUserId);
                    }
                    catch (e) {
                        console.error('[SquadManager] Redis pmessage error:', e);
                    }
                });
            }
            catch (e) {
                console.warn('[SquadManager] Redis init failed, falling back to in-memory mode:', e);
                this.isRedisEnabled = false;
            }
        }
        else {
            console.log('[SquadManager] Running in pure In-Memory mode (zero config, ultra-fast RAM broadcast)');
        }
    }
    registerConnection(userId, ws) {
        this.userConnectionMap.set(userId, ws);
    }
    hasSquad(code) {
        return this.squads.has(code);
    }
    getSquad(code) {
        return this.squads.get(code);
    }
    getSquadForUser(userId) {
        const code = this.userSquadMap.get(userId);
        return code ? this.squads.get(code) : undefined;
    }
    createSquad(code, hostUserId, hostName, initialLat, initialLng, ws, photoUrl) {
        const now = Date.now();
        const metadata = {
            code,
            name: `Squad ${code}`,
            meetupPointName: 'Designated Meet-up Landmark',
            meetupLat: initialLat,
            meetupLng: initialLng,
            createdAt: now,
            updatedAt: now,
        };
        const hostMember = {
            userId: hostUserId,
            userName: hostName,
            photoUrl,
            isHost: true,
            latitude: initialLat,
            longitude: initialLng,
            status: 'Active',
            batteryLevel: 100,
            lastSeen: now,
            websocket: ws,
        };
        const room = {
            metadata,
            members: new Map([[hostUserId, hostMember]]),
        };
        this.squads.set(code, room);
        this.userSquadMap.set(hostUserId, code);
        console.log(`[SquadManager] Created squad ${code} with host ${hostUserId}`);
        return room;
    }
    joinSquad(code, userId, userName, initialLat, initialLng, ws, photoUrl) {
        const room = this.squads.get(code);
        if (!room)
            return null;
        const now = Date.now();
        const member = {
            userId,
            userName,
            photoUrl,
            isHost: false,
            latitude: initialLat,
            longitude: initialLng,
            status: 'Active',
            batteryLevel: 100,
            lastSeen: now,
            websocket: ws,
        };
        room.members.set(userId, member);
        this.userSquadMap.set(userId, code);
        console.log(`[SquadManager] User ${userId} joined squad ${code}`);
        return room;
    }
    getMemberListDTO(code) {
        const room = this.squads.get(code);
        if (!room)
            return [];
        return Array.from(room.members.values()).map((m) => ({
            member_id: m.userId,
            member_name: m.userName,
            photo_url: m.photoUrl,
            is_host: m.isHost,
            latitude: m.latitude,
            longitude: m.longitude,
            status: m.status,
            battery_level: m.batteryLevel,
            last_seen: m.lastSeen,
        }));
    }
    updateMemberLocation(code, userId, lat, lng, status, batteryLevel, photoUrl) {
        const room = this.squads.get(code);
        if (!room)
            return false;
        const member = room.members.get(userId);
        if (!member)
            return false;
        member.latitude = lat;
        member.longitude = lng;
        member.lastSeen = Date.now();
        if (status !== undefined)
            member.status = status;
        if (batteryLevel !== undefined)
            member.batteryLevel = batteryLevel;
        if (photoUrl !== undefined)
            member.photoUrl = photoUrl;
        return true;
    }
    updateMetadata(code, partial) {
        const room = this.squads.get(code);
        if (!room)
            return null;
        if (partial.name)
            room.metadata.name = partial.name;
        if (partial.meetup_name)
            room.metadata.meetupPointName = partial.meetup_name;
        if (partial.meetup_lat !== undefined)
            room.metadata.meetupLat = partial.meetup_lat;
        if (partial.meetup_lng !== undefined)
            room.metadata.meetupLng = partial.meetup_lng;
        room.metadata.updatedAt = Date.now();
        return room.metadata;
    }
    leaveSquad(code, userId) {
        const room = this.squads.get(code);
        if (!room)
            return false;
        room.members.delete(userId);
        this.userSquadMap.delete(userId);
        console.log(`[SquadManager] User ${userId} left squad ${code}`);
        if (room.members.size === 0) {
            this.squads.delete(code);
            console.log(`[SquadManager] Squad ${code} empty, room deleted`);
        }
        return true;
    }
    handleDisconnect(userId) {
        this.userConnectionMap.delete(userId);
        const code = this.userSquadMap.get(userId);
        if (!code)
            return null;
        const room = this.squads.get(code);
        if (!room) {
            this.userSquadMap.delete(userId);
            return null;
        }
        room.members.delete(userId);
        this.userSquadMap.delete(userId);
        console.log(`[SquadManager] Disconnected user ${userId} removed from squad ${code}`);
        if (room.members.size === 0) {
            this.squads.delete(code);
            console.log(`[SquadManager] Squad ${code} deleted after disconnect`);
        }
        return { squadCode: code, wasMember: true };
    }
    broadcast(squadCode, payload, originUserId) {
        if (this.isRedisEnabled && this.redisPub) {
            this.redisPub.publish(`squad:${squadCode}`, JSON.stringify({ payload, originUserId }));
        }
        else {
            this.broadcastLocally(squadCode, payload, originUserId);
        }
    }
    broadcastLocally(squadCode, payload, originUserId) {
        const room = this.squads.get(squadCode);
        if (!room)
            return;
        const data = JSON.stringify(payload);
        for (const [memberId, member] of room.members.entries()) {
            if (originUserId && memberId === originUserId) {
                continue;
            }
            if (member.websocket.readyState === ws_1.WebSocket.OPEN) {
                member.websocket.send(data);
            }
        }
    }
    getStats() {
        let totalMembers = 0;
        for (const s of this.squads.values()) {
            totalMembers += s.members.size;
        }
        return {
            activeSquads: this.squads.size,
            connectedMembers: totalMembers,
            totalConnections: this.userConnectionMap.size,
            redisEnabled: this.isRedisEnabled,
        };
    }
}
exports.SquadManager = SquadManager;
