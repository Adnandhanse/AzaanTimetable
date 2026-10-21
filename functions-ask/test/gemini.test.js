'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {geminiJson}=require('../gemini-client');
const base={key:'test-only',schema:{type:'object',properties:{ok:{type:'boolean'}},required:['ok']},instructions:'test',input:{question:'a full question'},maxTokens:1000};
test('Gemini REST schema, model, header and token contract',async()=>{
 let body;
 const output=await geminiJson({...base,fetcher:async(url,req)=>{
  assert.equal(url,'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent');
  assert.ok(!url.includes('test-only'));assert.equal(req.headers['x-goog-api-key'],'test-only');
  body=JSON.parse(req.body);
  return {ok:true,json:async()=>({candidates:[{finishReason:'STOP',content:{parts:[{text:'{"ok":true}'}]}}]})};
 }});
 assert.equal(output.ok,true);assert.deepEqual(body.generationConfig.responseJsonSchema,base.schema);
 assert.equal(body.generationConfig.responseMimeType,'application/json');assert.equal(body.generationConfig.thinkingConfig,undefined);
 assert.equal(body.generationConfig.maxOutputTokens,1000);assert.equal(body.tools,undefined);
});
test('quota errors make exactly one request; there is no retry/paid fallback',async()=>{
 let calls=0;
 await assert.rejects(geminiJson({...base,fetcher:async()=>{calls++;return {ok:false,status:429};}}),e=>e.status===429);
 assert.equal(calls,1);
});
test('blocked, truncated, missing and malformed output are rejected',async()=>{
 const cases=[{promptFeedback:{blockReason:'SAFETY'}},{candidates:[{finishReason:'MAX_TOKENS'}]},
  {candidates:[]},{candidates:[{finishReason:'STOP',content:{parts:[{text:'not-json'}]}}]}];
 for(const data of cases)await assert.rejects(geminiJson({...base,fetcher:async()=>({ok:true,json:async()=>data})}));
});
test('unsupported or arbitrary model cannot change the outbound provider',async()=>{
 let called=false;
 await assert.rejects(geminiJson({...base,model:'https://attacker.invalid',fetcher:async()=>{called=true;}}),/unsupported-gemini-model/);
 assert.equal(called,false);
});

test('404 is surfaced without switching models or retrying',async()=>{
 let calls=0;
 await assert.rejects(geminiJson({...base,fetcher:async()=>{calls++;return {ok:false,status:404};}}),e=>e.status===404);
 assert.equal(calls,1);
});
test('explicit legacy models retain their compatible thinking budget',async()=>{
 for(const model of ['gemini-2.5-flash','gemini-2.5-flash-lite']) {
  await geminiJson({...base,model,fetcher:async(url,req)=>{
   assert.equal(JSON.parse(req.body).generationConfig.thinkingConfig.thinkingBudget,0);
   return {ok:true,json:async()=>({candidates:[{finishReason:'STOP',content:{parts:[{text:'{"ok":true}'}]}}]})};
  }});
 }
});
test('provider timeouts keep their type and are never retried',async()=>{
 let count=0;
 await assert.rejects(geminiJson({...base,name:'islam_search_plan',fetcher:async(_url,request)=>{
  count++;assert.ok(request.signal instanceof AbortSignal);
  throw new DOMException('test timeout','TimeoutError');
 }}),e=>e.name==='TimeoutError');
 assert.equal(count,1);
});
