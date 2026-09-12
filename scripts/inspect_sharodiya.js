async function inspectAll() {
  const routes = ['/auth', '/map', '/pandals', '/routes', '/groups'];
  for (const r of routes) {
    const res = await fetch('https://sharodiya.com' + r);
    const html = await res.text();
    // extract chunk scripts
    const chunks = [...html.matchAll(/src=[\"'](\/_next\/static\/chunks\/[^\"']+\.js)[\"']/g)].map(m => m[1]);
    console.log(`=== Route: ${r} (chunks: ${chunks.length}) ===`);
    // fetch each page-specific chunk (chunks not in common like 16owh3fyuk6gi.js)
    for (const chunk of chunks.slice(-2)) {
      const cRes = await fetch('https://sharodiya.com' + chunk);
      const cText = await cRes.text();
      const strings = [...cText.matchAll(/"([^"\\]{4,50})"/g)].map(m => m[1]);
      console.log(`  Chunk ${chunk}:`, strings.filter(s => !s.startsWith('/') && !s.includes('px') && !s.includes(';') && s.length > 5).slice(0, 15));
    }
  }
}
inspectAll().catch(console.error);
