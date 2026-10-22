'use strict';
// Optional, explicitly selected paid provider. No automatic Gemini fallback.
const OPENAI_MODEL='gpt-6-luna';
async function openaiJson({key,model=OPENAI_MODEL,schema,instructions,input,maxTokens,fetcher=fetch}) {
  if(model!==OPENAI_MODEL)throw Error('unsupported-openai-model');
  const response=await fetcher('https://api.openai.com/v1/chat/completions',{
    method:'POST',signal:AbortSignal.timeout(25000),
    headers:{Authorization:`Bearer ${key}`,'Content-Type':'application/json'},
    body:JSON.stringify({model,store:false,reasoning_effort:'none',max_completion_tokens:Math.max(1200,maxTokens),
      response_format:{type:'json_object'},messages:[
        {role:'system',content:`${instructions}\nReturn JSON only, matching this schema: ${JSON.stringify(schema)}`},
        {role:'user',content:JSON.stringify(input)}]})});
  if(!response.ok){const e=Error('openai-unavailable');e.status=response.status;throw e;}
  const data=await response.json(),choice=data.choices?.[0];
  if(!choice||choice.finish_reason!=='stop'||choice.message?.refusal||typeof choice.message?.content!=='string')throw Error('invalid-provider-output');
  return JSON.parse(choice.message.content);
}
module.exports={openaiJson,OPENAI_MODEL};
