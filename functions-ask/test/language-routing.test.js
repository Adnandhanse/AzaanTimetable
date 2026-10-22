'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {quickIntent,quickAnswer}=require('../quick-answer');
const data=require('../quick_answers.json');
const {runAsk,prepareCorpus}=require('../core');
test('reported full question and Hindi/Urdu speech variants resolve without any AI call',async()=>{
 for(const q of ['aakhri nabi ka kya naam tha','akhiri nabi ka naam kya tha','aakhiri nabee ka naam kya hai',
 'आखिरी नबी का क्या नाम था','आख़िरी नबी का नाम क्या है','آخری نبی کا نام کیا ہے']){
  assert.equal(quickIntent(q,data),'last_prophet',q);
  const r=await runAsk({question:q,quickData:data,call:()=>{throw Error('provider must not be used');}});
  assert.match(r.answer.text,/Muhammad/);assert.match(r.answer.reference,/33:40/);
 }
});
test('generic last name, another prophet, qualifiers and negation cannot become last-prophet fact',()=>{
 for(const q of ['last name kya hai','last naam kya hai','aakhri nabi ki biwi ka naam kya tha',
 'aakhri nabi nahi kaun tha','आखिरी नबी नहीं कौन था','آخری نبی نہیں کون تھا'])assert.equal(quickIntent(q,data),null,q);
});
test('Hindi and Urdu Fajr questions resolve while missed prayers and other prayers do not',()=>{
 for(const q of ['फज्र में कितनी रकात है','फ़ज्र की कितनी रकातें हैं','فجر میں کتنی رکعتیں ہیں'])assert.equal(quickIntent(q,data),'fajr_rakat',q);
 for(const q of ['फज्र में कितनी कजा रकात हैं','फज्र की सुन्नत नहीं पढ़ी','عصر میں کتنی رکعتیں ہیں'])assert.equal(quickIntent(q,data),null,q);
});
test('selection outage returns clearly unverified source suggestions with canonical text only',async()=>{
 let calls=0;const source={id:'hadith:test:1',kind:'hadith',book:'bukhari',number:1,title:'Test',en:'He placed the right hand over the left forearm during prayer.',ur:'',ar:''};
 const r=await runAsk({question:'hands in prayer',docs:prepareCorpus([source]),call:async()=>{
  if(++calls===1)return {intent:'search',understood:'hands',clarification:'',searches:[{must:[['hand','hands','forearm'],['prayer']],boost:[]}]};
  throw new DOMException('timeout','TimeoutError');
 }});
 assert.equal(r.status,'references');assert.equal(r.verification,'not-verified');assert.equal(r.answer,undefined);
 assert.equal(r.hits[0].en,source.en);assert.match(r.followup,/final jawab na/);
});

test('local guide, Quran metadata and source-filter exclusions avoid provider calls',async()=>{
 const {localAnswer}=require('../local-route');
 for(const q of ['namaz ka tarika','नमाज का तरीका','how to pray step by step'])
  assert.equal(localAnswer({question:q,kind:'all',allowGuides:true}).hits[0].guideId,'namaz');
 assert.equal(localAnswer({question:'namaz mein haath kahan rakhein',kind:'all',allowGuides:true}),null);
 assert.equal(localAnswer({question:'aakhri nabi ka kya naam tha',kind:'hadith',quickData:data}).status,'insufficient');
 const result=localAnswer({question:'कुरान में कितनी आयतें हैं',kind:'all',stats:{quranVerses:6236,quranSurahs:114}});
 assert.match(result.answer.text,/6,236/);
});
