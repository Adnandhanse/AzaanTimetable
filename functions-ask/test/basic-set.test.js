'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {quickIntent,quickAnswer}=require('../quick-answer');
const {runAsk,prepareCorpus}=require('../core');
const data=require('../quick_answers.json');
test('all 123 curated question examples and formatting variations resolve to the correct sourced topic',()=>{
 let count=0;
 for(const f of data.facts){assert.ok(f.questions.length>=4);assert.ok(f.hits.length);
  for(const q of f.questions)for(const variation of [q,q.toUpperCase()+' ???','  '+q.replace(/ /g,'   ')+'  ']){
   assert.equal(quickIntent(variation,data),f.id,variation);
   const r=quickAnswer(variation,'all',data);assert.equal(r.answer.text,f.answer);assert.ok(r.answer.reference);count++;
  }
 }
 assert.equal(data.facts.length,28);assert.equal(count,369);
});
test('synonyms, small spelling mistakes and changed word order work without collapsing qualifiers',()=>{
 for(const [q,id] of [
  ['kitni rakaat fajr me hain','fajr_rakat'],['fazr me kitni rakate hai','fajr_rakat'],
  ['subah ki namaz kitni rakat hoti hai','fajr_rakat'],['fajr ki sunnat kitni rakaat hain','fajr_sunnah'],
  ['fajr ki farz kitni rakaat hain','fajr_fard'],['ibrahm ki wife ka naam','ibrahim_family'],
  ['quran ki langauge kya hai','quran_language'],['quran ki zaban kya hai','quran_language']])
  assert.equal(quickIntent(q,data),id,q);
});
test('additional conditions, negation, different entities and unknown topics require library search',()=>{
 for(const q of ['fajr ki sunnat chhoot gayi to kya karein','fajr ki farz nahi padhi kitni rakaat qaza karein',
  'isha me kitni rakate hai','musa ki biwi ka naam','ibrahim ki biwi ki dua ka naam',
  'quran kis zaban mein nazil nahi hua','parents ke saath business kaise karein','safar mein fajr kitni rakaat',
  'fajr mein 8 farz rakate hoti hain kya','salam ka jawab toilet mein kaise dein'])assert.equal(quickIntent(q,data),null,q);
});
test('ambiguous overlapping basic examples are never guessed',()=>{
 const ambiguous={facts:[{id:'a',questions:['fajr ki rakaat']},{id:'b',questions:['fajr ki rakaat']}]};
 assert.equal(quickIntent('fajr ki rakaat',ambiguous),null);
});
test('semantic basic ID uses referenced database text, and invented IDs are rejected',async()=>{
 const request={question:'I want to know the language in which Quran came down',quickData:data,docs:()=>{throw Error('must not load full corpus');}};
 let calls=0;
 const r=await runAsk({...request,call:async()=>{calls++;return {intent:'search',understood:'Quran ki zaban',clarification:'',basic_id:'quran_language',searches:[]};}});
 assert.equal(calls,1);assert.match(r.answer.text,/Arabi/);assert.equal(r.hits[0].kind,'quran');
 await assert.rejects(runAsk({...request,call:async()=>({intent:'search',understood:'x',clarification:'',basic_id:'invented',searches:[]})}),/invalid-plan-basic-id/);
});
test('a question outside the set follows actual source retrieval and selection',async()=>{
 const docs=prepareCorpus([{id:'hadith:bukhari:1',kind:'hadith',book:'bukhari',number:1,title:'Bukhari',en:'He put his right hand on his left forearm during prayer.',grades:[]}]);
 let calls=0;
 const r=await runAsk({question:'namaz mein haath kahan rakhein',quickData:data,docs,call:async()=>++calls===1?
  {intent:'search',understood:'Namaz mein haath ki jagah',clarification:'',basic_id:'',searches:[{must:[['prayer'],['hand']],boost:[]}]}:
  {status:'selected',source_ids:['hadith:bukhari:1']}});
 assert.equal(calls,2);assert.equal(r.hits[0].id,'hadith:bukhari:1');
});
