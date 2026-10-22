'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {quickIntent,quickAnswer}=require('../quick-answer');
const data=require('../quick_answers.json');
test('both reported questions resolve from the packaged database without provider work',()=>{
 for(const q of ['fajr me kitni rakate hai ?','Fajar mein kitni rakaat hain','How many rakats are there in fajr']){
  const r=quickAnswer(q,'all',data);assert.ok(r,q);assert.match(r.answer.text,/2 rakaat/);assert.ok(r.hits.every(h=>h.kind==='hadith'));
 }
 const r=quickAnswer('ibrahim alaisalam ki biwi ka kya naam tha','all',data);
 assert.match(r.answer.text,/Sarah/);assert.match(r.answer.text,/Hajar/);assert.ok(r.hits.some(h=>h.number===3358));
});
test('specific modifiers, negation, other prayers and other people do not get a broad quick answer',()=>{
 for(const q of ['fajr ki sunnat nahi padhi to kya karein','fajr mein haath kahan rakhe','asr mein kitni rakate hai',
  'ibrahim ki biwi ne kya dua ki','musa ki biwi ka naam kya tha','fajr qaza ki kitni rakate hain'])assert.equal(quickIntent(q),null,q);
 assert.equal(quickIntent('fajr me kitni sunnah rakate hain'),'fajr_sunnah');
 assert.equal(quickIntent('fajr me kitni farz rakate hain'),'fajr_fard');
});
