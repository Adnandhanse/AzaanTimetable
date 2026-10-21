'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {countIntent,databaseAnswer}=require('../database-facts');
const {runAsk}=require('../core');
const stats={quranVerses:6236,quranSurahs:114};
test('whole-Quran count variants resolve without a model or corpus load',async()=>{
 let cases=0;
 for(const book of ['quran','quraan'])for(const noun of ['aayat','aayatein','ayat','verses'])for(const frame of [
  n=>`${book} me kitni ${n} hai`,n=>`${book} mein total ${n}`,n=>`total ${n} in the ${book}`,
  n=>`how many ${n} are there in the ${book}`]){
  const question=frame(noun);assert.equal(countIntent(question),'quran_verses',question);
  const result=await runAsk({question,stats,docs:()=>{throw Error('must not load');},call:()=>{throw Error('must not call Gemini');}});
  assert.match(result.answer.text,/6,236/);assert.equal(result.answer.type,'database');cases++;
 }
 assert.equal(cases,32);
 for(const q of ['Quran me kitni surah hain','How many surahs are there in the Quran','قرآن میں کتنی آیات ہیں'])assert.ok(countIntent(q),q);
});
test('subset, religious rulings, named surah and unrelated counts never get a shortcut total',()=>{
 for(const q of ['Quran me namaz ki kitni ayat hain','Quran me sajde ki kitni ayat hain',
  'How many verses about women are in Quran','Quran me Surah Baqarah mein kitni aayat hain',
  'Quran me Allah naam kitni ayat mein hai','Quran me kitni ayat 6666 hain',
  'Quran ki kitni surah mein Musa ka zikr hai','Namaz mein kitni rakat hain'])assert.equal(countIntent(q),null,q);
});
test('database facts are calculated inputs, never hardcoded responses or missing metadata guesses',()=>{
 assert.match(databaseAnswer('quran_verses',{quranVerses:5,quranSurahs:2}).answer.text,/5 aayatein/);
 assert.equal(databaseAnswer('quran_verses',null),null);
 assert.equal(databaseAnswer('invented',stats),null);
});
test('semantic count operation and guide routes do not load the full corpus',async()=>{
 const r=await runAsk({question:'Please give Quran chapter count',stats,docs:()=>{throw Error('no load');},call:async()=>({intent:'search',operation:'quran_surahs',understood:'Quran ki surah ka count',clarification:'',searches:[]})});
 assert.match(r.answer.text,/114/);
 const guide=await runAsk({question:'salah kaise padhein',allowGuides:true,docs:()=>{throw Error('no load');},call:async()=>({intent:'search',guide_id:'namaz',understood:'Namaz seekhna',clarification:'',searches:[]})});
 assert.equal(guide.hits[0].guideId,'namaz');
});
