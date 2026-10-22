'use strict';
const {checkGemini}=require('./check-gemini');
const {openaiJson,OPENAI_MODEL}=require('./openai-client');
const provider=process.env.ASK_AI_PROVIDER||'gemini';
if(!['gemini','openai'].includes(provider))throw Error('unsupported-ai-provider');
checkGemini({key:process.env.AI_KEY,...(provider==='openai'?{model:OPENAI_MODEL,call:openaiJson}:{})})
 .then(()=>console.log('Selected provider JSON compatibility check passed.',{provider}))
 .catch(e=>{console.error('Selected provider compatibility check failed.',{provider,status:e.status||null,type:e.name});process.exitCode=1;});
