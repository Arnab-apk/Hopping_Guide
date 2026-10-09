// Opt-in integration test: creates only uniquely named temporary test records.
// Never logs ID tokens, Stream tokens, service-account contents or API secrets.
require('dotenv').config();
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { initializeApp, applicationDefault, cert, deleteApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { StreamClient } = require('@stream-io/node-sdk');
const { handleVideoRequest } = require('../dist/video');

async function main() {
  const app = initializeApp({ credential: process.env.FIREBASE_SERVICE_ACCOUNT_JSON
    ? cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON))
    : process.env.GOOGLE_APPLICATION_CREDENTIALS
    ? cert(JSON.parse(fs.readFileSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, 'utf8')))
    : applicationDefault() });
  const auth = getAuth(app);
  const firestore = getFirestore(app);
  const stream = new StreamClient(process.env.STREAM_API_KEY, process.env.STREAM_API_SECRET);
  const stamp = crypto.randomBytes(8).toString('hex');
  const uid = `video_smoke_${stamp}`;
  const squadId = `video_smoke_${stamp}`;
  const createdUsers = [];
  let session;
  let unrelatedCall;
  let unrelatedUser;
  const doc = firestore.collection('squads').doc(squadId);
  const dartConfig = fs.readFileSync(path.join(__dirname, '../../app/lib/firebase_options.dart'), 'utf8');
  const apiKey = dartConfig.match(/apiKey:\s*'([^']+)'/)[1];
  let wroteDocument = false;
  try {
    await auth.createUser({ uid, displayName: 'Temporary video verification' });
    createdUsers.push(uid);
    const customToken = await auth.createCustomToken(uid);
    const signIn = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${apiKey}`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: customToken, returnSecureToken: true }),
      signal: AbortSignal.timeout(25000),
    });
    assert.equal(signIn.status, 200, 'Firebase sign-in must succeed');
    const { idToken } = await signIn.json();
    await doc.create({ name: 'Temporary video verification', membersUid: [uid] });
    wroteDocument = true;
    const invoke = async headers => {
      if (process.env.VIDEO_TEST_API_URL) {
        const response = await fetch(`${process.env.VIDEO_TEST_API_URL}/api/squads/${squadId}/video/session`, {
          method: 'POST', headers, signal: AbortSignal.timeout(90000),
        });
        return { status: response.status, data: await response.json() };
      }
      let result;
      await handleVideoRequest({ headers }, { setHeader: () => {} }, squadId, app,
        (_, status, data) => { result = { status, data }; });
      return result;
    };
    assert.equal((await invoke({ 'x-user-id': uid })).status, 401);
    const valid = await invoke({ authorization: `Bearer ${idToken}` });
    assert.equal(valid.status, 200, 'Authenticated member must get a call session');
    session = valid.data;
    const readCall = await fetch(`https://video.stream-io-api.com/api/v2/video/call/${session.callType}/${session.callId}?api_key=${session.apiKey}`, {
      headers: { Authorization: session.token, 'stream-auth-type': 'jwt' },
      signal: AbortSignal.timeout(25000),
    });
    assert.equal(readCall.status, 200, 'Scoped client token must read its private call');
    unrelatedUser = `${uid}_other`;
    await stream.upsertUsers([{ id: unrelatedUser, role: 'user', name: 'Temporary privacy verification' }]);
    unrelatedCall = stream.video.call(session.callType, `${session.callId}_other`);
    await unrelatedCall.getOrCreate({ data: { created_by_id: unrelatedUser } });
    const readOther = await fetch(`https://video.stream-io-api.com/api/v2/video/call/${session.callType}/${unrelatedCall.id}?api_key=${session.apiKey}`, {
      headers: { Authorization: session.token, 'stream-auth-type': 'jwt' },
      signal: AbortSignal.timeout(25000),
    });
    assert.ok([403, 404].includes(readOther.status), 'Client token must not read another private room');
    await doc.update({ membersUid: [] });
    assert.equal((await invoke({ authorization: `Bearer ${idToken}` })).status, 403);
    console.log('Live verification passed: Firebase sign-in, private Stream call access, cross-room privacy, forged identity rejection and membership-removal denial.');
  } finally {
    const cleanup = [];
    if (session) cleanup.push(stream.video.call(session.callType, session.callId).delete({ hard: true }));
    if (unrelatedCall) cleanup.push(unrelatedCall.delete({ hard: true }));
    if (wroteDocument) cleanup.push(doc.delete());
    for (const userId of createdUsers) cleanup.push(auth.deleteUser(userId));
    if (session) cleanup.push(stream.deleteUsers({ user_ids: [uid], user: 'hard', messages: 'hard', conversations: 'hard' }));
    if (unrelatedUser) cleanup.push(stream.deleteUsers({ user_ids: [unrelatedUser], user: 'hard', messages: 'hard', conversations: 'hard' }));
    const results = await Promise.allSettled(cleanup);
    await firestore.terminate();
    await deleteApp(app);
    if (results.some(result => result.status === 'rejected')) {
      throw new Error('Temporary verification records could not all be cleaned up.');
    }
    console.log('Temporary Firebase and Stream test records cleaned up.');
  }
}
main().catch(error => {
  // Print assertion context/status only, never raw provider responses.
  console.error('Live verification failed:', error.code || error.name,
    error.operator ? `expected ${error.expected}, received ${error.actual}` : 'check credentials and network access');
  process.exitCode = 1;
});
