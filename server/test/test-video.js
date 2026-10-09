const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');
const { StreamClient: RealStreamClient } = require('@stream-io/node-sdk');

let roster = { membersUid: ['alice'], name: 'Test group' };
let claimsValid = true;
let calls = 0;
let grants;
const originalLoad = Module._load;
Module._load = function(name, ...args) {
  if (name === 'firebase-admin/auth') return { getAuth: () => ({
    verifyIdToken: async (token, checkRevoked) => {
      assert.equal(checkRevoked, true);
      if (!claimsValid || token !== 'firebase-token') throw new Error('invalid');
      return { uid: 'alice' };
    },
    getUser: async uid => ({ uid, displayName: 'Alice' }),
  }) };
  if (name === 'firebase-admin/firestore') return { getFirestore: () => ({
    collection: () => ({ doc: () => ({ get: async () => ({
      data: () => roster, createTime: { toMillis: () => 1234 },
    }) }) }),
  }) };
  if (name === '@stream-io/node-sdk') return { StreamClient: class extends RealStreamClient {
    constructor(...params) {
      super(...params);
      this.upsertUsers = async () => {};
      this.video = {
        listCallTypes: async () => ({ call_types: {} }),
        createCallType: async request => { grants = request.grants; },
        call: () => ({ getOrCreate: async request => {
          calls++;
          assert.equal(request.data.members, undefined, 'No permanent membership bypasses renewal');
        } }),
      };
    }
  } };
  return originalLoad.call(this, name, ...args);
};
const { handleVideoRequest, CALL_TYPE, TOKEN_TTL, squadCallId } = require('../dist/video');
Module._load = originalLoad;
process.env.STREAM_API_KEY = 'test-key';
process.env.STREAM_API_SECRET = 'test-secret';

async function request(headers = {}, squadId = 'sq_PUJA1234', app = {}) {
  let result;
  await handleVideoRequest({ headers }, { setHeader: (key, value) => {
    assert.equal(key, 'Cache-Control'); assert.equal(value, 'no-store');
  } }, squadId, app, (_, status, data) => { result = { status, data }; });
  return result;
}

test('never accepts x-user-id without Firebase sign-in', async () => {
  const result = await request({ 'x-user-id': 'alice' });
  assert.equal(result.status, 401); assert.equal(calls, 0);
});
test('rejects forged and revoked Firebase tokens', async () => {
  assert.equal((await request({ authorization: 'Bearer alice' })).status, 401);
  claimsValid = false;
  assert.equal((await request({ authorization: 'Bearer firebase-token' })).status, 401);
  claimsValid = true;
});
test('rejects missing, closed and nonmember groups', async () => {
  for (const data of [undefined, { membersUid: ['bob'] }, { status: 'closed', membersUid: ['alice'] }]) {
    roster = data;
    assert.equal((await request({ authorization: 'Bearer firebase-token' })).status, 403);
  }
  assert.equal(calls, 0);
});
test('valid member gets a short-lived token for exactly one private room', async () => {
  roster = { membersUid: ['alice'], name: 'Test group' };
  const { status, data } = await request({ authorization: 'Bearer firebase-token' });
  assert.equal(status, 200);
  assert.deepEqual(grants.user, []);
  assert.deepEqual(grants.anonymous, []);
  assert.ok(grants.call_member.includes('join-call'));
  const payload = JSON.parse(Buffer.from(data.token.split('.')[1], 'base64url'));
  assert.equal(payload.user_id, 'alice');
  assert.deepEqual(payload.call_cids, [`${CALL_TYPE}:${data.callId}`]);
  assert.equal(payload.exp - payload.iat, TOKEN_TTL);
  assert.equal(data.userId, 'alice');
  assert.equal(JSON.stringify(data).includes('test-secret'), false);
});
test('membership removal denies token renewal', async () => {
  roster = { membersUid: [] };
  assert.equal((await request({ authorization: 'Bearer firebase-token' })).status, 403);
});
test('invalid group paths and unavailable auth fail closed', async () => {
  assert.equal((await request({}, '../other')).status, 400);
  assert.equal((await request({}, 'valid', null)).status, 503);
});
test('room identity stays stable and changes when a group code is reused', () => {
  assert.equal(squadCallId('a', '123'), squadCallId('a', '123'));
  assert.notEqual(squadCallId('a', '123'), squadCallId('b', '123'));
  assert.notEqual(squadCallId('a', '123'), squadCallId('a', '124'));
});
