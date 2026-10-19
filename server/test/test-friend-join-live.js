// Real signed-in client requests exercise deployed Firestore rules. Admin access
// is used only to provision/clean up our temporary identity and verify no plan edits.
require('dotenv').config();
const assert = require('node:assert/strict');
const fs = require('node:fs');
const crypto = require('node:crypto');
const {initializeApp, cert, deleteApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

async function main() {
  const code = process.env.FRIEND_TEST_GROUP_CODE;
  assert.ok(code, 'Set FRIEND_TEST_GROUP_CODE to explicitly select the group to test');
  const credentials = process.env.FIREBASE_SERVICE_ACCOUNT_JSON
    ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON)
    : JSON.parse(fs.readFileSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, 'utf8'));
  const app = initializeApp({credential:cert(credentials)});
  const auth = getAuth(app), db = getFirestore(app);
  const uid = `friend_join_check_${crypto.randomBytes(8).toString('hex')}`;
  const apiKey = fs.readFileSync('../app/lib/firebase_options.dart','utf8').match(/apiKey:\s*'([^']+)'/)[1];
  const root = `projects/${credentials.project_id}/databases/(default)/documents`;
  const base = `https://firestore.googleapis.com/v1/${root}`;
  let token, group, created = false, originalPlan;
  const encode = value => {
    if(value === null)return {nullValue:null};
    if(typeof value === 'string')return {stringValue:value};
    if(typeof value === 'boolean')return {booleanValue:value};
    if(typeof value === 'number')return Number.isInteger(value)?{integerValue:String(value)}:{doubleValue:value};
    if(Array.isArray(value))return {arrayValue:{values:value.map(encode)}};
    return {mapValue:{fields:Object.fromEntries(Object.entries(value).map(([k,v])=>[k,encode(v)]))}};
  };
  const decode = value => {
    if('stringValue' in value)return value.stringValue;
    if('integerValue' in value)return Number(value.integerValue);
    if('doubleValue' in value)return value.doubleValue;
    if('booleanValue' in value)return value.booleanValue;
    if('arrayValue' in value)return (value.arrayValue.values||[]).map(decode);
    if('mapValue' in value)return Object.fromEntries(Object.entries(value.mapValue.fields||{}).map(([k,v])=>[k,decode(v)]));
    return null;
  };
  const request = async (url, method='GET', body) => {
    const r=await fetch(url,{method,headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(25000)});
    const data=await r.json();
    assert.equal(r.status,200,`${method} ${url.replace(base,'').split('?')[0]}: ${data.error?.status||''}`);
    return data;
  };
  try {
    await auth.createUser({uid,displayName:'Temporary friend join check'});created=true;
    const customToken=await auth.createCustomToken(uid);
    const signin=await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${apiKey}`,{
      method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({token:customToken,returnSecureToken:true}),signal:AbortSignal.timeout(25000)});
    assert.equal(signin.status,200,'Temporary friend sign-in');token=(await signin.json()).idToken;
    const found=await request(`${base}:runQuery`,'POST',{structuredQuery:{from:[{collectionId:'squads'}],where:{fieldFilter:{field:{fieldPath:'squadCode'},op:'EQUAL',value:{stringValue:code}}},limit:1}});
    const document=found.find(row=>row.document)?.document;
    assert.ok(document,'Invite code resolves for a newly signed-in friend');
    group=document.name.split('/').pop();
    const groupRef=db.collection('squads').doc(group);
    originalPlan=(await groupRef.get()).data().chosenPandals||[];
    assert.ok(originalPlan.length>0,'Existing group has a shared hopping list');
    const member={id:uid,name:'Temporary friend join check',lat:0,lng:0,status:'Testing join',is_host:false,is_user:false,share_location:false,is_online:true,battery:100,batteryLevel:100,color:4294947584,last_seen:Date.now()};
    await request(`${base}:commit`,'POST',{writes:[
      {transform:{document:document.name,fieldTransforms:[{fieldPath:'membersUid',appendMissingElements:{values:[{stringValue:uid}]}}]}},
      {update:{name:`${document.name}/members/${uid}`,fields:encode(member).mapValue.fields}},
    ]});
    const joined=decode({mapValue:{fields:(await request(`${base}/squads/${group}`)).fields}});
    assert.ok(joined.membersUid.includes(uid),'Friend added to real group roster');
    assert.deepEqual(joined.chosenPandals,originalPlan,'Friend receives the complete existing ordered list');
    const members=await request(`${base}/squads/${group}/members`);
    assert.ok(members.documents.some(doc=>doc.name.endsWith(`/members/${uid}`)),'Friend can read group members');
    const saved=await request(`${base}:runQuery`,'POST',{structuredQuery:{from:[{collectionId:'squads'}],where:{fieldFilter:{field:{fieldPath:'membersUid'},op:'ARRAY_CONTAINS',value:{stringValue:uid}}}}});
    assert.ok(saved.some(row=>row.document?.name===document.name),'Group appears in friend account My groups');
    assert.ok(joined.chosenPandals.every(stop=>Number.isFinite(stop.lat)&&Number.isFinite(stop.lng)),'Every shared stop has map coordinates');
    const result={groupName:joined.name,code,joined:true,memberRead:true,myGroups:true,stopCount:joined.chosenPandals.length,firstStop:joined.chosenPandals[0].name,activeStopIndex:joined.activeStopIndex,hoppingActive:joined.isHoppingActive,allStopsHaveCoordinates:true,checkedAt:new Date().toISOString()};
    fs.mkdirSync('../app/build/phone-feature-audit',{recursive:true});
    fs.writeFileSync('../app/build/phone-feature-audit/friend-join-result.json',JSON.stringify(result,null,2));
    console.log('FRIEND JOIN PASSED:',JSON.stringify(result));
  } finally {
    if(group){
      const ref=db.collection('squads').doc(group);
      await ref.collection('members').doc(uid).delete();
      await ref.update({membersUid:FieldValue.arrayRemove(uid)});
      const after=(await ref.get()).data();
      assert.ok(!after.membersUid.includes(uid),'Temporary membership removed');
      assert.deepEqual(after.chosenPandals,originalPlan,'Original shared plan preserved');
    }
    if(created)await auth.deleteUser(uid);
    await db.terminate();await deleteApp(app);
    console.log('Temporary friend identity/membership removed; shared plan preserved.');
  }
}
main().catch(error=>{console.error('Friend join failed:',error.code||error.name,error.operator?error.message.split('\n')[0]:'check connectivity/configuration');process.exitCode=1;});
