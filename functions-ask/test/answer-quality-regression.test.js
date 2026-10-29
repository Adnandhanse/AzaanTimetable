'use strict';
const {test}=require('node:test'),a=require('node:assert/strict');
const {prepareCorpus}=require('../core');
const {retrieveEvidence,corpusIndex}=require('../assistant-retrieval');
const {validateAnswer}=require('../conversational');
const docs=prepareCorpus([
 {id:'hadith:test:1',kind:'hadith',book:'bukhari',number:1,title:'Test fixture',en:'When you stand for prayer face the Qibla and say Takbir, recite, bow calmly, then stand and prostrate, sit and prostrate again.',context:'Prayer'},
 {id:'hadith:test:2',kind:'hadith',book:'muslim',number:2,title:'Test fixture',en:'This hadith has been narrated with the same chain of transmitters.',context:'Zakat and prayer'},
 {id:'hadith:test:3',kind:'hadith',book:'bukhari',number:3,title:'Test fixture',en:'Zakat is an obligatory duty taken from the rich and returned to the poor.',context:'Zakat'},
 {id:'quran:test:1',kind:'quran',surah:1,number:1,title:'Test fixture',en:'Give zakat and establish prayer.'},
]);
test('natural method spellings rank a connected procedure, never narrator-only cross references',()=>{
 for(const q of ['namaz ka tariqa kya hai','namaz ka tareeqa kya hai','namaz ka tarika batao','how do I perform prayer step by step?']) {
  const r=retrieveEvidence(q,[],docs);a.equal(r.evidence[0].id,'hadith:test:1',q);
  a.ok(!r.evidence.some(x=>x.id==='hadith:test:2'));
 }
});
test('explicit Hadith request retains the requested source type and ignores conversational filler',()=>{
 const r=retrieveEvidence('zakat ke bare me hadees batao',[],docs);
 a.ok(r.evidence.length);a.ok(r.evidence.every(d=>d.kind==='hadith'));
 a.ok(r.evidence.some(d=>d.id==='hadith:test:3'));
});
test('citation whitespace differences do not erase valid references; changed words still fail',()=>{
 const quote='Zakat is an obligatory duty taken from the rich and returned to the poor.';
 const source=docs.find(d=>d.id==='hadith:test:3'),index=corpusIndex(docs);
 const raw={status:'answered',language:'en',statements:[{text:'Zakat is an obligatory duty supporting the poor.',kind:'answer',source_ids:[source.id]}],citations:[{source_id:source.id,quote:quote.replaceAll(' ','  ')}],uncertainty:'none'};
 a.equal(validateAnswer(raw,{language:'en',index,exact:{requested:false}}).references.length,1);
 raw.citations[0].quote=quote.replace('poor','king');
 a.equal(validateAnswer(raw,{language:'en',index,exact:{requested:false}}).references.length,0);
});
