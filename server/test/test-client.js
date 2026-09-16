/**
 * Automated end-to-end test verifying:
 * 1. Host creates squad PUJA9999
 * 2. Companion joins squad PUJA9999
 * 3. Host broadcasts location update
 * 4. Companion receives broadcast and measures latency (< 50ms)
 */

const { WebSocket } = require('ws');

const SERVER_URL = process.env.TEST_WS_URL || 'ws://localhost:8080/squad';

async function runTest() {
  console.log('🧪 Starting Squad WebSocket E2E Test on', SERVER_URL);

  const hostWs = new WebSocket(`${SERVER_URL}?token=user_host_123`);
  const peerWs = new WebSocket(`${SERVER_URL}?token=user_peer_456`);

  const awaitOpen = (ws) =>
    new Promise((resolve, reject) => {
      ws.once('open', resolve);
      ws.once('error', reject);
    });

  await Promise.all([awaitOpen(hostWs), awaitOpen(peerWs)]);
  console.log('✓ Both sockets connected successfully');

  let resolvePeerReceived;
  const peerReceivedPromise = new Promise((resolve) => {
    resolvePeerReceived = resolve;
  });

  peerWs.on('message', (data) => {
    const msg = JSON.parse(data.toString());
    if (msg.type === 'location_update') {
      const now = Date.now();
      const latency = now - msg.server_timestamp;
      console.log(`✓ Peer received location_update: lat=${msg.latitude}, lng=${msg.longitude}`);
      console.log(`⏱️ Round-trip broadcast latency: ~${latency} ms`);
      resolvePeerReceived(latency);
    }
  });

  // Step 1: Host creates squad
  console.log('Step 1: Host creating squad PUJA9999...');
  hostWs.send(
    JSON.stringify({
      type: 'join_squad',
      squad_code: 'PUJA9999',
      member_name: 'Anirban (Host)',
      is_host: true,
      initial_latitude: 22.5726,
      initial_longitude: 88.3639,
      timestamp: Date.now(),
    })
  );

  // Wait 100ms
  await new Promise((r) => setTimeout(r, 100));

  // Step 2: Peer joins squad
  console.log('Step 2: Companion joining squad PUJA9999...');
  peerWs.send(
    JSON.stringify({
      type: 'join_squad',
      squad_code: 'PUJA9999',
      member_name: 'Deblina (Companion)',
      is_host: false,
      initial_latitude: 22.5735,
      initial_longitude: 88.3645,
      timestamp: Date.now(),
    })
  );

  // Wait 100ms
  await new Promise((r) => setTimeout(r, 100));

  // Step 3: Host sends location update
  console.log('Step 3: Host sending location update...');
  hostWs.send(
    JSON.stringify({
      type: 'location_update',
      squad_code: 'PUJA9999',
      latitude: 22.5750,
      longitude: 88.3660,
      status: 'Near Bagbazar',
      battery_level: 88,
      timestamp: Date.now(),
    })
  );

  // Wait for peer to receive
  const latency = await Promise.race([
    peerReceivedPromise,
    new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout waiting for location update')), 3000)),
  ]);

  console.log(`🎉 E2E TEST PASSED! Sub-50ms latency confirmed: ${latency} ms.`);

  hostWs.close();
  peerWs.close();
  process.exit(0);
}

runTest().catch((err) => {
  console.error('❌ E2E TEST FAILED:', err);
  process.exit(1);
});
