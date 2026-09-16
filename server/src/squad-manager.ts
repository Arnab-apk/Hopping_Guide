import { WebSocket } from 'ws';
import Redis from 'ioredis';
import {
  MemberConnection,
  SquadMetadata,
  SquadRoom,
  SquadMemberDTO,
} from './types';

export class SquadManager {
  private squads = new Map<string, SquadRoom>();
  private userSquadMap = new Map<string, string>(); // userId -> squadCode
  private userConnectionMap = new Map<string, WebSocket>(); // userId -> ws

  private redisPub: Redis | null = null;
  private redisSub: Redis | null = null;
  private isRedisEnabled = false;

  constructor() {
    this.initRedis();
  }

  private initRedis(): void {
    const redisUrl = process.env.REDIS_URL;
    if (redisUrl) {
      try {
        console.log('[SquadManager] Connecting to Redis at', redisUrl);
        this.redisPub = new Redis(redisUrl);
        this.redisSub = new Redis(redisUrl);

        this.redisSub.psubscribe('squad:*', (err) => {
          if (err) {
            console.error('[SquadManager] Redis psubscribe error:', err);
          } else {
            console.log('[SquadManager] Subscribed to Redis channel squad:*');
            this.isRedisEnabled = true;
          }
        });

        this.redisSub.on('pmessage', (_pattern, channel, messageStr) => {
          try {
            const squadCode = channel.replace('squad:', '');
            const parsed = JSON.parse(messageStr);
            this.broadcastLocally(squadCode, parsed.payload, parsed.originUserId);
          } catch (e) {
            console.error('[SquadManager] Redis pmessage error:', e);
          }
        });
      } catch (e) {
        console.warn('[SquadManager] Redis init failed, falling back to in-memory mode:', e);
        this.isRedisEnabled = false;
      }
    } else {
      console.log('[SquadManager] Running in pure In-Memory mode (zero config, ultra-fast RAM broadcast)');
    }
  }

  public registerConnection(userId: string, ws: WebSocket): void {
    this.userConnectionMap.set(userId, ws);
  }

  public hasSquad(code: string): boolean {
    return this.squads.has(code);
  }

  public getSquad(code: string): SquadRoom | undefined {
    return this.squads.get(code);
  }

  public getSquadForUser(userId: string): SquadRoom | undefined {
    const code = this.userSquadMap.get(userId);
    return code ? this.squads.get(code) : undefined;
  }

  public createSquad(
    code: string,
    hostUserId: string,
    hostName: string,
    initialLat: number,
    initialLng: number,
    ws: WebSocket,
    photoUrl?: string
  ): SquadRoom {
    const now = Date.now();
    const metadata: SquadMetadata = {
      code,
      name: `Squad ${code}`,
      meetupPointName: 'Designated Meet-up Landmark',
      meetupLat: initialLat,
      meetupLng: initialLng,
      createdAt: now,
      updatedAt: now,
    };

    const hostMember: MemberConnection = {
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

    const room: SquadRoom = {
      metadata,
      members: new Map([[hostUserId, hostMember]]),
    };

    this.squads.set(code, room);
    this.userSquadMap.set(hostUserId, code);
    console.log(`[SquadManager] Created squad ${code} with host ${hostUserId}`);
    return room;
  }

  public joinSquad(
    code: string,
    userId: string,
    userName: string,
    initialLat: number,
    initialLng: number,
    ws: WebSocket,
    photoUrl?: string
  ): SquadRoom | null {
    const room = this.squads.get(code);
    if (!room) return null;

    const now = Date.now();
    const member: MemberConnection = {
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

  public getMemberListDTO(code: string): SquadMemberDTO[] {
    const room = this.squads.get(code);
    if (!room) return [];

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

  public updateMemberLocation(
    code: string,
    userId: string,
    lat: number,
    lng: number,
    status?: string,
    batteryLevel?: number,
    photoUrl?: string
  ): boolean {
    const room = this.squads.get(code);
    if (!room) return false;

    const member = room.members.get(userId);
    if (!member) return false;

    member.latitude = lat;
    member.longitude = lng;
    member.lastSeen = Date.now();
    if (status !== undefined) member.status = status;
    if (batteryLevel !== undefined) member.batteryLevel = batteryLevel;
    if (photoUrl !== undefined) member.photoUrl = photoUrl;

    return true;
  }

  public updateMetadata(
    code: string,
    partial: { name?: string; meetup_name?: string; meetup_lat?: number; meetup_lng?: number }
  ): SquadMetadata | null {
    const room = this.squads.get(code);
    if (!room) return null;

    if (partial.name) room.metadata.name = partial.name;
    if (partial.meetup_name) room.metadata.meetupPointName = partial.meetup_name;
    if (partial.meetup_lat !== undefined) room.metadata.meetupLat = partial.meetup_lat;
    if (partial.meetup_lng !== undefined) room.metadata.meetupLng = partial.meetup_lng;
    room.metadata.updatedAt = Date.now();

    return room.metadata;
  }

  public leaveSquad(code: string, userId: string): boolean {
    const room = this.squads.get(code);
    if (!room) return false;

    room.members.delete(userId);
    this.userSquadMap.delete(userId);
    console.log(`[SquadManager] User ${userId} left squad ${code}`);

    if (room.members.size === 0) {
      this.squads.delete(code);
      console.log(`[SquadManager] Squad ${code} empty, room deleted`);
    }

    return true;
  }

  public handleDisconnect(userId: string): { squadCode: string; wasMember: boolean } | null {
    this.userConnectionMap.delete(userId);
    const code = this.userSquadMap.get(userId);
    if (!code) return null;

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

  public broadcast(squadCode: string, payload: any, originUserId?: string): void {
    if (this.isRedisEnabled && this.redisPub) {
      this.redisPub.publish(
        `squad:${squadCode}`,
        JSON.stringify({ payload, originUserId })
      );
    } else {
      this.broadcastLocally(squadCode, payload, originUserId);
    }
  }

  private broadcastLocally(squadCode: string, payload: any, originUserId?: string): void {
    const room = this.squads.get(squadCode);
    if (!room) return;

    const data = JSON.stringify(payload);
    for (const [memberId, member] of room.members.entries()) {
      if (originUserId && memberId === originUserId) {
        continue;
      }
      if (member.websocket.readyState === WebSocket.OPEN) {
        member.websocket.send(data);
      }
    }
  }

  public getStats() {
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
