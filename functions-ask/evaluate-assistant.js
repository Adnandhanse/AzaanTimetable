'use strict';
// Explicit opt-in evaluation using fixed public questions. No customer history.
const fs=require('node:fs'),path=require('node:path');
const {readCorpus}=require('./corpus-loader');
const {answerConversation}=require('./conversational');
const {DEFAULT_MODEL}=require('./gemini-client');
const {languageOf}=require('./assistant-contract');
const suites=[
 ['roman',['fajr me kitni rakate hai?','isme sunnat kitni hai?','ibrahim alaisalam ki biwi ka kya naam tha?']],
 ['en',['How many rakats are in Fajr?','How many of those are Sunnah?','What was the name of Ibrahim Alaihis Salam\'s wife?']],
 ['hi',['फ़ज्र में कितनी रकअत हैं?','इसमें सुन्नत कितनी हैं?','इब्राहीम अलैहिस्सलाम की बीवी का क्या नाम था?']],
 ['ur',['فجر میں کتنی رکعتیں ہیں؟','اس میں سنت کتنی ہیں؟','ابراہیم علیہ السلام کی بیوی کا کیا نام تھا؟']],
 ['roman',['fajrr me kitni rakate hai?']],
 ['en',['Does touching my wife break wudu? How do the Hanafi and Shafii positions differ?']],
 ['en',['Give the exact reference Sahih Bukhari 999999.']],
 ['roman',['namaz ka tarika batao','maa baap ke huqooq','gussa kaise control karu','sone se pehle ki dua']],
 ['en',['How do I perform salah step by step?','Who is the final Prophet?']]
];
async function evaluate({key,model=DEFAULT_MODEL}){
 const docs=await readCorpus(path.join(__dirname,'corpus.ndjson.gz')),results=[];
 for(const [language,questions] of suites){
  const history=[];
  for(const question of questions){
   const started=Date.now();
   try{
    // Deliberately exercises generation, not just the reviewed-fact shortcut.
    const r=await answerConversation({question,language,history:[...history],docs,key,model});
    results.push({question,language,durationMs:Date.now()-started,status:r.status,
     answer:r.answer?.text,references:r.references.map(x=>({id:x.id,label:x.label,basis:x.basis})),
     notices:r.notices,automaticChecks:{language:r.language===language,references:r.references.every(x=>x.verified)},humanReviewRequired:true});
    history.push({role:'user',content:question},{role:'assistant',content:r.answer?.text||''});
   }catch(e){results.push({question,language,durationMs:Date.now()-started,error:{kind:e.failureKind||e.name,status:e.status||null},humanReviewRequired:true});}
  }
 }
 return {liveApiRun:true,model,at:new Date().toISOString(),results,
  semanticAccuracy:'Not automatically certified. Review directness, numbers, language, relevant evidence and differences manually.'};
}
if(require.main===module){
 if(!process.argv.includes('--live')||!process.env.AI_KEY){
  console.error('Not run: explicit --live and AI_KEY are required. No live API test is implied.');process.exitCode=2;
 }else evaluate({key:process.env.AI_KEY,model:process.env.ASK_GEMINI_MODEL||DEFAULT_MODEL}).then(report=>{
  fs.writeFileSync(path.join(__dirname,'assistant-live-evaluation.json'),JSON.stringify(report,null,2));
  console.log('Live evaluation report written; human semantic review is still required.');
  if(report.results.some(r=>r.error))process.exitCode=1;
 }).catch(e=>{console.error('Evaluation failed',{type:e.name,status:e.status||null});process.exitCode=1;});
}
module.exports={evaluate,suites};
