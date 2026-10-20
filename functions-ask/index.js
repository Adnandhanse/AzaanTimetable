'use strict';
const {onCall,HttpsError} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore,Timestamp} = require('firebase-admin/firestore');
const {reserveQuota} = require('./quota');
const {gunzipSync} = require('node:zlib');
const fs = require('node:fs');
const path = require('node:path');
const {prepareCorpus,runAsk} = require('./core');
initializeApp();
const apiKey=defineSecret('ASK_GEMINI_API_KEY');
let corpus;
function documents() {
  return corpus ||= prepareCorpus(JSON.parse(gunzipSync(fs.readFileSync(path.join(__dirname,'corpus.json.gz')))));
}
// Atomic shared counters bound provider calls across instances. Store no
// questions, audio or answers. This collection MUST be closed to client writes.
async function reserve(uid) {
  const limit=(name,fallback) => Math.max(1,Math.min(5000,Number(process.env[name]) || fallback));
  await reserveQuota({db:getFirestore(),uid,timestamp:Timestamp.fromMillis,
    userLimit:limit('ASK_USER_DAILY_LIMIT',5),globalLimit:Math.min(250,limit('ASK_GLOBAL_DAILY_LIMIT',250)),
    limited:()=>new HttpsError('resource-exhausted','AI limit reached. Please try later or use Library search.')});
}
exports.askIslamConnect=onCall({region:'us-central1',secrets:[apiKey],timeoutSeconds:120,
  memory:'1GiB',maxInstances:2,concurrency:4},async request=>{
  if (!request.auth) throw new HttpsError('unauthenticated','Enable anonymous sign-in for Ask Islam Connect.');
  if (process.env.ASK_AI_ENABLED === 'false') throw new HttpsError('unavailable','AI is temporarily disabled. Use Library search.');
  const data=request.data;
  if (!data || typeof data.question!=='string' || data.question.trim().length<3 || data.question.length>500 ||
      !['all','quran','hadith','story'].includes(data.kind)) throw new HttpsError('invalid-argument','Enter a question of 3–500 characters.');
  await reserve(request.auth.uid);
  try {
    return await runAsk({question:data.question.trim(),kind:data.kind,docs:documents(),key:apiKey.value(),
      model:process.env.ASK_GEMINI_MODEL || 'gemini-2.5-flash'});
  } catch (e) {
    // Do not log questions, source passages, provider bodies, tokens or keys.
    console.error('ask-ai-failed',{type:e.name,status:e.status || null});
    if(e.status===429)throw new HttpsError('resource-exhausted','AI provider limit reached. Use Library search or try later.');
    if(e.status===401 || e.status===403)throw new HttpsError('failed-precondition','AI provider key/access needs configuration.');
    throw new HttpsError('unavailable','AI could not complete this request. Use Library search or try again.');
  }
});
