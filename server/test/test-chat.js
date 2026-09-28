/**
 * Automated Test Suite for UMA Route Assistant Chatbot
 */

const assert = require('assert');
const { detectIntent } = require('../dist/chat/intent');
const { resolvePlace, getSearchablePlaces } = require('../dist/chat/resolve');
const { gatherRouteFacts } = require('../dist/chat/facts');
const {
  templateRouteAnswer,
  templateBlockageAnswer,
  templateCrowdAnswer,
  templateStationAnswer,
  templateHelplineAnswer,
} = require('../dist/chat/templates');
const {
  checkDeviceLimit,
  getCachedAnswer,
  setCachedAnswer,
} = require('../dist/chat/limits');
const { handleChatRequest } = require('../dist/chat/routes');

async function runChatTests() {
  console.log('🤖 Running UMA Route Assistant Test Suite...\n');

  // Test 1: Intent Detection (English, Bengali, Banglish)
  console.log('Test 1: Intent Detection...');
  {
    const r1 = detectIntent('Best way from Howrah to Kumartuli?');
    assert.strictEqual(r1.intent, 'route');
    assert.strictEqual(r1.entities.fromText, 'Howrah');
    assert.strictEqual(r1.entities.toText, 'Kumartuli');
    assert.strictEqual(r1.language, 'en');

    const r2 = detectIntent('হাওড়া থেকে বাগবাজার যাব');
    assert.strictEqual(r2.intent, 'route');
    assert.strictEqual(r2.language, 'bn');

    const r3 = detectIntent('Is College Street road open or blocked?');
    assert.strictEqual(r3.intent, 'blockage_check');

    const r4 = detectIntent('Which pandal is least crowded right now?');
    assert.strictEqual(r4.intent, 'crowd');

    const r5 = detectIntent('Nearest metro station to Baghbazar Sarbojanin');
    assert.strictEqual(r5.intent, 'nearest_station');

    const r6 = detectIntent('Emergency police helpline number');
    assert.strictEqual(r6.intent, 'helpline');

    console.log('  ✓ All 6 intent detection patterns verified');
  }

  // Test 2: Place Resolution
  console.log('Test 2: Place Resolution...');
  {
    const places = getSearchablePlaces();
    assert.ok(places.length > 50, `Expected > 50 searchable places, found ${places.length}`);

    // Resolve by name
    const hwh = resolvePlace('Howrah');
    assert.ok(hwh.match != null, 'Failed to resolve Howrah');
    assert.ok(hwh.match.name.toLowerCase().includes('howrah'));

    // Resolve by code
    const sdah = resolvePlace('SDAH');
    assert.ok(sdah.match != null, 'Failed to resolve SDAH');
    assert.strictEqual(sdah.match.code, 'SDAH');

    // Resolve landmark
    const collegeSt = resolvePlace('College Street');
    assert.ok(collegeSt.match != null, 'Failed to resolve College Street');

    console.log('  ✓ Place resolution (names, codes, landmarks) verified');
  }

  // Test 3: Facts Gathering
  console.log('Test 3: Fact Gathering...');
  {
    const from = resolvePlace('Howrah').match;
    const to = resolvePlace('College Street').match;

    const facts = await gatherRouteFacts(from, to, {
      distance_m: 3400,
      duration_s: 2400,
      mode: 'pedestrian',
    });

    assert.ok(facts.from, 'Missing facts.from');
    assert.ok(facts.to, 'Missing facts.to');
    assert.strictEqual(facts.route.distance_m, 3400);
    assert.strictEqual(facts.route.duration_min, 40);
    assert.ok(Array.isArray(facts.blockages_on_route), 'Missing blockages_on_route');
    assert.ok(facts.helplines.length > 0, 'Missing emergency helplines');

    console.log('  ✓ Deterministic facts gathered and verified');
  }

  // Test 4: Deterministic Fallback Templates
  console.log('Test 4: Fallback Template Generation...');
  {
    const from = resolvePlace('Howrah').match;
    const to = resolvePlace('College Street').match;
    const facts = await gatherRouteFacts(from, to);

    const enAnswer = templateRouteAnswer(facts, 'en');
    assert.ok(enAnswer.includes('Howrah'), 'Expected from place in template');
    assert.ok(enAnswer.includes('College Street'), 'Expected to place in template');

    const bnAnswer = templateRouteAnswer(facts, 'bn');
    assert.ok(bnAnswer.includes('থেকে'), 'Expected Bengali connective');

    const helpline = templateHelplineAnswer('en');
    assert.ok(helpline.includes('100 / 112'), 'Expected police emergency number');

    console.log('  ✓ Multilingual zero-cost fallback templates verified');
  }

  // Test 5: Rate Limiting & Response Caching
  console.log('Test 5: Rate Limiting & Caching...');
  {
    const testDev = 'test_dev_' + Math.random().toString(36).substring(2, 8);
    for (let i = 0; i < 10; i++) {
      const res = checkDeviceLimit(testDev);
      assert.strictEqual(res.allowed, true, `Call ${i + 1} should be allowed`);
    }
    // 11th call must be blocked
    const blocked = checkDeviceLimit(testDev);
    assert.strictEqual(blocked.allowed, false, '11th call must be rate-limited');

    // Caching
    setCachedAnswer('key_1', 'Cached answer test', new Date().toISOString(), false, 60);
    const cached = getCachedAnswer('key_1');
    assert.ok(cached != null);
    assert.strictEqual(cached.answer, 'Cached answer test');

    console.log('  ✓ Per-device rate limiter (10/hr) and 60s cache verified');
  }

  // Test 6: End-to-End handleChatRequest
  console.log('Test 6: Full handleChatRequest Pipeline...');
  {
    const res = await handleChatRequest({
      deviceId: 'test_dev_e2e',
      message: 'Best way from Howrah to College Street?',
      route: { distance_m: 3500, duration_s: 2700, mode: 'pedestrian' },
    });

    assert.strictEqual(res.status, 200);
    assert.ok(res.data.answer.length > 20);
    assert.strictEqual(res.data.intent, 'route');
    assert.ok(res.data.facts_as_of);

    console.log('  ✓ handleChatRequest succeeded with structured response');
  }

  console.log('\n🎉 ALL 6 CHATBOT TEST SUITES PASSED CLEANLY!\n');
}

runChatTests().catch((err) => {
  console.error('❌ Chatbot test failed:', err);
  process.exit(1);
});
