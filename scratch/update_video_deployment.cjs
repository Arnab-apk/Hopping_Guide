const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const indexPath = path.resolve('scratch', `video-update-index-${Date.now()}`);
const env = { ...process.env, GIT_INDEX_FILE: indexPath };
const git = (args, options = {}) => execFileSync('git', args, { env, encoding: 'utf8', stdio: ['pipe','pipe','pipe'], ...options }).trim();
try {
  const ref = 'refs/heads/deploy/stream-group-video';
  const parent = git(['rev-parse', ref]);
  git(['read-tree', parent]);
  for (const file of ['server/src/video.ts', 'server/test/test-video-live.js']) {
    const hash = git(['hash-object','-w','--',file]);
    git(['update-index','--add','--cacheinfo',`100644,${hash},${file}`]);
  }
  const tree = git(['write-tree']);
  const commit = git(['commit-tree',tree,'-p',parent], { input: 'fix(video): add safe deployment diagnostics and hosted endpoint verification\n' });
  git(['update-ref',ref,commit,parent]);
  console.log('Deployment commit:',commit);
} finally { if (fs.existsSync(indexPath)) fs.unlinkSync(indexPath); }
