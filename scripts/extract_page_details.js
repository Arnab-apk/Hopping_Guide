async function extractPageDetails() {
  const routes = ['/auth', '/map', '/pandals', '/routes', '/groups'];
  for (const r of routes) {
    const res = await fetch('https://sharodiya.com' + r);
    const html = await res.text();
    
    // In Next.js App Router, page code is often in self.__next_f pushes
    const pushes = [...html.matchAll(/self\.__next_f\.push\(\[1,"(.*)"\]\)/g)].map(m => m[1]);
    const unescaped = pushes.map(p => p.replace(/\\"/g, '"').replace(/\\n/g, '\n').replace(/\\\\/g, '\\')).join('\n');
    
    // Look for text, titles, headings, buttons, tabs
    console.log(`\n=================== ${r} ===================`);
    const titles = [...unescaped.matchAll(/"children":(\[[^\]]+\]|"[^"]+")/g)].map(m => m[1]).filter(s => typeof s === 'string' && s.length > 5 && !s.includes('$'));
    console.log('Sample content snippets:', titles.slice(0, 10));

    // Also look for specific chunks mentioned in unescaped
    const pageChunks = [...unescaped.matchAll(/\/_next\/static\/chunks\/[a-zA-Z0-9_-]+\.js/g)].map(m => m[0]);
    console.log('Page chunks:', [...new Set(pageChunks)]);
  }
}
extractPageDetails().catch(console.error);
