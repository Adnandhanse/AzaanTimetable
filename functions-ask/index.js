'use strict';
const {onCall,HttpsError} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore,Timestamp} = require('firebase-admin/firestore');
const {reserveQuota} = require('./quota');
const path = require('node:path');
const {runAsk} = require('./core');
const {DEFAULT_MODEL,geminiJson}=require('./gemini-client');
const {OPENAI_MODEL,openaiJson}=require('./openai-client');
const provider=process.env.ASK_AI_PROVIDER||'gemini';
if(!['gemini','openai'].includes(provider))throw Error('unsupported-ai-provider');
const {createAnswerCache} = require('./answer-cache');
const {createSharedAnswerCache,optionalCache} = require('./shared-answer-cache');
const answers=createAnswerCache();
const stats=require('./database_stats.json');
const quickData=require('./quick_answers.json');
const {quickIntent}=require('./quick-answer');
const {localAnswer}=require('./local-route');
const {createCorpusLoader} = require('./corpus-loader');
const {classifyFailure} = require('./failure');
initializeApp();
const apiKey=defineSecret(provider==='openai'?'ASK_OPENAI_API_KEY':'ASK_GEMINI_API_KEY');
const documents=createCorpusLoader(path.join(__dirname,'corpus.ndjson.gz'));
// Atomic shared counters bound provider calls across instances. Store no
// questions, audio or answers. This collection MUST be closed to client writes.
async function reserve(uid) {
  const limit=(name,fallback) => Math.max(1,Math.min(5000,Number(process.env[name]) || fallback));
  return await reserveQuota({db:getFirestore(),uid,timestamp:Timestamp.fromMillis,
    userLimit:limit('ASK_USER_DAILY_LIMIT',5),globalLimit:Math.min(250,limit('ASK_GLOBAL_DAILY_LIMIT',250)),
    limited:reason=>new HttpsError('resource-exhausted',reason==='cooldown'?'Please wait 5 seconds before another AI search.':reason==='user'?'Daily personal AI limit reached.':'Daily project AI budget reached.',{supportCode:reason==='cooldown'?'AI-COOLDOWN':reason==='user'?'AI-USER-LIMIT':'AI-PROJECT-LIMIT'})});
}
exports.askIslamConnect=onCall({region:'us-central1',secrets:[apiKey],timeoutSeconds:120,
  memory:'2GiB',maxInstances:2,concurrency:1},async request=>{
  if (!request.auth) throw new HttpsError('unauthenticated','Enable anonymous sign-in for Ask Islam Connect.');
  if (process.env.ASK_AI_ENABLED === 'false') throw new HttpsError('unavailable','AI is temporarily disabled. Use Library search.');
  const data=request.data;
  if (!data || typeof data.question!=='string' || data.question.trim().length<3 || data.question.length>500 ||
      !['all','quran','hadith','story'].includes(data.kind)) throw new HttpsError('invalid-argument','Enter a question of 3–500 characters.');
  let stage = 'quota',reservation;
  const refund=async()=>{if(reservation)await optionalCache(()=>reservation.refund());};
  try {
    const direct=localAnswer({question:data.question,kind:data.kind,quickData,stats,allowGuides:data.acceptGuides===true});
    console.info('ask-route',{release:'language-story-v5',revision:process.env.K_REVISION||'local',kind:data.kind,
      basicId:quickIntent(data.question,quickData),direct:!!direct,
      script:/[\u0900-\u097f]/.test(data.question)?'hindi':/[\u0600-\u06ff]/.test(data.question)?'arabic-script':'latin',
      questionHash:require('node:crypto').createHash('sha256').update(data.question.trim()).digest('hex').slice(0,16)});
    if(direct)return direct;
    const model=provider==='openai'?OPENAI_MODEL:(process.env.ASK_GEMINI_MODEL||DEFAULT_MODEL);
    const cacheKey=answers.key(`${model}:${stats.corpusSha256}:${stats.quickAnswerSha256}:v5:guides=${data.acceptGuides===true}`,data.kind,data.question);
    const cached=answers.get(cacheKey);
    if(cached){console.info('ask-cache-hit',{layer:'memory'});return cached;}
    const shared=createSharedAnswerCache({db:getFirestore(),secret:apiKey.value(),
      version:`${model}:${stats.corpusSha256}:${stats.quickAnswerSha256}:v5:guides=${data.acceptGuides===true}`,
      timestamp:Timestamp.fromMillis});
    const saved=await optionalCache(()=>shared.get(cacheKey));
    if(saved){console.info('ask-cache-hit',{layer:'shared'});answers.put(cacheKey,saved);return saved;}
    reservation=await reserve(request.auth.uid);
    stage = 'corpus';
    const docs = async()=>{stage='corpus';const loaded=await documents();stage='provider';return loaded;};
    stage = 'provider';
    const result=await runAsk({question:data.question.trim(),kind:data.kind,docs,key:apiKey.value(),
      model,call:provider==='openai'?openaiJson:geminiJson,stats,quickData,allowGuides:data.acceptGuides===true});
    if(result.status!=='answered')await refund();
    answers.put(cacheKey,result);
    await optionalCache(()=>shared.put(cacheKey,result));
    return result;
  } catch (e) {
    await refund();
    if (e instanceof HttpsError) throw e;
    const failure = classifyFailure(e, stage);
    console.error('ask-ai-failed', {provider,stage, supportCode: failure.supportCode,
      type:e.name, status:e.status || null});
    throw new HttpsError(failure.code,
      failure.supportCode === 'AI-LIMIT' ? 'AI usage limit reached. Please try later.' :
      'AI search could not complete. Share the support code with the platform admin.',
      {supportCode:failure.supportCode});
  }
});
