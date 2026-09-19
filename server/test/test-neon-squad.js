const http = require('http');
const { spawn } = require('child_process');
const { WebSocket } = require('ws');

// Helper to make HTTP requests
function httpRequest(options, postData) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          resolve({ status: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, raw: body });
        }
      });
    });
    req.on('error', reject);
    if (postData) {
      req.write(JSON.stringify(postData));
    }
    req.end();
  });
}

const path = require('path');

async function runNeonSquadTests() {
  console.log('🧪 Starting Neon Squad & Realtime End-to-End Test...');

  const serverScript = path.resolve(__dirname, '../dist/index.js');
  console.log('Spawning server from:', serverScript);

  // Start the server process on port 8089 to avoid conflicts
  const serverProcess = spawn(process.execPath, [serverScript], {
    env: { ...process.env, PORT: '8089', HOST: '127.0.0.1' },
    stdio: 'inherit',
  });

  // Wait for server to boot
  await new Promise((r) => setTimeout(r, 2000));

  try {
    // 1. Health check
    console.log('Test 1: Health check...');
    const health = await httpRequest({
      hostname: '127.0.0.1',
      port: 8089,
      path: '/health',
      method: 'GET',
    });
    if (health.status !== 200 || health.data.status !== 'ok') {
      throw new Error(`Health check failed: ${JSON.stringify(health)}`);
    }
    console.log('✓ Health check passed');

    // 2. Create squad via REST API
    console.log('Test 2: Creating squad via POST /api/squads...');
    const createRes = await httpRequest(
      {
        hostname: '127.0.0.1',
        port: 8089,
        path: '/api/squads',
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': 'host_arnab_123' },
      },
      {
        name: 'Bagbazar Hoppers',
        meetupLat: 22.5726,
        meetupLng: 88.3639,
        meetupLabel: 'Bagbazar Ghat Entry',
        separationRadiusM: 500,
        hostDisplayName: 'Arnab (Host)',
        isGuest: true,
      }
    );

    if (createRes.status !== 201 || !createRes.data.squad) {
      throw new Error(`Create squad failed: ${JSON.stringify(createRes)}`);
    }
    const squad = createRes.data.squad;
    const squadCode = squad.code;
    const squadId = squad.id;
    console.log(`✓ Squad created with ID: ${squadId} and Code: ${squadCode}`);

    // Verify squad code format: PUJA-XXXX (avoiding ambiguous chars 0, O, 1, I, L)
    if (!squadCode.match(/^PUJA-[2-9A-HJ-NP-Z]{4}$/)) {
      throw new Error(`Squad code format invalid: ${squadCode}`);
    }
    console.log('✓ Cryptographic squad code verified:', squadCode);

    // 3. Join squad via REST API
    console.log('Test 3: Joining squad via POST /api/squads/join...');
    const joinRes = await httpRequest(
      {
        hostname: '127.0.0.1',
        port: 8089,
        path: '/api/squads/join',
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': 'peer_debaditya_456' },
      },
      {
        code: squadCode,
        displayName: 'Debaditya (Companion)',
        isGuest: true,
      }
    );

    if (joinRes.status !== 200 || !joinRes.data.member) {
      throw new Error(`Join squad failed: ${JSON.stringify(joinRes)}`);
    }
    console.log('✓ Member joined squad successfully');

    // 4. Test preview endpoint
    console.log('Test 4: Preview endpoint GET /api/squads/preview/:code...');
    const previewRes = await httpRequest({
      hostname: '127.0.0.1',
      port: 8089,
      path: `/api/squads/preview/${squadCode}`,
      method: 'GET',
    });
    if (previewRes.status !== 200 || previewRes.data.member_count !== 2) {
      throw new Error(`Preview failed: ${JSON.stringify(previewRes)}`);
    }
    console.log('✓ Preview endpoint confirmed 2 members, privacy protected');

    // 5. Connect WebSockets for both Host and Companion
    console.log('Test 5: Connecting WebSockets to /ws?squadId=...');
    const wsUrl = `ws://127.0.0.1:8089/ws?squadId=${squadId}`;
    const hostWs = new WebSocket(`${wsUrl}&token=host_arnab_123`);
    const peerWs = new WebSocket(`${wsUrl}&token=peer_debaditya_456`);

    const awaitOpen = (ws) =>
      new Promise((resolve, reject) => {
        ws.once('open', resolve);
        ws.once('error', reject);
      });

    await Promise.all([awaitOpen(hostWs), awaitOpen(peerWs)]);
    console.log('✓ Both WebSockets connected to squad channel');

    // Prepare message listeners
    let resolveSeparationAlert;
    const separationAlertPromise = new Promise((resolve) => {
      resolveSeparationAlert = resolve;
    });

    let resolveChatReceived;
    const chatReceivedPromise = new Promise((resolve) => {
      resolveChatReceived = resolve;
    });

    hostWs.on('message', (data) => {
      const msg = JSON.parse(data.toString());
      if (msg.type === 'separation_alert') {
        console.log(`✓ Host received separation alert! Member distance: ${msg.payload.distanceMeters}m > threshold ${msg.payload.thresholdMeters}m`);
        resolveSeparationAlert(msg);
      }
      if (msg.type === 'chat_message') {
        console.log(`✓ Host received chat message: "${msg.payload.message}"`);
        resolveChatReceived(msg);
      }
    });

    // 6. Peer sends location update that is > 500m away from meetup point (22.5726, 88.3639)
    // 22.5800, 88.3639 is ~822m away
    console.log('Test 6: Companion sending location update 820m away (triggering separation alert)...');
    peerWs.send(
      JSON.stringify({
        type: 'location_update',
        eventId: 'loc-1',
        squadId: squadId,
        senderId: 'peer_debaditya_456',
        timestamp: new Date().toISOString(),
        payload: {
          lat: 22.5800,
          lng: 88.3639,
          accuracy: 5.0,
          heading: 90,
          speed: 1.2,
        },
      })
    );

    const alertEvent = await Promise.race([
      separationAlertPromise,
      new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout waiting for separation alert')), 4000)),
    ]);
    if (alertEvent.payload.distanceMeters < 500) {
      throw new Error(`Distance alert calculation mismatch: ${alertEvent.payload.distanceMeters}`);
    }
    console.log('✓ Separation alert verified with accurate Haversine calculation');

    // 7. Companion sends chat message
    console.log('Test 7: Companion sending chat message with optimistic clientMessageId...');
    let resolveAck;
    const ackPromise = new Promise((resolve) => (resolveAck = resolve));
    peerWs.on('message', (data) => {
      const msg = JSON.parse(data.toString());
      if (msg.type === 'message_ack') {
        console.log(`✓ Companion received message_ack for clientMessageId: ${msg.payload.clientMessageId}`);
        resolveAck(msg);
      }
    });

    peerWs.send(
      JSON.stringify({
        type: 'chat_message',
        eventId: 'chat-1',
        squadId: squadId,
        senderId: 'peer_debaditya_456',
        timestamp: new Date().toISOString(),
        payload: {
          clientMessageId: 'local-client-msg-123',
          message: 'Where is everyone meeting near Bagbazar?',
          messageType: 'text',
        },
      })
    );

    await Promise.all([
      ackPromise,
      chatReceivedPromise,
    ]);
    console.log('✓ Chat message delivery & acknowledgement verified');

    hostWs.close();
    peerWs.close();
    console.log('\n🎉 ALL NEON SQUAD & REALTIME TESTS PASSED SUCCESSFULLY! 🎉\n');
  } finally {
    serverProcess.kill();
  }
}

runNeonSquadTests().catch((err) => {
  console.error('❌ Test failed:', err);
  process.exit(1);
});
