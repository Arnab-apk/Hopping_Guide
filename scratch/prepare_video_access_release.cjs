const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
const index=path.resolve('scratch',`access-release-index-${Date.now()}`);
const env={...process.env,GIT_INDEX_FILE:index};
const git=(args,options={})=>execFileSync('git',args,{env,encoding:'utf8',stdio:['pipe','pipe','pipe'],...options}).trim();
try {
  const parent=git(['rev-parse','release/group-video-v0.1.5']);
  git(['read-tree',parent]);
  const files=['app/lib/widgets/group_video_call_button.dart','app/lib/screens/group_screen.dart','app/lib/screens/squad_chat_screen.dart','app/test/squad_screen_simplified_test.dart','docs/GROUP_VIDEO_CALLING.md','docs/GROUP_VIDEO_ACCESS_RELEASE_NOTES.md'];
  for(const file of files){
    const hash=git(['hash-object','-w','--',file]);
    git(['update-index','--add','--cacheinfo',`100644,${hash},${file}`]);
  }
  const tree=git(['write-tree']);
  const commit=git(['commit-tree',tree,'-p',parent],{input:'feat(video): make group calling accessible from every group tab\n\nUse a prominent full-width call button with a 48-pixel minimum touch target. Show the same action in standalone chat, and verify direct navigation from the default Trail tab to the group lobby.\n'});
  git(['update-ref','refs/heads/release/group-video-v0.1.6',commit]);
  const dir='app/build/releases/v0.1.6';fs.mkdirSync(dir,{recursive:true});
  const apk=`${dir}/UMA-v0.1.6.apk`;fs.copyFileSync('app/build/app/outputs/flutter-apk/app-release.apk',apk);
  const sha256=crypto.createHash('sha256').update(fs.readFileSync(apk)).digest('hex');
  fs.writeFileSync(`${dir}/SHA256SUMS.txt`,`${sha256}  UMA-v0.1.6.apk\n`);
  fs.writeFileSync(`${dir}/source.json`,JSON.stringify({commit,sha256,size:fs.statSync(apk).size}));
  console.log(JSON.stringify({commit,sha256,size:fs.statSync(apk).size}));
}finally{if(fs.existsSync(index))fs.unlinkSync(index);}
