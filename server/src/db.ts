import { Pool, PoolClient } from 'pg';
import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';

// Environment variables
const DATABASE_URL = process.env.DATABASE_URL;

// Database pool if DATABASE_URL is set
let pool: Pool | null = null;

if (DATABASE_URL) {
  console.log('[Database] Initializing Neon PostgreSQL pool connection...');
  pool = new Pool({
    connectionString: DATABASE_URL,
    ssl: { rejectUnauthorized: false }, // Standard for Neon Postgres SSL
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
  });

  pool.on('error', (err) => {
    console.error('[Database] Unexpected error on idle Neon client:', err);
  });
} else {
  console.log('[Database] No DATABASE_URL provided. Running with in-memory Neon-compatible persistence store.');
}

// ------------------------------------------------------------------------------
// Cryptographically secure squad code generator
// Format: PUJAXXXX (8 chars total, avoiding ambiguous characters 0, O, 1, I, L)
// Matches Flutter app expectation: PUJA + 4 alphanumeric chars
// ------------------------------------------------------------------------------
const SAFE_CHARS = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

export function generateSquadCode(): string {
  const bytes = crypto.randomBytes(4);
  let code = 'PUJA';
  for (let i = 0; i < 4; i++) {
    code += SAFE_CHARS[bytes[i] % SAFE_CHARS.length];
  }
  return code;
}

// ------------------------------------------------------------------------------
// In-Memory Fallback Data Store (Mirroring Neon Postgres Relational Tables)
// ------------------------------------------------------------------------------
interface ProfileRow {
  user_id: string;
  display_name: string;
  avatar_url?: string;
  is_guest: boolean;
  created_at: string;
  updated_at: string;
}

interface SquadRow {
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

interface MemberRow {
  squad_id: string;
  user_id: string;
  role: 'host' | 'member';
  share_location: boolean;
  joined_at: string;
  last_seen_at: string;
}

interface LocationRow {
  squad_id: string;
  user_id: string;
  latitude: number;
  longitude: number;
  accuracy_m?: number;
  heading_deg?: number;
  speed_mps?: number;
  updated_at: string;
}

interface MessageRow {
  id: string;
  squad_id: string;
  sender_user_id: string;
  message_type: 'text' | 'image' | 'location' | 'system';
  message: string | null;
  media_url: string | null;
  created_at: string;
}

interface EventRow {
  id: string;
  squad_id: string;
  actor_user_id: string | null;
  event_type: string;
  payload: any;
  created_at: string;
}

class InMemoryNeonStore {
  profiles = new Map<string, ProfileRow>();
  squads = new Map<string, SquadRow>(); // id -> SquadRow
  squadCodeMap = new Map<string, string>(); // code -> id
  members = new Map<string, Map<string, MemberRow>>(); // squad_id -> (user_id -> MemberRow)
  locations = new Map<string, Map<string, LocationRow>>(); // squad_id -> (user_id -> LocationRow)
  messages = new Map<string, MessageRow[]>(); // squad_id -> MessageRow[]
  events = new Map<string, EventRow[]>(); // squad_id -> EventRow[]
}

const memStore = new InMemoryNeonStore();

// ------------------------------------------------------------------------------
// Database Operations Facade
// ------------------------------------------------------------------------------

export async function upsertProfile(
  userId: string,
  displayName: string,
  avatarUrl?: string,
  isGuest = true
): Promise<ProfileRow> {
  const now = new Date().toISOString();
  if (pool) {
    const res = await pool.query(
      `INSERT INTO profiles (user_id, display_name, avatar_url, is_guest, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $5)
       ON CONFLICT (user_id) DO UPDATE
       SET display_name = EXCLUDED.display_name,
           avatar_url = COALESCE(EXCLUDED.avatar_url, profiles.avatar_url),
           is_guest = EXCLUDED.is_guest,
           updated_at = EXCLUDED.updated_at
       RETURNING *;`,
      [userId, displayName, avatarUrl || null, isGuest, now]
    );
    return res.rows[0];
  }

  const existing = memStore.profiles.get(userId);
  const row: ProfileRow = {
    user_id: userId,
    display_name: displayName,
    avatar_url: avatarUrl || existing?.avatar_url,
    is_guest: isGuest,
    created_at: existing?.created_at || now,
    updated_at: now,
  };
  memStore.profiles.set(userId, row);
  return row;
}

export async function createSquad(params: {
  name: string;
  hostUserId: string;
  meetupLat?: number;
  meetupLng?: number;
  meetupLabel?: string;
  separationRadiusM?: number;
  hostDisplayName?: string;
  hostAvatarUrl?: string;
  isGuest?: boolean;
}): Promise<{ squad: SquadRow; hostMember: MemberRow }> {
  const squadId = uuidv4();
  const code = generateSquadCode();
  const now = new Date().toISOString();
  const radius = Math.min(Math.max(params.separationRadiusM ?? 500, 50), 5000);

  if (pool) {
    const client: PoolClient = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Upsert host profile
      if (params.hostDisplayName) {
        await client.query(
          `INSERT INTO profiles (user_id, display_name, avatar_url, is_guest, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $5)
           ON CONFLICT (user_id) DO UPDATE SET display_name = EXCLUDED.display_name, updated_at = EXCLUDED.updated_at;`,
          [params.hostUserId, params.hostDisplayName, params.hostAvatarUrl || null, params.isGuest ?? true, now]
        );
      }

      // 2. Insert squad
      const squadRes = await client.query(
        `INSERT INTO squads (id, code, name, host_user_id, meetup_lat, meetup_lng, meetup_label, separation_radius_m, status, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'active', $9, $9)
         RETURNING *;`,
        [squadId, code, params.name, params.hostUserId, params.meetupLat ?? null, params.meetupLng ?? null, params.meetupLabel ?? null, radius, now]
      );

      // 3. Insert host into squad_members
      const memberRes = await client.query(
        `INSERT INTO squad_members (squad_id, user_id, role, share_location, joined_at, last_seen_at)
         VALUES ($1, $2, 'host', true, $3, $3)
         RETURNING *;`,
        [squadId, params.hostUserId, now]
      );

      // 4. Record audit event
      await client.query(
        `INSERT INTO squad_events (id, squad_id, actor_user_id, event_type, payload, created_at)
         VALUES ($1, $2, $3, 'squad_created', $4, $5);`,
        [uuidv4(), squadId, params.hostUserId, JSON.stringify({ code, name: params.name }), now]
      );

      await client.query('COMMIT');
      return { squad: squadRes.rows[0], hostMember: memberRes.rows[0] };
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  // In-memory atomic implementation
  await upsertProfile(
    params.hostUserId,
    params.hostDisplayName || 'Hopper Host',
    params.hostAvatarUrl,
    params.isGuest ?? true
  );

  const squad: SquadRow = {
    id: squadId,
    code,
    name: params.name,
    host_user_id: params.hostUserId,
    meetup_lat: params.meetupLat ?? null,
    meetup_lng: params.meetupLng ?? null,
    meetup_label: params.meetupLabel ?? null,
    separation_radius_m: radius,
    status: 'active',
    created_at: now,
    updated_at: now,
  };
  memStore.squads.set(squadId, squad);
  memStore.squadCodeMap.set(code, squadId);

  const hostMember: MemberRow = {
    squad_id: squadId,
    user_id: params.hostUserId,
    role: 'host',
    share_location: true,
    joined_at: now,
    last_seen_at: now,
  };
  const memberMap = new Map<string, MemberRow>();
  memberMap.set(params.hostUserId, hostMember);
  memStore.members.set(squadId, memberMap);

  return { squad, hostMember };
}

export async function joinSquad(params: {
  code: string;
  userId: string;
  displayName?: string;
  avatarUrl?: string;
  isGuest?: boolean;
}): Promise<{ squad: SquadRow; member: MemberRow; isNewJoin: boolean }> {
  const normCode = params.code.trim().toUpperCase();
  const now = new Date().toISOString();

  if (pool) {
    const client: PoolClient = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Find squad
      const squadRes = await client.query(
        `SELECT * FROM squads WHERE code = $1;`,
        [normCode]
      );
      if (squadRes.rows.length === 0) {
        throw new Error('SQUAD_NOT_FOUND');
      }
      const squad: SquadRow = squadRes.rows[0];
      if (squad.status !== 'active') {
        throw new Error('SQUAD_CLOSED');
      }

      // 2. Upsert profile
      if (params.displayName) {
        await client.query(
          `INSERT INTO profiles (user_id, display_name, avatar_url, is_guest, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $5)
           ON CONFLICT (user_id) DO UPDATE SET display_name = EXCLUDED.display_name, updated_at = EXCLUDED.updated_at;`,
          [params.userId, params.displayName, params.avatarUrl || null, params.isGuest ?? true, now]
        );
      }

      // 3. Check existing membership (Idempotent)
      const existingRes = await client.query(
        `SELECT * FROM squad_members WHERE squad_id = $1 AND user_id = $2;`,
        [squad.id, params.userId]
      );

      let member: MemberRow;
      let isNewJoin = false;

      if (existingRes.rows.length > 0) {
        // Update last seen
        const updateRes = await client.query(
          `UPDATE squad_members SET last_seen_at = $1 WHERE squad_id = $2 AND user_id = $3 RETURNING *;`,
          [now, squad.id, params.userId]
        );
        member = updateRes.rows[0];
      } else {
        // Insert new member
        const insertRes = await client.query(
          `INSERT INTO squad_members (squad_id, user_id, role, share_location, joined_at, last_seen_at)
           VALUES ($1, $2, 'member', true, $3, $3)
           RETURNING *;`,
          [squad.id, params.userId, now]
        );
        member = insertRes.rows[0];
        isNewJoin = true;

        // Record join event
        await client.query(
          `INSERT INTO squad_events (id, squad_id, actor_user_id, event_type, payload, created_at)
           VALUES ($1, $2, $3, 'member_joined', $4, $5);`,
          [uuidv4(), squad.id, params.userId, JSON.stringify({ displayName: params.displayName }), now]
        );
      }

      await client.query('COMMIT');
      return { squad, member, isNewJoin };
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  // In-memory implementation
  const squadId = memStore.squadCodeMap.get(normCode);
  if (!squadId) {
    throw new Error('SQUAD_NOT_FOUND');
  }
  const squad = memStore.squads.get(squadId)!;
  if (squad.status !== 'active') {
    throw new Error('SQUAD_CLOSED');
  }

  await upsertProfile(
    params.userId,
    params.displayName || 'Companion Hopper',
    params.avatarUrl,
    params.isGuest ?? true
  );

  let memberMap = memStore.members.get(squadId);
  if (!memberMap) {
    memberMap = new Map();
    memStore.members.set(squadId, memberMap);
  }

  const existing = memberMap.get(params.userId);
  if (existing) {
    existing.last_seen_at = now;
    return { squad, member: existing, isNewJoin: false };
  }

  const newMember: MemberRow = {
    squad_id: squadId,
    user_id: params.userId,
    role: 'member',
    share_location: true,
    joined_at: now,
    last_seen_at: now,
  };
  memberMap.set(params.userId, newMember);

  return { squad, member: newMember, isNewJoin: true };
}

export async function getSquadById(squadId: string): Promise<SquadRow | null> {
  if (pool) {
    const res = await pool.query(`SELECT * FROM squads WHERE id = $1;`, [squadId]);
    return res.rows[0] || null;
  }
  return memStore.squads.get(squadId) || null;
}

export async function getSquadByCode(code: string): Promise<SquadRow | null> {
  const norm = code.trim().toUpperCase();
  if (pool) {
    const res = await pool.query(`SELECT * FROM squads WHERE code = $1;`, [norm]);
    return res.rows[0] || null;
  }
  const id = memStore.squadCodeMap.get(norm);
  return id ? memStore.squads.get(id) || null : null;
}

export async function getSquadMembers(squadId: string): Promise<(MemberRow & { display_name: string; avatar_url?: string; is_guest: boolean })[]> {
  if (pool) {
    const res = await pool.query(
      `SELECT sm.*, p.display_name, p.avatar_url, p.is_guest
       FROM squad_members sm
       LEFT JOIN profiles p ON sm.user_id = p.user_id
       WHERE sm.squad_id = $1
       ORDER BY (CASE WHEN sm.role = 'host' THEN 0 ELSE 1 END), sm.joined_at ASC;`,
      [squadId]
    );
    return res.rows;
  }

  const memberMap = memStore.members.get(squadId);
  if (!memberMap) return [];
  const list: (MemberRow & { display_name: string; avatar_url?: string; is_guest: boolean })[] = [];
  for (const m of memberMap.values()) {
    const p = memStore.profiles.get(m.user_id);
    list.push({
      ...m,
      display_name: p?.display_name || 'Pujo Hopper',
      avatar_url: p?.avatar_url,
      is_guest: p?.is_guest ?? true,
    });
  }
  return list.sort((a, b) => (a.role === 'host' ? -1 : 1));
}

export async function leaveSquad(squadId: string, userId: string): Promise<{ success: boolean; closed?: boolean }> {
  if (pool) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const squadRes = await client.query(`SELECT * FROM squads WHERE id = $1;`, [squadId]);
      if (squadRes.rows.length === 0) return { success: false };
      const squad = squadRes.rows[0];

      if (squad.host_user_id === userId) {
        // If host leaves, check if other members exist
        const membersRes = await client.query(
          `SELECT * FROM squad_members WHERE squad_id = $1 AND user_id != $2 ORDER BY joined_at ASC LIMIT 1;`,
          [squadId, userId]
        );
        if (membersRes.rows.length > 0) {
          // Transfer host to oldest companion
          const newHost = membersRes.rows[0];
          await client.query(`UPDATE squads SET host_user_id = $1 WHERE id = $2;`, [newHost.user_id, squadId]);
          await client.query(`UPDATE squad_members SET role = 'host' WHERE squad_id = $1 AND user_id = $2;`, [squadId, newHost.user_id]);
        } else {
          // Close squad
          await client.query(`UPDATE squads SET status = 'closed' WHERE id = $1;`, [squadId]);
        }
      }

      await client.query(`DELETE FROM squad_members WHERE squad_id = $1 AND user_id = $2;`, [squadId, userId]);
      await client.query(`DELETE FROM squad_locations WHERE squad_id = $1 AND user_id = $2;`, [squadId, userId]);
      await client.query('COMMIT');
      return { success: true };
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  const squad = memStore.squads.get(squadId);
  if (!squad) return { success: false };
  const memberMap = memStore.members.get(squadId);
  if (memberMap) {
    memberMap.delete(userId);
    if (squad.host_user_id === userId) {
      const remaining = Array.from(memberMap.values());
      if (remaining.length > 0) {
        remaining[0].role = 'host';
        squad.host_user_id = remaining[0].user_id;
      } else {
        squad.status = 'closed';
      }
    }
  }
  const locMap = memStore.locations.get(squadId);
  if (locMap) locMap.delete(userId);
  return { success: true };
}

export async function updateMeetup(
  squadId: string,
  hostUserId: string,
  meetup: { lat: number; lng: number; label: string }
): Promise<SquadRow> {
  const now = new Date().toISOString();
  if (pool) {
    const res = await pool.query(
      `UPDATE squads
       SET meetup_lat = $1, meetup_lng = $2, meetup_label = $3, updated_at = $4
       WHERE id = $5 AND host_user_id = $6
       RETURNING *;`,
      [meetup.lat, meetup.lng, meetup.label, now, squadId, hostUserId]
    );
    if (res.rows.length === 0) throw new Error('NOT_HOST_OR_SQUAD_NOT_FOUND');
    return res.rows[0];
  }

  const squad = memStore.squads.get(squadId);
  if (!squad || squad.host_user_id !== hostUserId) throw new Error('NOT_HOST_OR_SQUAD_NOT_FOUND');
  squad.meetup_lat = meetup.lat;
  squad.meetup_lng = meetup.lng;
  squad.meetup_label = meetup.label;
  squad.updated_at = now;
  return squad;
}

export async function updateSettings(
  squadId: string,
  hostUserId: string,
  settings: { separationRadiusM?: number; name?: string }
): Promise<SquadRow> {
  const now = new Date().toISOString();
  const radius = settings.separationRadiusM
    ? Math.min(Math.max(settings.separationRadiusM, 50), 5000)
    : undefined;

  if (pool) {
    const res = await pool.query(
      `UPDATE squads
       SET separation_radius_m = COALESCE($1, separation_radius_m),
           name = COALESCE($2, name),
           updated_at = $3
       WHERE id = $4 AND host_user_id = $5
       RETURNING *;`,
      [radius ?? null, settings.name ?? null, now, squadId, hostUserId]
    );
    if (res.rows.length === 0) throw new Error('NOT_HOST_OR_SQUAD_NOT_FOUND');
    return res.rows[0];
  }

  const squad = memStore.squads.get(squadId);
  if (!squad || squad.host_user_id !== hostUserId) throw new Error('NOT_HOST_OR_SQUAD_NOT_FOUND');
  if (radius) squad.separation_radius_m = radius;
  if (settings.name) squad.name = settings.name;
  squad.updated_at = now;
  return squad;
}

export async function upsertLocation(
  squadId: string,
  userId: string,
  loc: { latitude: number; longitude: number; accuracyM?: number; headingDeg?: number; speedMps?: number }
): Promise<void> {
  const now = new Date().toISOString();
  if (pool) {
    await pool.query(
      `INSERT INTO squad_locations (squad_id, user_id, latitude, longitude, accuracy_m, heading_deg, speed_mps, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT (squad_id, user_id) DO UPDATE
       SET latitude = EXCLUDED.latitude,
           longitude = EXCLUDED.longitude,
           accuracy_m = EXCLUDED.accuracy_m,
           heading_deg = EXCLUDED.heading_deg,
           speed_mps = EXCLUDED.speed_mps,
           updated_at = EXCLUDED.updated_at;`,
      [squadId, userId, loc.latitude, loc.longitude, loc.accuracyM ?? null, loc.headingDeg ?? null, loc.speedMps ?? null, now]
    );
    return;
  }

  let locMap = memStore.locations.get(squadId);
  if (!locMap) {
    locMap = new Map();
    memStore.locations.set(squadId, locMap);
  }
  locMap.set(userId, {
    squad_id: squadId,
    user_id: userId,
    latitude: loc.latitude,
    longitude: loc.longitude,
    accuracy_m: loc.accuracyM,
    heading_deg: loc.headingDeg,
    speed_mps: loc.speedMps,
    updated_at: now,
  });
}

export async function getLatestLocations(squadId: string): Promise<LocationRow[]> {
  if (pool) {
    const res = await pool.query(
      `SELECT sl.* FROM squad_locations sl
       JOIN squad_members sm ON sl.squad_id = sm.squad_id AND sl.user_id = sm.user_id
       WHERE sl.squad_id = $1 AND sm.share_location = TRUE;`,
      [squadId]
    );
    return res.rows;
  }

  const locMap = memStore.locations.get(squadId);
  if (!locMap) return [];
  const memberMap = memStore.members.get(squadId);
  const result: LocationRow[] = [];
  for (const [uid, loc] of locMap.entries()) {
    const m = memberMap?.get(uid);
    if (m?.share_location) {
      result.push(loc);
    }
  }
  return result;
}

export async function saveMessage(params: {
  squadId: string;
  senderUserId: string;
  messageType?: 'text' | 'image' | 'location' | 'system';
  message?: string;
  mediaUrl?: string;
}): Promise<MessageRow> {
  const id = uuidv4();
  const now = new Date().toISOString();
  const msgType = params.messageType || 'text';

  if (pool) {
    const res = await pool.query(
      `INSERT INTO squad_messages (id, squad_id, sender_user_id, message_type, message, media_url, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *;`,
      [id, params.squadId, params.senderUserId, msgType, params.message || null, params.mediaUrl || null, now]
    );
    return res.rows[0];
  }

  const row: MessageRow = {
    id,
    squad_id: params.squadId,
    sender_user_id: params.senderUserId,
    message_type: msgType,
    message: params.message || null,
    media_url: params.mediaUrl || null,
    created_at: now,
  };

  let list = memStore.messages.get(params.squadId);
  if (!list) {
    list = [];
    memStore.messages.set(params.squadId, list);
  }
  list.push(row);
  return row;
}

export async function getMessages(squadId: string, limit = 50): Promise<MessageRow[]> {
  if (pool) {
    const res = await pool.query(
      `SELECT * FROM squad_messages
       WHERE squad_id = $1
       ORDER BY created_at ASC
       LIMIT $2;`,
      [squadId, limit]
    );
    return res.rows;
  }

  const list = memStore.messages.get(squadId) || [];
  return list.slice(-limit);
}
