'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {prepareCorpus,retrieve,validatePlan,validateSelection,runAsk,contextFor}=require('../core');
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
  return calls.length===1?structuredClone(plan):{status:'selected',source_ids:['hadith:bukhari:1']};
 }});
 assert.equal(calls.length,2);assert.equal(calls[1].input.excerpts.length,1);
 assert.equal(result.hits[0].en,docs[0].en);assert.equal(result.hits[0].normalized,undefined);
 assert.deepEqual(result.paragraphs,[]);assert.equal(result.speech_urdu,'');assert.equal(result.answerMode,'sources-only');
});
test('missing evidence stops before answer-model call',async()=>{
 let count=0;const result=await runAsk({question:'unknown',docs,key:'test',call:async()=>{count++;return {intent:'search',understood:'unknown',clarification:'',searches:[{must:[['nonexistenttopic']],boost:[]}]};}});
 assert.equal(result.status,'insufficient');assert.equal(count,1);assert.deepEqual(result.paragraphs,[]);
});
test('forged, uncited and empty evidence are rejected',()=>{
 const candidates=retrieve(docs,plan);
 for(const ids of [[],['hadith:invented:99']])assert.throws(()=>validateSelection({status:'selected',source_ids:ids},candidates));
});
test('clarification and unrelated questions do not trigger retrieval/answer generation',async()=>{
 for(const intent of ['clarify','out_of_scope']) {
  let count=0;const r=await runAsk({question:'ambiguous',docs,call:async()=>{count++;return {intent,understood:'',clarification:'Kis waqie ke bare mein?',searches:[]};}});
  assert.equal(count,1);assert.equal(r.status,intent);assert.deepEqual(r.hits,[]);
 }
});
test('context size is bounded',()=>{
 const c=Array.from({length:12},(_,i)=>({doc:{id:String(i),en:'x'.repeat(40000),grades:[]},terms:['x']}));
 assert.ok(contextFor(c).reduce((n,x)=>n+x.text.length,0)<=24000);
});
test('an invalid essential concept cannot be dropped to broaden a query',()=>{
 assert.throws(()=>validatePlan({intent:'search',understood:'hands',clarification:'',searches:[{must:[['prayer'],['']],boost:[]}]}),/empty-essential-concept/);
});

test('model prose and forged source bodies are never forwarded',async()=>{
 let calls=0;
 const r=await runAsk({question:'hand position',docs,call:async()=>++calls===1?structuredClone(plan):
   {status:'selected',source_ids:['hadith:bukhari:1'],answer:'Invented claim',en:'Forged scripture',paragraphs:[{text:'Fabricated'}]}});
 assert.deepEqual(r.paragraphs,[]);assert.equal(r.hits[0].en,docs[0].en);assert.equal(r.answer,undefined);
});
