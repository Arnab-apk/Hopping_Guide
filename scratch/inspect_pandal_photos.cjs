const fs = require('node:fs');
async function main() {
  if (process.argv.includes('--image')) {
    const imageUrl = 'https://www.durgapujakolkata.in/api/r2-image/images/1787429222182-img_20250927_164900.jpg';
    for (const method of ['HEAD', 'GET']) {
      const result = await fetch(imageUrl, { method, signal: AbortSignal.timeout(15000) });
      console.log(JSON.stringify({ method, status: result.status, type: result.headers.get('content-type') }));
      if (method === 'GET' && result.ok && result.headers.get('content-type')?.startsWith('image/')) {
        fs.writeFileSync('scratch/pandal-photo-preview.jpg', Buffer.from(await result.arrayBuffer()));
      } else if (result.body) await result.body.cancel();
    }
    return;
  }
  const url = 'https://www.durgapujakolkata.in/paras';
  const response = await fetch(url);
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  const html = await response.text();
  const chunks = [...html.matchAll(/self\.__next_f\.push\((\[.*?\])\)<\/script>/gs)].flatMap(m => { try { return JSON.parse(m[1]).filter(x => typeof x === 'string'); } catch { return []; } }).join('');
  const i = chunks.indexOf('Ultadanga');
  console.log(JSON.stringify({ bytes: html.length, snippet: chunks.slice(Math.max(0,i-300),i+2000), beginning: chunks.slice(0,1000), scripts: [...html.matchAll(/<script[^>]+src="([^"]+)"/g)].map(m=>m[1]) }, null, 2));
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
