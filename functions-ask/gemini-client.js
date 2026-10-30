'use strict';
const {setTimeout:wait}=require('node:timers/promises');
const DEFAULT_MODEL='gemini-3.5-flash-lite';
const MODELS=new Set([DEFAULT_MODEL,'gemini-2.5-flash','gemini-2.5-flash-lite']);
function transient(e){return ['TimeoutError','AbortError'].includes(e.name)||[408,500,502,503,504].includes(e.status);}
async function geminiJson({key,model=DEFAULT_MODEL,schema,instructions,input,maxTokens,name,fetcher=fetch,
 maxAttempts=1,timeoutMs=25000,totalTimeoutMs=35000,sleep=wait,now=Date.now,log=(event,fields)=>console.info(event,fields)}) {
 if(!MODELS.has(model))throw Error('unsupported-gemini-model');
 const attempts=Math.min(2,Math.max(1,maxAttempts));
 const started=now(),deadline=started+Math.min(55000,Math.max(1000,totalTimeoutMs));
 const phase=name==='islam_conversation_answer'?'answer':name==='islam_search_plan'?'plan':name==='islam_source_selection'?'selection':'check';
 for(let attempt=1;attempt<=attempts;attempt++){
  let bodyPhase=false;
  try{
   const remaining=deadline-now();if(remaining<=0)throw new DOMException('provider-deadline','TimeoutError');
   const response=await fetcher(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,{
    method:'POST',signal:AbortSignal.timeout(Math.max(1,Math.floor(Math.min(timeoutMs,remaining)))),
    headers:{'x-goog-api-key':key,'Content-Type':'application/json'},
    body:JSON.stringify({systemInstruction:{parts:[{text:instructions}]},
     contents:[{role:'user',parts:[{text:JSON.stringify(input)}]}],
     generationConfig:{responseMimeType:'application/json',responseJsonSchema:schema,maxOutputTokens:maxTokens,
      ...(model.startsWith('gemini-2.5-')?{thinkingConfig:{thinkingBudget:0}}:{})}})});
   if(!response.ok){const e=Error('gemini-unavailable');e.status=response.status;e.failureKind=[401,403].includes(e.status)?'provider-auth':e.status===429?'quota':'provider';throw e;}
   bodyPhase=true;
   const data=await response.json(),candidate=data.candidates?.[0];
   if(data.promptFeedback?.blockReason||!candidate||candidate.finishReason!=='STOP')
    throw Object.assign(Error('gemini-blocked-or-incomplete'),{failureKind:'response'});
   const text=(candidate.content?.parts||[]).filter(p=>typeof p.text==='string'&&p.thought!==true).map(p=>p.text).join('');
   const result=JSON.parse(text);
   log('gemini-request-complete',{phase,attempt,durationMs:now()-started,status:response.status||200});
   return result;
  }catch(e){
   e.failureKind=e.failureKind||(['TimeoutError','AbortError'].includes(e.name)?'timeout':e instanceof SyntaxError||bodyPhase?'parse':'network');
   // A timed-out generation already spent its latency budget. Retry only
   // fast transient HTTP failures, never quota/auth/parse failures or timeouts.
   const retry=attempt<attempts&&transient(e)&&!['TimeoutError','AbortError'].includes(e.name)&&deadline-now()>1000;
   log('gemini-request-failed',{phase,attempt,durationMs:now()-started,type:e.name,status:e.status||null,kind:e.failureKind,retry});
   if(!retry)throw e;
   await sleep(Math.min(500,Math.max(0,deadline-now()-1)));
  }
 }
}
module.exports={geminiJson,DEFAULT_MODEL,transient};
