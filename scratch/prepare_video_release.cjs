const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');
const index = path.resolve('scratch', `release-index-${Date.now()}`);
const env = {...process.env, GIT_INDEX_FILE:index};
const git = (args, opts={}) => execFileSync('git',args,{env,encoding:'utf8',stdio:['pipe','pipe','pipe'],maxBuffer:32*1024*1024,...opts}).trim();
try {
  const parent=git(['rev-parse','deploy/stream-group-video']);
  git(['read-tree',parent]);
  const candidates=git(['ls-files','-c','-o','--exclude-standard','--','app']).split(/\r?\n/);
  const excluded=/(^|\/)(build|\.dart_tool|\.gradle|\.widget_preview|ephemeral|node_modules)(\/|$)|firebase_options\.dart$|google-services\.json$|GoogleService-Info\.plist$|(^|\/)(\.env[^/]*|key\.properties|local\.properties)$|\.(jks|keystore)$/;
  const files=[...new Set(candidates.filter(file=>file && !excluded.test(file) && fs.existsSync(file)))];
  files.push('docs/GROUP_VIDEO_CALLING.md','docs/GROUP_VIDEO_RELEASE_NOTES.md');
  const config=require('../server/node_modules/dotenv').parse(fs.readFileSync('server/.env'));
  const indexEntries=[];
  for(const file of files) {
    const buffer=fs.readFileSync(file);
    if(buffer.includes(Buffer.from(config.STREAM_API_SECRET)) || buffer.includes(Buffer.from('-----BEGIN PRIVATE KEY-----')))throw new Error(`Credential scan rejected ${file}`);
    const hash=git(['hash-object','-w','--',file]);
    indexEntries.push(`100644 ${hash}\t${file}`);
  }
  git(['update-index','--index-info'],{input:indexEntries.join('\n')+'\n'});
  const generated=git(['ls-files','--','server/node_modules','server/dist','app/android/build']).split(/\r?\n/).filter(Boolean);
  if(generated.length)git(['update-index','--force-remove','--stdin'],{input:generated.join('\n')+'\n'});
  const tree=git(['write-tree']);
  const commit=git(['commit-tree',tree,'-p',parent],{input:'release: snapshot verified Android app with private group video calling\n\nInclude the existing app source used for the signed 0.1.5 (2003) build. Add Stream calling UI, authenticated session API integration, tests and deployment documentation. Secrets and generated build output are excluded.\n'});
  git(['update-ref','refs/heads/release/group-video-v0.1.5',commit]);
  const out='app/build/releases/v0.1.5'; fs.mkdirSync(out,{recursive:true});
  const apk=`${out}/UMA-v0.1.5.apk`;
  fs.copyFileSync('app/build/app/outputs/flutter-apk/app-release.apk',apk);
  const sha256=crypto.createHash('sha256').update(fs.readFileSync(apk)).digest('hex');
  fs.writeFileSync(`${out}/SHA256SUMS.txt`,`${sha256}  UMA-v0.1.5.apk\n`);
  fs.writeFileSync(`${out}/source.json`,JSON.stringify({commit,sha256,size:fs.statSync(apk).size}));
  console.log(JSON.stringify({commit,sha256,size:fs.statSync(apk).size,sourceFiles:files.length}));
} finally {if(fs.existsSync(index))fs.unlinkSync(index);}
