'use strict';
const {onCall,HttpsError} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore,Timestamp} = require('firebase-admin/firestore');
const {reserveQuota} = require('./quota');
const path = require('node:path');
const {runAsk} = require('./core');
const {DEFAULT_MODEL} = require('./gemini-client');
const {createAnswerCache} = require('./answer-cache');
const answers=createAnswerCache();
const stats=require('./database_stats.json');
const {createCorpusLoader} = require('./corpus-loader');
const {classifyFailure} = require('./failure');
initializeApp();
const apiKey=defineSecret('ASK_GEMINI_API_KEY');
const documents=createCorpusLoader(path.join(__dirname,'corpus.ndjson.gz'));
// Atomic shared counters bound provider calls across instances. Store no
// questions, audio or answers. This collection MUST be closed to client writes.
async function reserve(uid) {
  const limit=(name,fallback) => Math.max(1,Math.min(5000,Number(process.env[name]) || fallback));
  await reserveQuota({db:getFirestore(),uid,timestamp:Timestamp.fromMillis,
    userLimit:limit('ASK_USER_DAILY_LIMIT',5),globalLimit:Math.min(250,limit('ASK_GLOBAL_DAILY_LIMIT',250)),
    limited:()=>new HttpsError('resource-exhausted','AI limit reached. Please try later or use Library search.')});
}
exports.askIslamConnect=onCall({region:'us-central1',secrets:[apiKey],timeoutSeconds:120,
  memory:'2GiB',maxInstances:2,concurrency:1},async request=>{
  if (!request.auth) throw new HttpsError('unauthenticated','Enable anonymous sign-in for Ask Islam Connect.');
  if (process.env.ASK_AI_ENABLED === 'false') throw new HttpsError('unavailable','AI is temporarily disabled. Use Library search.');
  const data=request.data;
  if (!data || typeof data.question!=='string' || data.question.trim().length<3 || data.question.length>500 ||
      !['all','quran','hadith','story'].includes(data.kind)) throw new HttpsError('invalid-argument','Enter a question of 3–500 characters.');
  let stage = 'quota';
  try {
    await reserve(request.auth.uid);
    const model=process.env.ASK_GEMINI_MODEL || DEFAULT_MODEL;
    const cacheKey=answers.key(`${model}:guides=${data.acceptGuides===true}`,data.kind,data.question);
    const cached=answers.get(cacheKey);
    if(cached)return cached;
    stage = 'corpus';
    const docs = async()=>{stage='corpus';const loaded=await documents();stage='gemini';return loaded;};
    stage = 'gemini';
    const result=await runAsk({question:data.question.trim(),kind:data.kind,docs,key:apiKey.value(),
      model,stats,allowGuides:data.acceptGuides===true});
    answers.put(cacheKey,result);
    return result;
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    const failure = classifyFailure(e, stage);
    console.error('ask-ai-failed', {stage, supportCode: failure.supportCode,
      type:e.name, status:e.status || null});
    throw new HttpsError(failure.code,
      failure.supportCode === 'AI-LIMIT' ? 'AI usage limit reached. Please try later.' :
      'AI search could not complete. Share the support code with the platform admin.',
      {supportCode:failure.supportCode});
  }
});
