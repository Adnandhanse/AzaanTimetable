'use strict';
const {test}=require('node:test'),a=require('node:assert/strict');
const {prepareCorpus}=require('../core');
const {retrieveEvidence,corpusIndex}=require('../assistant-retrieval');
const {validateAnswer}=require('../conversational');
const {geminiJson}=require('../gemini-client');
const docs=prepareCorpus([
 {id:'quran:94:6',kind:'quran',surah:94,number:6,en:'Indeed, with hardship comes ease.',title:'Quran'},
 {id:'hadith:fixture:1',kind:'hadith',book:'bukhari',number:1,en:'When you stand for prayer face the Qibla and say Takbir, recite, bow calmly, then stand and prostrate, sit and prostrate again.',title:'Fixture'},
 {id:'story:nuh:1',kind:'story',storyId:'nuh',title:'Nuh Alaihis Salam',chapter:'The flood',en:'Noah called his people to worship Allah. The flood came and the ark carried those who believed.'},
]);
test('indexed search retains Hadith, Quran and story evidence for relevant natural questions',()=>{
 for(const [q,kind] of [['namaz ka tariqa kya hai','hadith'],['hardship ease','quran'],['nuh flood','story']]){
  const first=retrieveEvidence(q,[],docs),again=retrieveEvidence(q,[],docs);
  a.ok(first.evidence.some(e=>e.kind===kind),q);
  a.deepEqual(again.evidence,first.evidence);
 }
});
test('religious answers cannot silently lose citations and remain confirmed answers',()=>{
 const raw={status:'answered',language:'en',statements:[{text:'Hardship is accompanied by ease.',kind:'answer',source_ids:[]}],citations:[],uncertainty:'none'};
 const result=validateAnswer(raw,{language:'en',index:corpusIndex(docs),exact:{requiresEvidence:true}});
 a.equal(result.status,'insufficient');a.ok(!result.answer.text.includes('Hardship is accompanied'));
 raw.statements[0].source_ids=['quran:94:6'];raw.citations=[{source_id:'quran:94:6',quote:'Indeed, with hardship comes ease.'}];
 const cited=validateAnswer(raw,{language:'en',index:corpusIndex(docs),exact:{requiresEvidence:true},allowedIds:new Set(['quran:94:6'])});
 a.equal(cited.status,'answered');a.equal(cited.references[0].label,'Quran 94:6');
});
test('a timed-out Gemini generation is not automatically repeated',async()=>{
 let calls=0;
 await a.rejects(geminiJson({key:'not-a-real-key',instructions:'fixture',input:{},schema:{},name:'islam_conversation_answer',maxTokens:100,maxAttempts:2,
  fetcher:async()=>{calls++;throw new DOMException('fixture timeout','TimeoutError');},log:()=>{},sleep:()=>a.fail('No retry delay expected')}));
 a.equal(calls,1);
});
