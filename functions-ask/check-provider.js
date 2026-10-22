'use strict';
const {setTimeout:wait}=require('node:timers/promises');
const {checkGemini}=require('./check-gemini');
const {DEFAULT_MODEL}=require('./gemini-client');
const {openaiJson,OPENAI_MODEL}=require('./openai-client');
function temporary(error){
 return ['TimeoutError','AbortError'].includes(error?.name)||[408,500,502,503,504].includes(error?.status);
}
// Deployment smoke check only. Runtime question calls and quotas are unchanged.
// At most three Gemini requests; permanent errors and quota errors fail at once.
async function checkProvider({provider='gemini',key,model,check=checkGemini,sleep=wait,
 random=Math.random,log=(event,fields)=>console.info(event,fields)}={}) {
 if(!['gemini','openai'].includes(provider))throw Error('unsupported-ai-provider');
 if(!key)throw Error('missing-key');
 const attempts=provider==='gemini'?3:1;
 for(let attempt=1;attempt<=attempts;attempt++){
  try{
   await check({key,model:model||(provider==='openai'?OPENAI_MODEL:DEFAULT_MODEL),
     ...(provider==='openai'?{call:openaiJson}:{})});
   log('provider-check-passed',{provider,attempt});
   return;
  }catch(error){
   if(attempt===attempts||!temporary(error)){
    log('provider-check-failed',{provider,attempt,status:error.status||null,type:error.name||'Error'});
    throw error;
   }
   const jitter=Math.floor(Math.min(1,Math.max(0,random()))*500);
   const delayMs=[2000,5000][attempt-1]+jitter;
   log('provider-check-retrying',{provider,attempt,nextAttempt:attempt+1,
     delayMs,status:error.status||null,type:error.name||'Error'});
   await sleep(delayMs);
  }
 }
}
if(require.main===module){
 const provider=process.env.ASK_AI_PROVIDER||'gemini';
 checkProvider({provider,key:process.env.AI_KEY,
   ...(provider==='gemini'&&process.env.ASK_GEMINI_MODEL?{model:process.env.ASK_GEMINI_MODEL}:{})})
  .then(()=>console.log('Selected provider JSON compatibility check passed.',{provider}))
  .catch(error=>{
   console.error('Selected provider compatibility check failed. Deployment remains blocked.',{
    provider,status:error.status||null,type:error.name||'Error',
    action:temporary(error)?'Temporary provider failure persisted after bounded checks. Retry the workflow later.':
     error.status===429?'Provider quota reached. Check quota before running again.':
     [401,403].includes(error.status)?'Check selected provider API key and access.':
     error.status===404?'Configured model is unavailable for this project.':'Check provider configuration or structured output.'});
   process.exitCode=1;
  });
}
module.exports={checkProvider,temporary};
