const { test } = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');
const original = Module._load;
let roster, invitation, ended, receipt, sent;
const doc = {
  get: async () => ({ data: () => roster }),
  collection: name => name === 'members'
    ? { get: async () => ({ docs: [
        { id: 'alice', data: () => ({ callPushTokens: ['caller-token-should-not-ring'] }) },
        { id: 'bob', data: () => ({ callPushTokens: ['recipient-token-1234567890'] }) },
        { id: 'removed', data: () => ({ callPushTokens: ['removed-token-should-not-ring'] }) },
      ] }) }
    : { doc: id => name === 'callPushReceipts' ? { receipt: true }
        : { get: async () => ({ data: () => invitation, exists: id.endsWith('_ended') && ended }) } },
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
  ended = receipt = false; sent = [];
}
async function request(token = 'valid') {
  let result;
  await notifyGroupCall({ headers: { authorization: `Bearer ${token}` } }, { setHeader() {} },
    'group', 'invite', {}, (_, status, data) => { result = { status, data }; });
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
  reset(); ended = true; assert.equal((await request()).status, 409);
  reset(); invitation.senderId = 'bob'; assert.equal((await request()).status, 409);
  reset(); invitation.callSentAt = { toMillis: () => Date.now() - 61000 };
  assert.equal((await request()).status, 409); assert.equal(sent.length, 0);
  assert.equal(validInvitation({}, 'alice', 'invite'), false);
});
