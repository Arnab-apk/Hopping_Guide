const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execSync } = require('child_process');
const https = require('https');

const repo = 'Arnab-apk/Hopping_Guide';
const tag_name = 'v1.0.0';
const release_title = 'UMA v1.0.0 — Smooth Map Navigation, 60 FPS GPS Tracking, & Group Video Calling';

// 1. Retrieve token via Git Credential Manager
const env = { ...process.env, GIT_TERMINAL_PROMPT: '0', GCM_INTERACTIVE: 'never' };
const credOutput = execSync('git credential fill', {
  input: `url=https://github.com/${repo}.git\n\n`,
  encoding: 'utf-8',
  env: env
});

const lines = credOutput.split('\n');
let token = process.env.GH_TOKEN || process.env.GITHUB_TOKEN;
if (!token) {
  for (const line of lines) {
    if (line.startsWith('password=')) {
      token = line.substring(9).trim();
      break;
    }
  }
}

if (!token) {
  console.error('Error: Could not retrieve GitHub token.');
  process.exit(1);
}

const apkDir = path.resolve('app', 'build', 'app', 'outputs', 'flutter-apk');
const apkFiles = {
  'UMA-v1.0.0-arm64-v8a.apk': path.join(apkDir, 'app-arm64-v8a-release.apk'),
  'UMA-v1.0.0-armeabi-v7a.apk': path.join(apkDir, 'app-armeabi-v7a-release.apk'),
  'UMA-v1.0.0-x86_64.apk': path.join(apkDir, 'app-x86_64-release.apk'),
};

for (const [name, filePath] of Object.entries(apkFiles)) {
  if (!fs.existsSync(filePath)) {
    console.error(`Error: Missing APK file at ${filePath}`);
    process.exit(1);
  }
}

// Generate checksums
console.log('Computing SHA256 checksums...');
const checksumLines = [];
for (const [name, filePath] of Object.entries(apkFiles)) {
  const hash = crypto.createHash('sha256');
  const data = fs.readFileSync(filePath);
  hash.update(data);
  const digest = hash.digest('hex');
  const sizeMb = (fs.statSync(filePath).size / (1024 * 1024)).toFixed(1);
  console.log(`  ${name}: ${digest} (${sizeMb} MB)`);
  checksumLines.push(`${digest}  ${name}`);
}

const checksumPath = path.join(apkDir, 'SHA256SUMS.txt');
fs.writeFileSync(checksumPath, checksumLines.join('\n') + '\n', 'utf-8');

const assetsToUpload = { ...apkFiles, 'SHA256SUMS.txt': checksumPath };

const headers = {
  'Authorization': `Bearer ${token}`,
  'Accept': 'application/vnd.github+json',
  'User-Agent': 'UMA-Release-Publisher',
};

const bodyText = `# UMA v1.0.0 — Major Performance, Smooth Map Experience, Video Calling, & Route Pin Release

Welcome to **UMA v1.0.0**! This milestone release introduces silky smooth map navigation, zero grey tile flashes, 60 FPS decoupled GPS radar tracking, lightweight per-ABI Android APKs, incoming group call ringing alerts, and refined transit routing markers.

---

### 🚀 Key Improvements & Highlights

#### 1. Ultra-Smooth Interactive Map & Navigation
- **Zero Grey Tile Flashes & Smart Buffering**: Expanded tile caching (\`keepBuffer: 2–3\`, \`panBuffer: 1–2\`) with gentle 140ms fade-in transitions. Previously loaded map tiles are retained during momentary network hiccups (\`evictErrorTileStrategy: none\`).
- **Fluid Camera Glide**: Camera motions now utilize natural cubic animation curves (\`Curves.easeInOutCubic\`) tuned to 450ms for snappy, fluid pan/zoom glides across pandals and clusters.
- **Immediate Touch Response**: Tightened pinch-to-zoom movement threshold to 25.0, removing gesture lag and drag stickiness.
- **Greater Kolkata Bounds**: Centered and constrained to greater Kolkata geographic bounds (\`LatLng(21.8, 87.5)\` to \`LatLng(23.4, 89.2)\`), preventing off-map panning.
- **60 FPS Decoupled GPS Avatar**: Decoupled the live user radar pulse animation from auth/avatar layout rebuilds. The GPS radar pulse now animates at a rock-solid 60 FPS without triggering full widget tree passes.

#### 2. Stutter-Free Lazy Lists & Instant Renders
- Clamped stagger entrance delays (\`index.clamp(0, 7)\`) in pandal, search, and dining lists—completely eliminating multi-second scroll delays when fling-scrolling through 50+ items.

#### 3. Lightweight Per-ABI APKs & 61.6% Download Size Reduction
- Split per-ABI release builds (\`arm64-v8a\`, \`armeabi-v7a\`, \`x86_64\`), reducing the modern ARM64 package size down to **122.5 MiB** (from 318.4 MiB universal).
- Verified on physical Motorola Edge 50 (\`versionCode 4020\`, Android 16 / API 36).

#### 4. Squad Social, Ringing Alerts & Group Video Calling
- **Incoming Call Ringing System**: Added full-screen ringing alert and incoming call push notifications for instant squad connection.
- **Fixed End Call Button**: Prominently placed, accessible red "End call" button anchored cleanly below media controls.
- **Resilient Fallback**: Automatic, resilient fallback to hosted squad calling backend (\`uma-group-calling.onrender.com\`).

#### 5. Transit Routing & Clean Station Markers
- **Focused Station Pins**: Trail and itinerary maps display intermediate, boarding, and interchange stations strictly for active transit legs.
- **Pandal Pin Layering**: Numbered festival pins render atop station markers for clean tap target priority.

---

### 📦 Release Assets & Checksums

| Asset | Target Architecture | Size |
|---|---|---|
| \`UMA-v1.0.0-arm64-v8a.apk\` | Modern 64-bit ARM devices (Snapdragon, MediaTek, Pixel, Samsung) | ~122.5 MB |
| \`UMA-v1.0.0-armeabi-v7a.apk\` | Older 32-bit ARM Android devices | ~100.1 MB |
| \`UMA-v1.0.0-x86_64.apk\` | x86_64 Emulators & Chromebooks | ~177.2 MB |
| \`SHA256SUMS.txt\` | Cryptographic checksums | Text |

Verify checksums using:
\`\`\`bash
sha256sum -c SHA256SUMS.txt
\`\`\`

---

### ✅ Quality & Verification
- **Automated Tests**: **439 passing tests** with zero failures across the entire suite.
- **Static Analysis**: \`flutter analyze\` report: **0 issues found**.
- **Physical Device**: Verified installed and launched on Motorola Edge 50.
`;

function request(url, options, data) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            resolve(body ? JSON.parse(body) : null);
          } catch {
            resolve(body);
          }
        } else {
          const err = new Error(`HTTP ${res.statusCode}: ${body}`);
          err.statusCode = res.statusCode;
          reject(err);
        }
      });
    });
    req.on('error', reject);
    if (data) {
      req.write(data);
    }
    req.end();
  });
}

async function main() {
  console.log(`Checking release for tag ${tag_name}...`);
  let release;
  try {
    release = await request(`https://api.github.com/repos/${repo}/releases/tags/${tag_name}`, {
      method: 'GET',
      headers
    });
    console.log(`Found release ID ${release.id}: ${release.html_url}`);

    // Update release details
    console.log('Updating release title and description...');
    release = await request(`https://api.github.com/repos/${repo}/releases/${release.id}`, {
      method: 'PATCH',
      headers: { ...headers, 'Content-Type': 'application/json' }
    }, JSON.stringify({
      name: release_title,
      body: bodyText,
      draft: false,
      prerelease: false
    }));
    console.log('Updated release details successfully.');
  } catch (err) {
    if (err.statusCode === 404) {
      console.log(`Release ${tag_name} not found, creating...`);
      release = await request(`https://api.github.com/repos/${repo}/releases`, {
        method: 'POST',
        headers: { ...headers, 'Content-Type': 'application/json' }
      }, JSON.stringify({
        tag_name,
        target_commitish: 'release/v1.0.0',
        name: release_title,
        body: bodyText,
        draft: false,
        prerelease: false
      }));
      console.log(`Created release ID ${release.id}`);
    } else {
      throw err;
    }
  }

  const existingAssets = {};
  for (const asset of (release.assets || [])) {
    existingAssets[asset.name] = asset.id;
  }

  const baseUploadUrl = release.upload_url.split('{')[0];

  for (const [assetName, assetPath] of Object.entries(assetsToUpload)) {
    if (existingAssets[assetName]) {
      const assetId = existingAssets[assetName];
      console.log(`Deleting existing asset ${assetName} (ID: ${assetId})...`);
      try {
        await request(`https://api.github.com/repos/${repo}/releases/assets/${assetId}`, {
          method: 'DELETE',
          headers
        });
        console.log(`Deleted old ${assetName}`);
      } catch (delErr) {
        console.warn(`Warning: Could not delete ${assetName}:`, delErr.message);
      }
    }

    const fileSize = fs.statSync(assetPath).size;
    const isApk = assetName.endsWith('.apk');
    const contentType = isApk ? 'application/vnd.android.package-archive' : 'text/plain; charset=utf-8';
    console.log(`Uploading ${assetName} (${(fileSize / (1024 * 1024)).toFixed(2)} MB)...`);

    const fileBuffer = fs.readFileSync(assetPath);
    const uploadRes = await request(`${baseUploadUrl}?name=${encodeURIComponent(assetName)}`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': contentType,
        'Content-Length': fileSize,
        'User-Agent': 'UMA-Release-Publisher',
        'Accept': 'application/vnd.github+json'
      }
    }, fileBuffer);

    console.log(`Uploaded ${assetName} -> ${uploadRes.browser_download_url}`);
  }

  console.log('\n--- ALL ASSETS UPLOADED AND RELEASE PUBLISHED SUCCESSFULLY! ---');
  console.log(`Release URL: ${release.html_url}`);
}

main().catch(err => {
  console.error('Fatal error publishing release:', err);
  process.exit(1);
});
