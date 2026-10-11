const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const indexPath = path.resolve('scratch', `call-notifications-index-${Date.now()}`);
const env = { ...process.env, GIT_INDEX_FILE: indexPath };
const git = (args, options = {}) => execFileSync('git', args, {
  env, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'], ...options,
}).trim();
try {
  const ref = 'refs/heads/deploy/stream-group-video';
  const parent = git(['rev-parse', ref]);
  git(['read-tree', parent]);
  for (const file of ['server/src/index.ts', 'server/src/call-notifications.ts', 'server/test/test-call-notifications.js']) {
    const hash = git(['hash-object', '-w', '--', file]);
    git(['update-index', '--add', '--cacheinfo', `100644,${hash},${file}`]);
  }
  const tree = git(['write-tree']);
  const commit = git(['commit-tree', tree, '-p', parent], {
    input: 'feat(video): notify current group members of incoming calls via FCM\n',
  });
  git(['update-ref', ref, commit, parent]);
  git(['push', 'origin', 'deploy/stream-group-video']);
  fs.writeFileSync('scratch/call-notifications-deployment.json', JSON.stringify({ commit }));
  console.log('Calling server source pushed:', commit);
} finally { if (fs.existsSync(indexPath)) fs.unlinkSync(indexPath); }
