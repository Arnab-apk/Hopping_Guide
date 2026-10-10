// Real three-client WebRTC test using synthetic AV. No physical camera/mic.
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const esbuild = require('esbuild');
const { chromium } = require('playwright-core');
const dotenv = require('../../server/node_modules/dotenv');
const requireServer = require('node:module').createRequire(path.resolve('../../server/package.json'));
const { initializeApp, cert, deleteApp } = requireServer('firebase-admin/app');
const { getAuth } = requireServer('firebase-admin/auth');
const { getFirestore } = requireServer('firebase-admin/firestore');
const { StreamClient } = require('../../server/node_modules/@stream-io/node-sdk');

async function main() {
  const config = dotenv.parse(fs.readFileSync(path.resolve('../../server/.env')));
  const app = initializeApp({ credential: cert(JSON.parse(fs.readFileSync(config.GOOGLE_APPLICATION_CREDENTIALS))) });
  const auth = getAuth(app), db = getFirestore(app);
  const stream = new StreamClient(config.STREAM_API_KEY, config.STREAM_API_SECRET);
  const apiKey = fs.readFileSync('../../app/lib/firebase_options.dart','utf8').match(/apiKey:\s*'([^']+)'/)[1];
  const stamp = crypto.randomBytes(8).toString('hex');
  const userIds = [1,2,3].map(number => `video_media_${stamp}_${number}`);
  const createdUsers = []; const sessions = [];
  const doc = db.collection('squads').doc(`video_media_${stamp}`);
  let wroteDoc = false, browser, server;
  try {
    for (const uid of userIds) {
      await auth.createUser({ uid, displayName: 'Temporary media verification' }); createdUsers.push(uid);
    }
    await doc.create({ name: 'Temporary media verification', membersUid: userIds }); wroteDoc = true;
    for (const uid of userIds) {
      const customToken = await auth.createCustomToken(uid);
      const signIn = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${apiKey}`, {
        method: 'POST', headers: { 'Content-Type':'application/json' },
        body: JSON.stringify({ token: customToken, returnSecureToken:true }), signal: AbortSignal.timeout(25000),
      });
      assert.equal(signIn.status,200,'Firebase sign-in');
      const { idToken } = await signIn.json();
      const response = await fetch(`https://uma-group-calling.onrender.com/api/squads/${doc.id}/video/session`, {
        method:'POST', headers:{Authorization:`Bearer ${idToken}`},signal:AbortSignal.timeout(90000),
      });
      assert.equal(response.status,200,'Hosted group session'); sessions.push(await response.json());
    }
    const bundle = await esbuild.build({ entryPoints:['browser.js'],bundle:true,write:false,format:'iife',platform:'browser' });
    server = http.createServer((req,res) => {
      if (req.url === '/bundle.js') { res.setHeader('Content-Type','application/javascript'); res.end(bundle.outputFiles[0].text); }
      else { res.setHeader('Content-Type','text/html'); res.end('<div id="participants"></div><script src="/bundle.js"></script>'); }
    });
    await new Promise(resolve => server.listen(0,'127.0.0.1',resolve));
    const origin = `http://127.0.0.1:${server.address().port}`;
    browser = await chromium.launch({ executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,
      args:['--use-fake-device-for-media-stream','--use-fake-ui-for-media-stream','--mute-audio','--autoplay-policy=no-user-gesture-required'] });
    const pages = [];
    for (const session of sessions) {
      const context = await browser.newContext({ permissions:['camera','microphone'],viewport:{width:1100,height:800} });
      await context.addInitScript(() => {
        window.mediaConnections=[];
        const NativeConnection = window.RTCPeerConnection;
        window.RTCPeerConnection = class extends NativeConnection {
          constructor(...args) { super(...args); window.mediaConnections.push(this); }
        };
      });
      const page = await context.newPage(); pages.push(page);
      await page.goto(origin); await page.evaluate(session => window.joinMedia(session),session);
    }
    const deadline = Date.now()+60000;
    let stats;
    do {
      stats = await Promise.all(pages.map(page => page.evaluate(() => window.mediaStats())));
      if (stats.every(item => item.participants === 3 && item.videoFrames > 10 && item.audioPackets > 10)) break;
      await new Promise(resolve => setTimeout(resolve,1000));
    } while(Date.now()<deadline);
    for (const item of stats) {
      assert.equal(item.participants,3,'All group participants visible');
      assert.ok(item.videoFrames>10,'Remote video frames decoded');
      assert.ok(item.audioPackets>10,'Remote audio packets received');
    }
    console.log('Three-participant group media verified:',JSON.stringify(stats));
    const muted = await pages[0].evaluate(async () => {
      await window.mediaCall.camera.disable(); await window.mediaCall.microphone.disable();
      return { camera:window.mediaCall.camera.state.status,microphone:window.mediaCall.microphone.state.status };
    });
    assert.equal(muted.camera,'disabled'); assert.equal(muted.microphone,'disabled');
    await pages[0].evaluate(async () => { await window.mediaCall.camera.enable(); await window.mediaCall.microphone.enable(); });
    await pages[2].evaluate(async () => { await window.mediaCall.leave(); await window.mediaClient.disconnectUser(); });
    await pages[0].waitForFunction(() => window.mediaParticipantCount === 2,{},{timeout:20000});
    console.log('Camera/microphone toggle and participant leave verified.');
    fs.writeFileSync('verified.json',JSON.stringify({ participants:3,stats,cameraMicrophoneToggle:true,leave:true,syntheticMedia:true,hostedBackend:true,verifiedAt:new Date().toISOString() },null,2));
  } finally {
    if(browser)await browser.close();
    if(server)await new Promise(resolve => server.close(resolve));
    const cleanup=[];
    if(sessions[0])cleanup.push(stream.video.call(sessions[0].callType,sessions[0].callId).delete({hard:true}));
    if(wroteDoc)cleanup.push(doc.delete());
    for(const uid of createdUsers)cleanup.push(auth.deleteUser(uid));
    if(sessions.length)cleanup.push(stream.deleteUsers({user_ids:sessions.map(item=>item.userId),user:'hard',messages:'hard',conversations:'hard'}));
    const results=await Promise.allSettled(cleanup); await db.terminate(); await deleteApp(app);
    if(results.some(result=>result.status==='rejected'))throw new Error('Temporary media test cleanup failed');
    console.log('Temporary media-test records cleaned up.');
  }
}
main().catch(error => {
  console.error('Media verification failed:',error.name,error.operator ? `expected ${error.expected}, received ${error.actual}` : String(error.message).replace(/eyJ[A-Za-z0-9_.-]+/g,'[redacted]').slice(0,300));
  process.exitCode=1;
});
