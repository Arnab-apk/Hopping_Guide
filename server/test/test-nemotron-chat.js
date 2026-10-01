/**
 * Live Verification Test for NVIDIA Nemotron 3 Ultra Chatbot Integration
 */
const { handleChatRequest } = require('../dist/chat/routes');

async function testNemotron() {
  console.log('Testing NVIDIA Nemotron 3 Ultra online mode...\n');

  // Query 1: Bengali Route Query
  const q1 = 'হাওড়া থেকে বাগবাজার কীভাবে যাব? (How do I go from Howrah to Bagbazar?)';
  console.log(`Query 1 (Bengali): "${q1}"`);
  const r1 = await handleChatRequest({
    deviceId: 'test_nemotron_bn',
    message: q1,
    lang: 'bn',
    route: { distance_m: 5200, duration_s: 3600, mode: 'pedestrian' },
  });
  console.log('used_llm:', r1.data.used_llm);
  console.log('Answer 1:\n' + r1.data.answer);
  console.log('--------------------------------------------------\n');

  // Query 2: English Blockage Query
  const q2 = 'Is College Street road open or blocked by police?';
  console.log(`Query 2 (English): "${q2}"`);
  const r2 = await handleChatRequest({
    deviceId: 'test_nemotron_en',
    message: q2,
    lang: 'en',
  });
  console.log('used_llm:', r2.data.used_llm);
  console.log('Answer 2:\n' + r2.data.answer);
  console.log('--------------------------------------------------\n');

  if (r1.data.used_llm && r2.data.used_llm) {
    console.log('🎉 SUCCESS: NVIDIA Nemotron 3 Ultra verified for both Bengali and English!');
  }
}

testNemotron().catch(console.error);
