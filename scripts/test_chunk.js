async function checkChunk() {
  const res = await fetch('https://sharodiya.com/_next/static/chunks/3grdzqphzlwe2.js');
  const text = await res.text();
  console.log('Chunk length:', text.length);
  // Find strings and text
  const strings = [...text.matchAll(/"([^"\\]{4,60})"/g)].map(m => m[1]);
  console.log('Sample strings in welcome chunk:', strings.slice(0, 30));
}
checkChunk().catch(console.error);
