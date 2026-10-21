'use strict';
const {createHmac,timingSafeEqual}=require('node:crypto');
const VERSION='answer-cache-v1';
function signature(secret,key,version,expires,json) {
 return createHmac('sha256',secret).update(JSON.stringify([key,version,expires,json])).digest('hex');
}
// Auth/quota checks happen in the callable before this cache. No question,
// account ID or user-specific planner interpretation is stored here.
function createSharedAnswerCache({db,secret,version,now=Date.now,timestamp=n=>n,ttlMs=86400000}) {
 const signedVersion=`${VERSION}:${version}`;
 const ref=key=>db.collection('_askAiAnswerCache').doc(key);
 return {
  async get(key){
   const snap=await ref(key).get();if(!snap.exists)return null;const d=snap.data();
   if(d.version!==signedVersion||!Number.isSafeInteger(d.expires)||d.expires<=now()||typeof d.json!=='string'||Buffer.byteLength(d.json)>262144||!/^[a-f0-9]{64}$/.test(d.signature||''))return null;
   const expected=signature(secret,key,d.version,d.expires,d.json);
   if(!timingSafeEqual(Buffer.from(expected,'hex'),Buffer.from(d.signature,'hex')))return null;
   try {const r=JSON.parse(d.json);return r.status==='answered'&&r.answerMode==='sources-only'?r:null;}catch{return null;}
  },
  async put(key,result){
   if(result.status!=='answered'||result.answerMode!=='sources-only'||(!result.hits?.length&&!result.answer))return;
   // Only supported public-source fields; omit the per-user understood field.
   const payload={status:'answered',answerMode:'sources-only',paragraphs:[],speech_urdu:'',speech_english:'',hits:result.hits||[]};
   if(result.answer)payload.answer=result.answer;
   if(result.followup)payload.followup=result.followup;
   const json=JSON.stringify(payload);if(Buffer.byteLength(json)>262144)return;
   const expires=now()+ttlMs;
   await ref(key).set({version:signedVersion,expires,expireAt:timestamp(expires),json,
    signature:signature(secret,key,signedVersion,expires,json)});
  }
 };
}
// A cache outage must not hold a user request open. An already-started write
// may finish later; it only stores the same immutable validated source result.
async function optionalCache(work,budgetMs=1500){
 let timer;try{return await Promise.race([Promise.resolve().then(work),new Promise(resolve=>{timer=setTimeout(()=>resolve(null),budgetMs);})]);}
 catch{console.warn('ask-shared-cache-unavailable');return null;}finally{clearTimeout(timer);}
}
module.exports={createSharedAnswerCache,optionalCache};
