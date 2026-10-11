const { test } = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');
const original = Module._load;
let roster, invitation, ended, receipt, sent, ringCapable;
const doc = {
  get: async () => ({ data: () => roster }),
  collection: name => name === 'members'
    ? { get: async () => ({ docs: [
        { id: 'alice', data: () => ({ callPushTokens: ['caller-token-should-not-ring'] }) },
        { id: 'bob', data: () => ({ callPushTokens: ['recipient-token-1234567890'],
          callRingTokens: ringCapable ? ['recipient-token-1234567890'] : [] }) },
        { id: 'removed', data: () => ({ callPushTokens: ['removed-token-should-not-ring'] }) },
      ] }) }
    : { doc: id => name === 'callPushReceipts' ? { receipt: true }
        : { get: async () => ({ data: () => id.endsWith('_ended') ? ended : invitation,
          exists: id.endsWith('_ended') ? Boolean(ended) : true }) } },
};
Module._load = function(name, ...args) {
  if (name === 'firebase-admin/auth') return { getAuth: () => ({
    verifyIdToken: async token => { if (token !== 'valid') throw Error(); return { uid: 'alice' }; },
    getUser: async () => ({ displayName: 'Alice' }),
  }) };
  if (name === 'firebase-admin/firestore') return {
    FieldValue: { serverTimestamp: () => 'server-time' },
    getFirestore: () => ({ collection: () => ({ doc: () => doc }),
      runTransaction: async callback => callback({
        get: async () => ({ exists: receipt }), create: () => { receipt = true; },
      }),
    }),
  };
  if (name === 'firebase-admin/messaging') return { getMessaging: () => ({
    sendEachForMulticast: async message => { sent.push(message); return { successCount: message.tokens.length }; },
  }) };
  return original.call(this, name, ...args);
};
const { notifyGroupCall, validInvitation } = require('../dist/call-notifications');
Module._load = original;

function reset() {
  roster = { membersUid: ['alice', 'bob'], name: 'Test group' };
  invitation = { senderId: 'alice', callEvent: 'invite', callInvitationId: 'invite', callSentAt: { toMillis: () => Date.now() } };
  ended = receipt = ringCapable = false; sent = [];
}
async function request(token = 'valid', ending = false) {
  let result;
  await notifyGroupCall({ headers: { authorization: `Bearer ${token}` } }, { setHeader() {} },
    'group', 'invite', {}, (_, status, data) => { result = { status, data }; }, ending);
  return result;
}
test('only current group recipients receive a short-lived audible push', async () => {
  reset();
  assert.equal((await request()).status, 200);
  assert.deepEqual(sent[0].tokens, ['recipient-token-1234567890']);
  assert.equal(sent[0].android.priority, 'high');
  assert.equal(sent[0].android.notification.channelId, 'uma_incoming_calls');
  assert.ok(sent[0].android.ttl <= 60000);
  assert.equal(sent[0].data.invitationId, 'invite');
  assert.equal((await request()).data.duplicate, true);
  assert.equal(sent.length, 1);
});
test('forged identity, membership removal, ended and expired invitations fail closed', async () => {
  reset(); assert.equal((await request('forged')).status, 401);
  roster.membersUid = ['bob']; assert.equal((await request()).status, 403);
  reset(); ended = {senderId: 'alice', callEvent: 'end', callInvitationId: 'invite'};
  assert.equal((await request()).status, 409);
  reset(); invitation.senderId = 'bob'; assert.equal((await request()).status, 409);
  reset(); invitation.callSentAt = { toMillis: () => Date.now() - 61000 };
  assert.equal((await request()).status, 409); assert.equal(sent.length, 0);
  assert.equal(validInvitation({}, 'alice', 'invite'), false);
});

test('ring-capable devices receive high-priority data without a duplicate notification', async () => {
  reset(); ringCapable = true;
  assert.equal((await request()).status, 200);
  assert.equal(sent.length, 1);
  assert.equal(sent[0].data.type, 'group_call_ring');
  assert.equal(sent[0].notification, undefined);
  assert.equal(sent[0].android.priority, 'high');
  assert.equal(sent[0].data.callerName, 'Alice');
});

test('only the invitation owner can end ringing on recipients', async () => {
  reset(); ringCapable = true;
  ended = {senderId: 'bob', callEvent: 'end', callInvitationId: 'invite'};
  assert.equal((await request('valid', true)).status, 409);
  assert.equal(sent.length, 0);
  assert.equal((await request()).status, 200);
  receipt = false; sent = [];
  ended = {senderId: 'alice', callEvent: 'end', callInvitationId: 'invite'};
  assert.equal((await request('valid', true)).status, 200);
  assert.equal(sent[0].data.type, 'group_call_end');
});
