'use strict';
// Gemini Developer API only. No OpenAI/paid-provider fallback and no retries.
const DEFAULT_MODEL='gemini-3.5-flash-lite';
const MODELS=new Set([DEFAULT_MODEL,'gemini-2.5-flash','gemini-2.5-flash-lite']);
async function geminiJson({key,model=DEFAULT_MODEL,schema,instructions,input,maxTokens,fetcher=fetch}) {
  if(!MODELS.has(model))throw Error('unsupported-gemini-model');
  const response=await fetcher(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,{
    method:'POST',signal:AbortSignal.timeout(40000),
    headers:{'x-goog-api-key':key,'Content-Type':'application/json'},
    body:JSON.stringify({
      systemInstruction:{parts:[{text:instructions}]},
      contents:[{role:'user',parts:[{text:JSON.stringify(input)}]}],
      generationConfig:{responseMimeType:'application/json',responseJsonSchema:schema,
        maxOutputTokens:maxTokens,
        // 3.5 Flash-Lite defaults to minimal thinking; do not send the 2.5 budget.
        ...(model.startsWith('gemini-2.5-')?{thinkingConfig:{thinkingBudget:0}}:{})},
      // No Google Search grounding: all evidence comes from our own corpus.
    }),
  });
  if(!response.ok){const e=new Error('gemini-unavailable');e.status=response.status;throw e;}
  const data=await response.json();
  const candidate=data.candidates?.[0];
  if(data.promptFeedback?.blockReason || !candidate || candidate.finishReason!=='STOP')throw Error('gemini-blocked-or-incomplete');
  const text=(candidate.content?.parts || []).filter(p=>typeof p.text==='string' && p.thought!==true).map(p=>p.text).join('');
  return JSON.parse(text);
}
module.exports={geminiJson,DEFAULT_MODEL};
