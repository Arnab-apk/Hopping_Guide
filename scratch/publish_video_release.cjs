const { spawnSync }=require('node:child_process');
const fs=require('node:fs');
const repo='Arnab-apk/Hopping_Guide';
const version=process.env.UMA_RELEASE_VERSION||'v0.1.5';
const notes=version==='v0.1.7'?'docs/MAP_NAMES_RELEASE_NOTES.md':version==='v0.1.6'?'docs/GROUP_VIDEO_ACCESS_RELEASE_NOTES.md':'docs/GROUP_VIDEO_RELEASE_NOTES.md';
const credentials=spawnSync('git',['credential','fill'],{input:`url=https://github.com/${repo}.git\n\n`,encoding:'utf8',env:{...process.env,GIT_TERMINAL_PROMPT:'0',GCM_INTERACTIVE:'never'}});
const token=(credentials.stdout||'').split(/\r?\n/).find(line=>line.startsWith('password='))?.slice(9);
if(!token)throw new Error('GitHub credentials unavailable');
const env={...process.env,GH_TOKEN:token};
const gh='C:/Users/arnab/AppData/Local/Microsoft/WinGet/Links/gh.exe';
const run=args=>{const result=spawnSync(gh,args,{env,encoding:'utf8',stdio:['ignore','pipe','pipe'],maxBuffer:4*1024*1024});if(result.status!==0)throw new Error(`GitHub command failed: ${(result.stderr||'').replaceAll(token,'[redacted]').slice(0,500)}`);return result.stdout.trim();};
const dir=`app/build/releases/${version}`;
const source=JSON.parse(fs.readFileSync(`${dir}/source.json`));
async function main(){
  const push=spawnSync('git',['push','origin',`release/group-video-${version}`],{encoding:'utf8',stdio:['ignore','pipe','pipe']});
  if(push.status!==0)throw new Error('Release source push failed');
  console.log('Release source pushed:',source.commit);
  let release=JSON.parse(run(['api',`repos/${repo}/releases?per_page=30`])).find(item=>item.tag_name===version);
  if(!release){
    console.log(run(['release','create',version,'--repo',repo,'--target',source.commit,'--title',`UMA ${version} — ${version==='v0.1.7'?'More map names':version==='v0.1.6'?'Easier access to group calls':'Group video calling'}`,'--notes-file',notes,'--draft']));
    for(let attempt=0;attempt<5 && !release;attempt++){
      await new Promise(resolve=>setTimeout(resolve,1000));
      release=JSON.parse(run(['api',`repos/${repo}/releases?per_page=30`])).find(item=>item.tag_name===version);
    }
    if(!release)throw new Error('New draft release is not visible yet; rerun safely to resume.');
  }
  const missing=[`UMA-${version}.apk`,'SHA256SUMS.txt'].filter(name=>!release.assets.some(asset=>asset.name===name));
  if(missing.length){
    console.log('Uploading signed APK and checksum...');
    run(['release','upload',version,...missing.map(name=>`${dir}/${name}`),'--repo',repo]);
  }
  release=JSON.parse(run(['api',`repos/${repo}/releases/${release.id}`]));
  const apk=release.assets.find(asset=>asset.name===`UMA-${version}.apk`);
  if(!apk||apk.size!==source.size)throw new Error('Uploaded APK size verification failed');
  if(apk.digest&&apk.digest!==`sha256:${source.sha256}`)throw new Error('Uploaded APK digest verification failed');
  if(!release.assets.some(asset=>asset.name==='SHA256SUMS.txt'))throw new Error('Uploaded checksum missing');
  run(['release','edit',version,'--repo',repo,'--draft=false','--latest']);
  const published=JSON.parse(run(['api',`repos/${repo}/releases/tags/${version}`]));
  if(published.draft)throw new Error('Release is still a draft');
  console.log('Published verified release:',published.html_url);
  console.log('APK SHA-256:',source.sha256);
}
main().catch(error=>{console.error(String(error.message).replaceAll(token,'[redacted]'));process.exitCode=1;});
