// Public-page photo metadata only: no sign-in, uploads or private albums.
const fs = require('node:fs/promises');
const path = require('node:path');
const origin = 'https://www.durgapujakolkata.in';
const root = path.resolve(__dirname, '..');

function flightObjects(html) {
  const chunks = [...html.matchAll(/self\.__next_f\.push\((\[.*?\])\)<\/script>/gs)]
    .flatMap(m => {
      try { return JSON.parse(m[1]).filter(x => typeof x === 'string'); }
      catch { return []; }
    }).join('');
  const objects = [];
  for (const line of chunks.split('\n')) {
    const colon = line.indexOf(':');
    if (colon < 0) continue;
    try { objects.push(JSON.parse(line.slice(colon + 1))); } catch { /* non-JSON flight row */ }
  }
  // Large Flight text rows can contain JSON without a trailing newline.
  // Extract balanced objects as data; never execute the site's scripts.
  for (const match of chunks.matchAll(/\{"(?:id|pandal)":/g)) {
    const value = readObject(chunks, match.index);
    if (value) objects.push(value);
  }
  const creditsAt = chunks.indexOf('"uploaderMap":');
  if (creditsAt >= 0) {
    const value = readObject(chunks, chunks.indexOf('{', creditsAt));
    if (value) objects.push({ uploaderMap: value });
  }
  return objects;
}

function readObject(text, start) {
  let depth = 0, quoted = false, escaped = false;
  for (let i = start; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === '"') quoted = false;
    } else if (c === '"') quoted = true;
    else if (c === '{') depth++;
    else if (c === '}' && --depth === 0) {
      try { return JSON.parse(text.slice(start, i + 1)); } catch { return null; }
    }
  }
  return null;
}

function visit(value, predicate, result = []) {
  if (!value || typeof value !== 'object') return result;
  if (predicate(value)) result.push(value);
  for (const child of Object.values(value)) visit(child, predicate, result);
  return result;
}

function normalize(name) {
  return name.toLowerCase().replace(/baghbazar/g, 'bagbazar')
    .replace(/sarbojonin|sarbojanin|sarbojonine/g, 'sarbojanin')
    .replace(/pally/g, 'palli').replace(/pratyay/g, 'prattay')
    .replace(/\b(sarbojanin|durgotsab|durgotsav|sarodotsab|durga|puja|pujo|pandal|committee|exhibition)\b/g, '')
    .replace(/[^a-z0-9]/g, '');
}

function distance(a, b) {
  const rad = x => x * Math.PI / 180;
  const dlat = rad(a.lat - b.lat), dlon = rad(a.lng - b.lng);
  const h = Math.sin(dlat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dlon / 2) ** 2;
  return 6371000 * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
}

async function page(url) {
  const response = await fetch(url, { signal: AbortSignal.timeout(25000) });
  if (!response.ok) throw new Error(`HTTP ${response.status}: ${url}`);
  return flightObjects(await response.text());
}

async function main() {
  const args = process.argv.slice(2);
  const apply = args.includes('--apply');
  const limitArg = args.find(x => x.startsWith('--limit='));
  const limit = limitArg ? Number(limitArg.split('=')[1]) : 12;
  if (!Number.isInteger(limit) || limit < 1 || limit > 100) throw new Error('Use --limit=1..100');
  const locals = JSON.parse(await fs.readFile(path.join(root, 'app/assets/data/pandals.json'), 'utf8'));
  const directory = await page(`${origin}/paras`);
  const remotes = [...new Map(visit(directory, x => x.paraName && x.slug).map(x => [x.slug, x])).values()];
  if (remotes.length === 0) throw new Error('No directory records found; source format may have changed.');
  const matches = [];
  for (const local of locals) {
    const candidates = remotes.filter(x => normalize(x.paraName) === normalize(local.name));
    // Ambiguous names or conflicting coordinates need manual review.
    if (candidates.length !== 1 || !Number.isFinite(candidates[0].lat) ||
        !Number.isFinite(candidates[0].lng) || distance(local, candidates[0]) > 1000) continue;
    const remote = candidates[0];
    if (remote.imageUrl || remote.gallery?.length) matches.push({ local, remote });
  }
  const target = path.join(root, 'app/assets/data/pandal_photos.json');
  let manifest = { version: 1, pandals: {} };
  try { manifest = JSON.parse(await fs.readFile(target, 'utf8')); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  let updated = 0, photoCount = 0;
  const failures = [];
  for (const { local, remote } of matches.slice(0, limit)) {
    const sourceUrl = `${origin}/paras/${remote.slug}`;
    try {
      const detail = await page(sourceUrl);
      const record = visit(detail, x => x.paraName && x.slug === remote.slug)[0];
      if (!record) throw new Error('Missing detail record');
      const credits = visit(detail, x => x.uploaderMap)[0]?.uploaderMap || {};
      const urls = [...new Set([record.imageUrl, ...(Array.isArray(record.gallery) ? record.gallery : [])])]
        .filter(x => typeof x === 'string' && x.startsWith('/api/r2-image/images/'))
        .slice(0, 6);
      const photos = [];
      for (const raw of urls) {
        const url = new URL(raw, origin);
        url.search = ''; // Never retain deployment tokens or signed storage URLs.
        let response = await fetch(url, { method: 'HEAD', signal: AbortSignal.timeout(20000) });
        if (!response.ok) {
          // The public proxy accepts GET but rejects HEAD (403).
          response = await fetch(url, { signal: AbortSignal.timeout(20000) });
        }
        const isImage = response.ok && response.headers.get('content-type')?.startsWith('image/');
        if (response.body) await response.body.cancel();
        if (!isImage) continue;
        const filename = decodeURIComponent(url.pathname.split('/').pop());
        const existing = manifest.pandals[local.id]?.find(x => x.url === url.href);
        photos.push(existing || {
          url: url.href,
          caption: '',
          credit: credits[filename] || credits[`images/${filename}`] || '',
          source_url: sourceUrl,
          rights_status: 'unverified',
          // Source listing edition is NOT evidence of the photo's year.
        });
      }
      if (photos.length === 0) { failures.push({ id: local.id, reason: 'No reachable gallery photographs' }); continue; }
      // Preserve manually curated photographs on refresh.
      const old = manifest.pandals[local.id] || [];
      manifest.pandals[local.id] = [...new Map([...old, ...photos].map(x => [x.url, x])).values()];
      updated++;
      photoCount += photos.length;
      console.log(`${local.id}: ${photos.length} reachable photographs`);
    } catch (error) { failures.push({ id: local.id, reason: error.message }); }
  }
  if (apply && updated) {
    manifest.updated_at = new Date().toISOString();
    await fs.writeFile(target, JSON.stringify(manifest, null, 2) + '\n');
  }
  console.log(JSON.stringify({ mode: apply ? 'apply' : 'dry-run', directoryRecords: remotes.length,
    confidentPhotoMatches: matches.length, updatedPandals: updated, photoCount, failures }, null, 2));
  if (updated === 0) process.exitCode = 1;
}

module.exports = { flightObjects, normalize, distance };
if (require.main === module) main().catch(error => { console.error(error.message); process.exitCode = 1; });
