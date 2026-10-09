import { IncomingMessage, ServerResponse } from 'http';
import { createHash } from 'crypto';
import { StreamClient } from '@stream-io/node-sdk';
import { App } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

export const CALL_TYPE = 'uma_squad';
export const TOKEN_TTL = 300;
let streamClient: StreamClient | undefined;
let setup: Promise<void> | undefined;

function client(): StreamClient {
  if (!process.env.STREAM_API_KEY || !process.env.STREAM_API_SECRET) {
    throw new Error('Video calling is not configured on the server.');
  }
  return streamClient ??= new StreamClient(process.env.STREAM_API_KEY, process.env.STREAM_API_SECRET);
}

// Tokens grant membership only for one call. Never persist membership in Stream:
// renewal must pass the current Firestore membership check again.
export async function ensurePrivateCallType(): Promise<void> {
  if (!setup) {
    setup = (async () => {
      const video = client().video;
      const grants = {
        user: [], guest: [], anonymous: [],
        call_member: ['read-call', 'join-call', 'send-audio', 'send-video'],
      };
      const types = await video.listCallTypes();
      if (types.call_types[CALL_TYPE]) {
        await video.updateCallType({ name: CALL_TYPE, grants });
      } else {
        await video.createCallType({ name: CALL_TYPE, grants });
      }
    })().catch(error => { setup = undefined; throw error; });
  }
  await setup;
}

export function squadCallId(squadId: string, createdAt: string): string {
  return `squad_${createHash('sha256').update(`${squadId}:${createdAt}`).digest('hex').slice(0, 40)}`;
}

export function isSquadMember(data: Record<string, unknown> | undefined, uid: string): boolean {
  return !!data && data.status !== 'closed' && Array.isArray(data.membersUid) && data.membersUid.includes(uid);
}

export async function handleVideoRequest(
  req: IncomingMessage, res: ServerResponse, squadId: string, app: App | null,
  send: (res: ServerResponse, status: number, data: unknown) => void,
): Promise<void> {
  res.setHeader('Cache-Control', 'no-store');
  const fail = (status: number, code: string, message: string) => send(res, status, { error: { code, message } });
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(squadId)) {
    fail(400, 'INVALID_GROUP', 'Invalid group.'); return;
  }
  if (!app) { fail(503, 'AUTH_UNAVAILABLE', 'Sign-in verification is unavailable.'); return; }
  const bearer = req.headers.authorization?.match(/^Bearer (\S+)$/)?.[1];
  if (!bearer) { fail(401, 'AUTH_REQUIRED', 'Sign in to join a group call.'); return; }
  let uid: string;
  try {
    // Deliberately bypass the legacy API's x-user-id and cached-token fallbacks.
    uid = (await getAuth(app).verifyIdToken(bearer, true)).uid;
  } catch {
    fail(401, 'AUTH_REQUIRED', 'Your sign-in expired. Sign in again.'); return;
  }
  try {
    const squad = await getFirestore(app).collection('squads').doc(squadId).get();
    const data = squad.data();
    if (!isSquadMember(data, uid)) {
      fail(403, 'NOT_A_MEMBER', 'Only current group members can join this call.'); return;
    }
    if (!process.env.STREAM_API_KEY || !process.env.STREAM_API_SECRET) {
      fail(503, 'VIDEO_NOT_CONFIGURED', 'Video calling is not configured on the server.'); return;
    }
    await ensurePrivateCallType();
    // Firestore creation time distinguishes groups even if an invite code is reused.
    const callId = squadCallId(squadId, squad.createTime!.toMillis().toString());
    const user = await getAuth(app).getUser(uid);
    await client().upsertUsers([{ id: uid, role: 'user', name: user.displayName || 'Group member' }]);
    await client().video.call(CALL_TYPE, callId).getOrCreate({
      data: { created_by_id: uid, custom: { squad_id: squadId, title: data!.name || 'Group video call' } },
    });
    send(res, 200, {
      apiKey: process.env.STREAM_API_KEY, userId: uid, callType: CALL_TYPE, callId,
      token: client().generateCallToken({ user_id: uid, call_cids: [`${CALL_TYPE}:${callId}`], validity_in_seconds: TOKEN_TTL }),
      expiresIn: TOKEN_TTL,
    });
  } catch {
    // Never expose upstream responses, tokens or credentials in logs/errors.
    fail(503, 'VIDEO_UNAVAILABLE', 'Could not connect to group calling. Please try again.');
  }
}
