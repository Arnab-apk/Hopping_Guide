// Deploy secrets through Render secret files. Do not emit their contents or
// include them in command arguments, Git commits, or service metadata output.
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const dotenv = require('../server/node_modules/dotenv');
const config = dotenv.parse(fs.readFileSync('server/.env'));
const outputPath = path.resolve('scratch/render_video_service.json');
if (fs.existsSync(outputPath)) throw new Error('Service metadata already exists; inspect before creating another service.');
const secretPath = path.resolve('server/.env.render-video');
if (!config.STREAM_API_KEY || !config.STREAM_API_SECRET || !config.GOOGLE_APPLICATION_CREDENTIALS) throw new Error('Required local calling credentials are missing.');
fs.writeFileSync(secretPath, `STREAM_API_KEY=${config.STREAM_API_KEY}\nSTREAM_API_SECRET=${config.STREAM_API_SECRET}\n`);
try {
  const args = ['services', 'create', '--name', 'uma-group-calling', '--type', 'web_service',
    '--repo', 'https://github.com/Arnab-apk/Hopping_Guide', '--branch', 'deploy/stream-group-video',
    '--runtime', 'node', '--plan', 'free', '--region', 'singapore', '--root-directory', 'server',
    '--build-command', 'npm ci && npm run build', '--start-command', 'npm start',
    '--health-check-path', '/health', '--auto-deploy=false',
    '--env-var', 'NODE_VERSION=22', '--env-var', 'FIREBASE_PROJECT_ID=kolkata-puja-2026',
    '--env-var', 'GOOGLE_APPLICATION_CREDENTIALS=/etc/secrets/firebase-admin.json',
    '--env-var', 'DOTENV_CONFIG_PATH=/etc/secrets/stream-video.env',
    '--secret-file', `stream-video.env:${secretPath}`,
    '--secret-file', `firebase-admin.json:${config.GOOGLE_APPLICATION_CREDENTIALS}`,
    '--confirm', '--output', 'json'];
  const result = spawnSync('render', args, { encoding: 'utf8', timeout: 90000, windowsHide: true });
  if (result.status !== 0) {
    const message = (result.stderr || 'Render service creation failed.')
      .replaceAll(config.STREAM_API_SECRET, '[redacted]').replace(/-----BEGIN PRIVATE KEY-----[\s\S]*?-----END PRIVATE KEY-----/g, '[redacted]');
    throw new Error(message.slice(0, 1600));
  }
  const data = JSON.parse(result.stdout);
  const service = data.service || data;
  const metadata = { id: service.id, name: service.name,
    url: service.serviceDetails?.url, plan: service.serviceDetails?.plan,
    dashboardUrl: service.dashboardUrl, branch: service.branch };
  if (!metadata.id) throw new Error('Service created, but metadata format is unexpected; inspect service list.');
  fs.writeFileSync(outputPath, JSON.stringify(metadata, null, 2));
  console.log(JSON.stringify(metadata));
} finally {
  if (fs.existsSync(secretPath)) fs.unlinkSync(secretPath);
}
