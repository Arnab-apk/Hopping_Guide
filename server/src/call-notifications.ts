import { IncomingMessage, ServerResponse } from 'http';
import { App } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

export function validInvitation(data: any, uid: string, id: string, now = Date.now()): boolean {
  const sent = data?.callSentAt?.toMillis?.();
  return data?.senderId === uid && data?.callEvent === 'invite' &&
    data?.callInvitationId === id && typeof sent === 'number' &&
    sent <= now + 10000 && sent + 60000 > now;
}

export async function notifyGroupCall(req: IncomingMessage, res: ServerResponse,
  groupId: string, invitationId: string, app: App | null,
  send: (res: ServerResponse, status: number, data: unknown) => void, ending = false): Promise<void> {
  res.setHeader('Cache-Control', 'no-store');
  if (!/^[\w-]{1,128}$/.test(groupId) || !/^[\w-]{1,128}$/.test(invitationId)) {
    send(res, 400, { error: 'Invalid invitation' }); return;
  }
  if (!app) { send(res, 503, { error: 'Authentication unavailable' }); return; }
  let uid: string;
  try {
    const bearer = req.headers.authorization?.match(/^Bearer (\S+)$/)?.[1];
    if (!bearer) throw new Error('Missing token');
    uid = (await getAuth(app).verifyIdToken(bearer, true)).uid;
  } catch { send(res, 401, { error: 'Sign in required' }); return; }
  try {
    const db = getFirestore(app);
    const group = db.collection('squads').doc(groupId);
    const invitation = group.collection('messages').doc(invitationId);
    const roster = (await group.get()).data();
    if (roster?.status === 'closed' || !roster?.membersUid?.includes(uid)) {
      send(res, 403, { error: 'Group membership required' }); return;
    }
    const data = (await invitation.get()).data();
    const end = (await group.collection('messages').doc(`${invitationId}_ended`).get()).data();
    const hasEnded = end?.senderId === uid && end?.callEvent === 'end' && end?.callInvitationId === invitationId;
    if (!validInvitation(data, uid, invitationId) || (ending ? !hasEnded : hasEnded)) {
      send(res, 409, { error: 'Invitation expired or ended' }); return;
    }
    // The server owns this receipt. Retries cannot repeatedly ring every device.
    const receipt = group.collection('callPushReceipts').doc(ending ? `${invitationId}_ended` : invitationId);
    const reserved = await db.runTransaction(async tx => {
      if ((await tx.get(receipt)).exists) return false;
      tx.create(receipt, { senderId: uid, sentAt: FieldValue.serverTimestamp() });
      return true;
    });
    if (!reserved) { send(res, 200, { notified: 0, duplicate: true }); return; }
    const members = await group.collection('members').get();
    const tokens = new Set<string>();
    const ringTokens = new Set<string>();
    for (const member of members.docs) {
      if (member.id === uid || !roster.membersUid.includes(member.id)) continue;
      const registered = member.data().callPushTokens;
      const ringing = member.data().callRingTokens;
      if (Array.isArray(registered)) {
        for (const token of registered.slice(-5)) {
          if (typeof token === 'string' && token.length > 20 && token.length < 4096) {
            if (Array.isArray(ringing) && ringing.includes(token)) ringTokens.add(token);
            else if (!ending) tokens.add(token);
          }
        }
      }
    }
    const caller = (await getAuth(app).getUser(uid)).displayName || 'A group member';
    const expiresAt = String(data!.callSentAt.toMillis() + 60000);
    // Updated Android clients render a looping call notification themselves.
    // Keep ordinary notifications for clients that have not upgraded yet.
    for (const token of ringTokens) tokens.delete(token);
    const all = [...tokens];
    let notified = 0;
    for (let i = 0; i < all.length; i += 500) {
      const result = await getMessaging(app).sendEachForMulticast({
        tokens: all.slice(i, i + 500),
        notification: { title: 'Incoming group call', body: `${caller} is calling ${roster.name || 'your group'}. Tap to answer.` },
        data: { type: 'group_call', groupId, invitationId, expiresAt },
        android: { priority: 'high', ttl: Math.max(0, Number(expiresAt) - Date.now()),
          notification: { channelId: 'uma_incoming_calls', tag: invitationId,
            sound: 'default', priority: 'max', visibility: 'private', defaultVibrateTimings: true } },
      });
      notified += result.successCount;
    }
    const ringing = [...ringTokens];
    for (let i = 0; i < ringing.length; i += 500) {
      const result = await getMessaging(app).sendEachForMulticast({
        tokens: ringing.slice(i, i + 500),
        data: { type: ending ? 'group_call_end' : 'group_call_ring', groupId, invitationId,
          expiresAt, callerName: caller, groupName: roster.name || 'your group' },
        android: { priority: 'high', ttl: Math.max(0, Number(expiresAt) - Date.now()) },
      });
      notified += result.successCount;
    }
    send(res, 200, { notified });
  } catch {
    send(res, 503, { error: 'Call notifications unavailable' });
  }
}
