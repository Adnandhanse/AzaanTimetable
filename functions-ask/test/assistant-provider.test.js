'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {geminiJson}=require('../gemini-client');const {classifyFailure}=require('../failure');
const base={key:'never-log-this-secret',schema:{type:'object'},instructions:'JSON test',input:{question:'public fixture'},maxTokens:200,name:'islam_conversation_answer',maxAttempts:2};
const success=()=>({ok:true,status:200,json:async()=>({candidates:[{finishReason:'STOP',content:{parts:[{text:'{"ok":true}'}]}}]})});
test('one controlled transient retry; no third call; no secrets or question text in diagnostics',async()=>{
 let count=0;const logs=[];
 const r=await geminiJson({...base,sleep:async()=>{},log:(e,f)=>logs.push([e,f]),fetcher:async()=>++count===1?{ok:false,status:503}:success()});
 assert.equal(r.ok,true);assert.equal(count,2);assert.ok(!JSON.stringify(logs).includes(base.key));assert.ok(!JSON.stringify(logs).includes('public fixture'));
 count=0;await assert.rejects(geminiJson({...base,sleep:async()=>{},log:()=>{},fetcher:async()=>{count++;return {ok:false,status:503};}}),e=>e.status===503);assert.equal(count,2);
});
test('quota, provider-auth, output parsing and timeout remain distinct',async()=>{
 for(const [status,kind,support] of [[429,'quota','AI-LIMIT'],[401,'provider-auth','AI-KEY'],[403,'provider-auth','AI-KEY'],[503,'provider','AI-SERVER']]){
  let count=0;
  await assert.rejects(geminiJson({...base,sleep:async()=>{},log:()=>{},fetcher:async()=>{count++;return {ok:false,status};}}),e=>e.failureKind===kind&&classifyFailure(e,'provider').supportCode===support);
  assert.equal(count,status===503?2:1);
 }
 let calls=0;
 await assert.rejects(geminiJson({...base,log:()=>{},fetcher:async()=>{calls++;return {ok:true,json:async()=>{throw new SyntaxError('private response body');}};}}),e=>e.failureKind==='parse'&&classifyFailure(e,'provider').supportCode==='AI-OUTPUT');assert.equal(calls,1);
});
test('total deadline bounds retries even when a request exhausts the first budget',async()=>{
 let clock=0,calls=0;
 await assert.rejects(geminiJson({...base,now:()=>clock,sleep:async ms=>{clock+=ms;},timeoutMs:20000,totalTimeoutMs:35000,log:()=>{},fetcher:async()=>{
  calls++;clock+=calls===1?20000:14500;throw new DOMException('timed out','TimeoutError');
 }}),e=>classifyFailure(e,'provider').supportCode==='AI-TIMEOUT');
 assert.equal(calls,2);assert.equal(clock,35000);
});
