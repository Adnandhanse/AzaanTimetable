'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {geminiJson}=require('../gemini-client');
const base={key:'test-only',model:'gemini-2.5-flash',schema:{type:'object',properties:{ok:{type:'boolean'}},required:['ok']},instructions:'test',input:{question:'a full question'},maxTokens:1000};
test('Gemini REST schema, model, header and token contract',async()=>{
 let body;
 const output=await geminiJson({...base,fetcher:async(url,req)=>{
  assert.equal(url,'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent');
  assert.ok(!url.includes('test-only'));assert.equal(req.headers['x-goog-api-key'],'test-only');
  body=JSON.parse(req.body);
  return {ok:true,json:async()=>({candidates:[{finishReason:'STOP',content:{parts:[{text:'{"ok":true}'}]}}]})};
 }});
 assert.equal(output.ok,true);assert.deepEqual(body.generationConfig.responseJsonSchema,base.schema);
 assert.equal(body.generationConfig.responseMimeType,'application/json');assert.equal(body.generationConfig.thinkingConfig.thinkingBudget,0);
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
