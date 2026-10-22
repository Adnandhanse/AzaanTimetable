'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {openaiJson,OPENAI_MODEL}=require('../openai-client');
const base={key:'test-only',schema:{type:'object'},instructions:'Return JSON',input:{question:'test'},maxTokens:650};
test('explicit OpenAI adapter pins provider, excludes storage, validates complete JSON',async()=>{
 const r=await openaiJson({...base,fetcher:async(url,req)=>{
  assert.equal(url,'https://api.openai.com/v1/chat/completions');assert.equal(req.headers.Authorization,'Bearer test-only');
  const b=JSON.parse(req.body);assert.equal(b.store,false);assert.equal(b.model,OPENAI_MODEL);assert.equal(b.response_format.type,'json_object');
  return {ok:true,json:async()=>({choices:[{finish_reason:'stop',message:{content:'{"ok":true}'}}]})};
 }});assert.equal(r.ok,true);
});
test('provider quota errors do not trigger automatic calls or fallback',async()=>{
 let n=0;await assert.rejects(openaiJson({...base,fetcher:async()=>{n++;return {ok:false,status:429};}}),e=>e.status===429);assert.equal(n,1);
});
test('truncation and arbitrary models are rejected',async()=>{
 await assert.rejects(openaiJson({...base,fetcher:async()=>({ok:true,json:async()=>({choices:[{finish_reason:'length',message:{content:'{}'}}]})})}),/invalid-provider-output/);
 await assert.rejects(openaiJson({...base,model:'arbitrary'}),/unsupported-openai-model/);
});
