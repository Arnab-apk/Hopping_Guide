const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
const index=path.resolve('scratch',`map-release-index-${Date.now()}`);
const env={...process.env,GIT_INDEX_FILE:index};
const git=(args,options={})=>execFileSync('git',args,{env,encoding:'utf8',stdio:['pipe','pipe','pipe'],...options}).trim();
try {
  const parent=git(['rev-parse','release/group-video-v0.1.6']);git(['read-tree',parent]);
  for(const file of ['app/lib/screens/map_screen.dart','app/test/launch_layout_test.dart','docs/MAP_NAMES_RELEASE_NOTES.md']){
    const hash=git(['hash-object','-w','--',file]);git(['update-index','--add','--cacheinfo',`100644,${hash},${file}`]);
  }
  const tree=git(['write-tree']);
  const commit=git(['commit-tree',tree,'-p',parent],{input:'feat(map): show denser place labels with a remembered rendering preference\n\nEnable finer OSM tiles without changing the camera position. Provide a larger-label fallback in map tools, keep the provider zoom limit, and reduce buffered tiles. Verify viewport stability when changing density and map layouts across display sizes.\n'});
  git(['update-ref','refs/heads/release/group-video-v0.1.7',commit]);
  const dir='app/build/releases/v0.1.7';fs.mkdirSync(dir,{recursive:true});
  const apk=`${dir}/UMA-v0.1.7.apk`;fs.copyFileSync('app/build/app/outputs/flutter-apk/app-release.apk',apk);
  const sha256=crypto.createHash('sha256').update(fs.readFileSync(apk)).digest('hex');
  fs.writeFileSync(`${dir}/SHA256SUMS.txt`,`${sha256}  UMA-v0.1.7.apk\n`);
  fs.writeFileSync(`${dir}/source.json`,JSON.stringify({commit,sha256,size:fs.statSync(apk).size}));console.log(JSON.stringify({commit,sha256,size:fs.statSync(apk).size}));
}finally{if(fs.existsSync(index))fs.unlinkSync(index);}
