'use strict';
const {quickIntent,answerForFact}=require('./quick-answer');
const {countIntent,databaseAnswer}=require('./database-facts');
const {romanQuestion}=require('./question-language');
const GUIDES={namaz:'Namaz ka tarika',shahadah:'Shahadah',roza:'Roza',zakat:'Zakat',hajj:'Hajj',umrah:'Umrah',janaza:'Namaz-e-Janaza',eidain:'Eid ki namaz'};
const phrases={
 namaz:['namaz ka tarika','namaz ka tareeqa','namaz kaise padhein','namaz kaise padhe','namaz padhne ka tarika','salah kaise padhein','how to pray','how to pray step by step','how to perform salah'],
 shahadah:['shahadah ka matlab','shahada ka matlab'],roza:['roza ka tarika','roza ka tareeqa'],
 zakat:['zakat ka tarika'],hajj:['hajj ka tarika'],umrah:['umrah ka tarika','umrah kaise karein'],
 janaza:['janaza ka tarika','janaza namaz ka tarika'],eidain:['eid ki namaz ka tarika','eid namaz ka tarika']};
function guideIntent(question){
 const q=romanQuestion(question).toLowerCase().replace(/[^\p{L}\p{N}]+/gu,' ').split(' ')
  .filter(w=>w&&!['mujhe','batao','btao','please','batayein','batayen'].includes(w)).join(' ');
 return Object.keys(phrases).find(id=>phrases[id].includes(q))||null;
}
function guideAnswer(id){return {status:'answered',answerMode:'sources-only',paragraphs:[],speech_urdu:'',speech_english:'',hits:[{
 id:`guide:${id}`,kind:'guide',guideId:id,number:1,title:GUIDES[id],
 en:'Open the step-by-step Learning guide. Each step includes its existing references.',
 ur:'Learning mein qadam-ba-qadam tarika parhein. Har step ke saath references maujood hain.',ar:'',grades:[]}]};}
function localAnswer({question,kind='all',quickData,stats,allowGuides=false}){
 const id=quickData&&quickIntent(question,quickData);
 if(id){
  const answer=answerForFact(id,kind,quickData);if(answer)return answer;
  // The answer is known but the user's source filter excludes its evidence.
  // Do not spend provider quota merely to rediscover the same exclusion.
  return {status:'insufficient',answerMode:'sources-only',paragraphs:[],speech_urdu:'',speech_english:'',hits:[],
   followup:'Is basic jawab ka reference selected source mein nahi hai. Sabhi sources select karke dobara poochhein.'};
 }
 const count=['all','quran'].includes(kind)?databaseAnswer(countIntent(question),stats):null;
 if(count)return count;
 const guide=allowGuides&&kind==='all'?guideIntent(question):null;
 return guide?guideAnswer(guide):null;
}
module.exports={localAnswer,GUIDES,guideIntent,guideAnswer};
