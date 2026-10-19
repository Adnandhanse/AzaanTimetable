'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {prepareCorpus,retrieve,validatePlan,validateAnswer,runAsk,openAIJson,contextFor}=require('../core');
const docs=prepareCorpus([
 {id:'hadith:bukhari:1',kind:'hadith',book:'bukhari',number:1,title:'Bukhari',en:'During prayer he placed his right hand over his left forearm.',ur:'',grades:[]},
 {id:'hadith:muslim:2',kind:'hadith',book:'muslim',number:2,title:'Muslim',en:'He raised his hands when beginning prayer.',ur:'',grades:[]},
 {id:'hadith:bukhari:3',kind:'hadith',book:'bukhari',number:3,title:'Bukhari',en:'Prayer is important.',ur:'',grades:[]},
 {id:'story:yusuf:y1',kind:'story',storyId:'yusuf',pageId:'y1',number:1,title:'Yusuf',chapter:'Dream',en:'Joseph told his father about a dream.',roman:'Yusuf ne khwaab bataya.',grades:[]},
]);
const plan=validatePlan({intent:'search',understood:'Namaz mein haath rakhna',clarification:'',searches:[{must:[['prayer'],['hand','forearm'],['placed','put','folded']],boost:['right hand']}]});
test('natural-language plan retains specific action; prayer-only narration is rejected',()=>{
 assert.deepEqual(retrieve(docs,plan).map(c=>c.doc.id),['hadith:bukhari:1']);
});
test('kind filters work',()=>assert.equal(retrieve(docs,plan,'quran').length,0));
test('grounded pipeline uses retrieved IDs and returns trusted corpus text',async()=>{
 const calls=[];
 const result=await runAsk({question:'Namaz mein haath kahan rakhna hai?',docs,key:'test',call:async req=>{
  calls.push(req);
  return calls.length===1?structuredClone(plan):{status:'answered',followup:'',speech_urdu:'ہاتھ',speech_english:'Hands',paragraphs:[{text:'Riwayat mein daayein haath ka zikr hai.',source_ids:['hadith:bukhari:1']}]};
 }});
 assert.equal(calls.length,2);assert.equal(calls[1].input.excerpts.length,1);
 assert.equal(result.hits[0].en,docs[0].en);assert.equal(result.hits[0].normalized,undefined);
});
test('missing evidence stops before answer-model call',async()=>{
 let count=0;const result=await runAsk({question:'unknown',docs,key:'test',call:async()=>{count++;return {intent:'search',understood:'unknown',clarification:'',searches:[{must:[['nonexistenttopic']],boost:[]}]};}});
 assert.equal(result.status,'insufficient');assert.equal(count,1);assert.deepEqual(result.paragraphs,[]);
});
test('forged, uncited and empty evidence are rejected',()=>{
 const candidates=retrieve(docs,plan);
 for(const ids of [[],['hadith:invented:99']])assert.throws(()=>validateAnswer({status:'answered',followup:'',speech_urdu:'',speech_english:'',paragraphs:[{text:'Claim',source_ids:ids}]},candidates));
});
test('clarification and unrelated questions do not trigger retrieval/answer generation',async()=>{
 for(const intent of ['clarify','out_of_scope']) {
  let count=0;const r=await runAsk({question:'ambiguous',docs,call:async()=>{count++;return {intent,understood:'',clarification:'Kis waqie ke bare mein?',searches:[]};}});
  assert.equal(count,1);assert.equal(r.status,intent);assert.deepEqual(r.hits,[]);
 }
});
test('HTTP contract uses Responses structured outputs, no storage and bounded tokens',async()=>{
 let payload;
 const out=await openAIJson({key:'test-only',model:'gpt-4.1-mini',schema:{type:'object'},name:'test_schema',instructions:'test',input:{question:'question'},maxTokens:12,
 fetcher:async(url,req)=>{payload=JSON.parse(req.body);assert.equal(url,'https://api.openai.com/v1/responses');return {ok:true,json:async()=>({status:'completed',output:[{content:[{type:'output_text',text:'{"ok":true}'}]}]})};}});
 assert.equal(payload.store,false);assert.equal(payload.text.format.strict,true);assert.equal(payload.max_output_tokens,12);assert.equal(out.ok,true);
});
test('refusals, truncated responses and provider failures are not shown as answers',async()=>{
 for(const data of [{status:'incomplete',output:[]},{status:'completed',output:[{content:[{type:'refusal',refusal:'no'}]}]}]) {
  await assert.rejects(openAIJson({key:'test',model:'test',schema:{},name:'test',instructions:'',input:{},maxTokens:1,fetcher:async()=>({ok:true,json:async()=>data})}));
 }
 await assert.rejects(openAIJson({key:'test',model:'test',schema:{},name:'test',instructions:'',input:{},maxTokens:1,fetcher:async()=>({ok:false,status:401})}));
});
test('context size is bounded',()=>{
 const c=Array.from({length:12},(_,i)=>({doc:{id:String(i),en:'x'.repeat(40000),grades:[]},terms:['x']}));
 assert.ok(contextFor(c).reduce((n,x)=>n+x.text.length,0)<=24000);
});
test('an invalid essential concept cannot be dropped to broaden a query',()=>{
 assert.throws(()=>validatePlan({intent:'search',understood:'hands',clarification:'',searches:[{must:[['prayer'],['']],boost:[]}]}),/empty-essential-concept/);
});
