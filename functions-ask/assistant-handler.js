'use strict';
const {createHash,createHmac,timingSafeEqual}=require('node:crypto');
const {requestData}=require('./assistant-contract');
const {localResponse}=require('./assistant-local');
const {answerConversation}=require('./conversational');
const {optionalCache}=require('./shared-answer-cache');
const VERSION='conversation-v1.1';
const notesVersion=createHash('sha256').update(JSON.stringify(require('./scholarly-notes.json'))).digest('hex');
function cacheKey({uid,question,language,model,version}){
 return createHash('sha256').update(JSON.stringify([VERSION,uid,question.normalize('NFKC').trim().replace(/\s+/g,' '),language,model,version])).digest('hex');
}
function signature(secret,key,json,expires){return createHmac('sha256',secret).update(JSON.stringify([VERSION,key,expires,json])).digest('hex');}
// User-scoped cache: generated/personalised answers are never shared between users.
function privateCache({db,secret,now=Date.now,timestamp=n=>n}){
 const ref=key=>db.collection('_askAiAnswerCache').doc(key);
 return {
  async get(key){const snap=await ref(key).get();if(!snap.exists)return null;const d=snap.data();
   if(d.version!==VERSION||!Number.isSafeInteger(d.expires)||d.expires<=now()||typeof d.json!=='string'||Buffer.byteLength(d.json)>262144||!/^[a-f0-9]{64}$/.test(d.signature||''))return null;
   if(!timingSafeEqual(Buffer.from(signature(secret,key,d.json,d.expires),'hex'),Buffer.from(d.signature,'hex')))return null;
   try{const value=JSON.parse(d.json);return value.answerMode==='conversation-v1'&&value.status==='answered'?value:null;}catch{return null;}},
  async put(key,value){if(value.status!=='answered')return;const json=JSON.stringify(value);if(Buffer.byteLength(json)>262144)return;
   const expires=now()+86400000;await ref(key).set({version:VERSION,json,expires,expireAt:timestamp(expires),signature:signature(secret,key,json,expires)});}
 };
}
function createAssistantHandler({quickData,stats,documents,reserve,cache,ram,model,key,call,log=(event,fields)=>console.info(event,fields),now=Date.now}){
 return async({uid,data})=>{
  const request=requestData(data),started=now();
  const direct=localResponse({...request,quickData,stats});
  if(direct){log('ask-answer-complete',{route:direct.route,language:request.language,durationMs:now()-started});return direct;}
  // Never cache contextual conversations. Stateless caching includes UID and script.
  const ck=cacheKey({uid,question:request.question,language:request.language,model,version:stats.corpusSha256+':'+stats.quickAnswerSha256+':'+notesVersion});
  if(!request.history.length){const saved=ram?.get(ck)||await optionalCache(()=>cache?.get(ck));if(saved)return saved;}
  let reservation;
  try{
   reservation=await reserve(uid);
   const docs=await documents();
   const result=await answerConversation({...request,docs,key:key(),model,...(call?{call}:{}),now});
   if(result.status!=='answered')await optionalCache(()=>reservation.refund());
   if(!request.history.length&&result.status==='answered'){
    ram?.put(ck,result);await optionalCache(()=>cache?.put(ck,result));
   }
   return result;
  }catch(error){
   if(reservation)await optionalCache(()=>reservation.refund());
   throw error;
  }
 };
}
module.exports={createAssistantHandler,privateCache,cacheKey,VERSION};
