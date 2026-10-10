// Snapshot only the calling backend into a deployment branch. Preserve the
// user's working tree and ordinary index, including their other app changes.
const { execFileSync, spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const branch = 'deploy/stream-group-video';
const indexPath = path.resolve('scratch', `video-index-${crypto.randomBytes(6).toString('hex')}`);
const env = { ...process.env, GIT_INDEX_FILE: indexPath };
const git = (args, options = {}) => execFileSync('git', args, { env, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'], ...options }).trim();
if (spawnSync('git', ['show-ref', '--verify', '--quiet', `refs/heads/${branch}`]).status === 0) throw new Error('Deployment branch already exists; inspect it before updating.');
try {
  const parent = git(['rev-parse', 'HEAD']);
  git(['read-tree', parent]);
  const files = ['server/package.json', 'server/package-lock.json', 'server/Dockerfile',
    'server/src/index.ts', 'server/src/video.ts', 'server/test/configure-video.js',
    'server/test/test-video.js', 'server/test/test-video-live.js', 'render.yaml',
    'docs/GROUP_VIDEO_CALLING.md'];
  for (const file of files) {
    const hash = git(['hash-object', '-w', '--', file]);
    git(['update-index', '--add', '--cacheinfo', `100644,${hash},${file}`]);
  }
  const tree = git(['write-tree']);
  const commit = git(['commit-tree', tree, '-p', parent], {
    input: 'feat(video): deploy private Firebase-authenticated Stream group rooms\n\nVerify current group membership before issuing expiring call tokens. Configure a dedicated private call type, include security tests, and provide free Render deployment configuration.\n',
  });
  git(['update-ref', `refs/heads/${branch}`, commit, '0000000000000000000000000000000000000000']);
  console.log('Deployment branch:', branch);
  console.log('Deployment commit:', commit);
} finally {
  if (fs.existsSync(indexPath)) fs.unlinkSync(indexPath);
}
