// Isolated QA group; only the newly registered device owner and a temporary
// caller belong to it. No tokens or credentials are logged or stored.
const fs = require('node:fs');
const crypto = require('node:crypto');
const path = require('node:path');
const serverRequire = require('node:module').createRequire(path.resolve('server/package.json'));
serverRequire('dotenv').config({ path: 'server/.env', quiet: true });
const { initializeApp, cert, deleteApp } = serverRequire('firebase-admin/app');
const { getAuth } = serverRequire('firebase-admin/auth');
const { getFirestore, FieldValue } = serverRequire('firebase-admin/firestore');
const { StreamClient } = serverRequire('@stream-io/node-sdk');
const stateFile = 'scratch/call-push-qa-state.json';
const base = 'https://uma-group-calling.onrender.com';
async function main() {
  const credentials = process.env.FIREBASE_SERVICE_ACCOUNT_JSON
    ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON)
    : JSON.parse(fs.readFileSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, 'utf8'));
  const app = initializeApp({ credential: cert(credentials) });
  const db = getFirestore(app), auth = getAuth(app);
  const action = process.argv[2];
  try {
    if (action === 'setup') {
      if (fs.existsSync(stateFile)) throw Error('QA state already exists; use it or clean it up first.');
      const members = await db.collectionGroup('members').get();
      const candidates = new Map();
      for (const member of members.docs) {
        const data = member.data();
        if (Array.isArray(data.callPushTokens) && data.callPushTokens.length) candidates.set(member.id, data);
      }
      if (candidates.size > 1) throw Error(`Need an unambiguous device owner; found ${candidates.size}.`);
      const [receiver, profile] = [...candidates][0] || [];
      const stamp = crypto.randomBytes(5).toString('hex');
      const caller = `call_qa_${stamp}`, group = `call_qa_${stamp}`;
      await auth.createUser({ uid: caller, displayName: 'UMA call verification' });
      const state = { caller, receiver, group };
      fs.writeFileSync(stateFile, JSON.stringify(state));
      const doc = db.collection('squads').doc(group);
      const code = `QA${stamp.slice(0,6).toUpperCase()}`;
      await doc.set({ squadId: group, squadCode: code, name: 'UMA Call Verification',
        hostId: caller, membersUid: receiver ? [caller, receiver] : [caller], chosenPandals: [], isHoppingActive: false });
      if (receiver) await doc.collection('members').doc(receiver).set(profile);
      await doc.collection('members').doc(caller).set({ id: caller, name: 'UMA call verification',
        isHost: true, share_location: false, latitude: 0, longitude: 0, last_seen: Date.now() });
      console.log('Isolated call verification group ready. QA invite code:', code);
      return;
    }
    const state = JSON.parse(fs.readFileSync(stateFile));
    const doc = db.collection('squads').doc(state.group);
    if (action === 'status') {
      const member = (await doc.collection('members').doc(state.receiver).get()).data() || {};
      console.log('Device registration:', JSON.stringify({
        pushTokens: member.callPushTokens?.length || 0,
        ringTokens: member.callRingTokens?.length || 0,
      }));
      const response = await fetch(`${base}/api/squads/${state.group}/video/notify/probe/end`, {
        signal: AbortSignal.timeout(30000),
      });
      console.log('Ringing server route probe (405 means installed):', response.status);
      return;
    }
    if (action === 'attach') {
      const members = await db.collectionGroup('members').get();
      const candidates = new Map();
      for (const member of members.docs) {
        if (member.data().callPushTokens?.length) candidates.set(member.id, member.data());
      }
      if (candidates.size !== 1) throw Error(`Registered device owners: ${candidates.size}`);
      const [receiver, profile] = [...candidates][0];
      await doc.update({ membersUid: FieldValue.arrayUnion(receiver) });
      await doc.collection('members').doc(receiver).set(profile);
      state.receiver = receiver;
      fs.writeFileSync(stateFile, JSON.stringify(state));
      console.log('Connected phone added to isolated verification group.'); return;
    }
    if (action === 'cleanup') {
      const stream = new StreamClient(process.env.STREAM_API_KEY, process.env.STREAM_API_SECRET);
      if (state.callId) await stream.video.call(state.callType, state.callId).delete({ hard: true });
      await db.recursiveDelete(doc);
      await auth.deleteUser(state.caller);
      if (state.callId) await stream.deleteUsers({ user_ids: [state.caller], user: 'hard', messages: 'hard', conversations: 'hard' });
      fs.unlinkSync(stateFile);
      console.log('Temporary call, group, messages and caller cleaned up.');
      return;
    }
    if (!['ring', 'end'].includes(action)) throw Error('Use setup, ring, end or cleanup');
    const apiKey = fs.readFileSync(path.join('app/lib/firebase_options.dart'), 'utf8').match(/apiKey:\s*'([^']+)'/)[1];
    const customToken = await auth.createCustomToken(state.caller);
    const login = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${apiKey}`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: customToken, returnSecureToken: true }), signal: AbortSignal.timeout(25000),
    });
    if (!login.ok) throw Error(`QA login status ${login.status}`);
    const { idToken } = await login.json();
    const headers = { Authorization: `Bearer ${idToken}` };
    if (action === 'end') {
      if (!state.invitation) throw Error('No verification invitation');
      await doc.collection('messages').doc(`${state.invitation}_ended`).set({
        senderId: state.caller, senderName: 'UMA call verification', type: 'text',
        text: 'Verification caller left.', timestamp: Date.now(), callEvent: 'end',
        callInvitationId: state.invitation, callSentAt: FieldValue.serverTimestamp(),
      });
      const response = await fetch(`${base}/api/squads/${state.group}/video/notify/${state.invitation}/end`, {
        method: 'POST', headers, signal: AbortSignal.timeout(30000),
      });
      console.log('Hosted call cancellation:', response.status);
      if (!response.ok) throw Error(`Cancellation status ${response.status}`);
      return;
    }
    if (!state.callId) {
      const sessionResponse = await fetch(`${base}/api/squads/${state.group}/video/session`, {
        method: 'POST', headers, signal: AbortSignal.timeout(90000),
      });
      if (!sessionResponse.ok) throw Error(`QA session status ${sessionResponse.status}`);
      const session = await sessionResponse.json();
      state.callId = session.callId; state.callType = session.callType;
    }
    const invitation = doc.collection('messages').doc();
    state.invitation = invitation.id;
    fs.writeFileSync(stateFile, JSON.stringify(state));
    await invitation.set({ squadId: state.group, senderId: state.caller, senderName: 'UMA call verification',
      type: 'text', text: 'Incoming verification call.', timestamp: Date.now(),
      callEvent: 'invite', callInvitationId: invitation.id, callSentAt: FieldValue.serverTimestamp() });
    const notified = await fetch(`${base}/api/squads/${state.group}/video/notify/${invitation.id}`, {
      method: 'POST', headers, signal: AbortSignal.timeout(30000),
    });
    const result = await notified.json();
    console.log('Hosted call notification:', notified.status, 'devices accepted by FCM:', result.notified ?? 0);
    if (!notified.ok || !result.notified) throw Error('No push delivery accepted.');
  } finally { await db.terminate(); await deleteApp(app); }
}
main().catch(error => { console.error('Call verification:', error.code || error.message?.slice(0,180) || 'failed'); process.exitCode = 1; });
