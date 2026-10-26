'use strict';
const {quickIntent,tokens}=require('./quick-answer');
const {romanQuestion}=require('./question-language');
const {countIntent}=require('./database-facts');
function contextQuestion(question,history,quickData){
 if(quickIntent(question,quickData))return question;
 const q=romanQuestion(question).toLowerCase();
 const pronouns=/\b(?:ismein|isme|usmein|usme|iss|uss|it|its|that|this|these|those)\b|(?:اس (?:میں|mein|ki|ke)|اس کی|اس کے|इसमें|उसमें|इसकी|उसकी)/u;
 if(!pronouns.test(q))return question;
 const prior=history.filter(m=>m.role==='user').at(-1)?.content;
 if(!prior||!quickIntent(prior,quickData))return question;
 // Reuse a previous subject only for an elliptical follow-up. New qualifiers,
 // names, numbers and negation stay in the query and can block a basic match.
 const current=tokens(q.replace(pronouns,' ').replace(/\b(?:in|of|about)\b/g,' '));
 const old=tokens(prior).filter(t=>!['count','who','which','how','where','sunnah','fard'].includes(t));
 return [...new Set([...old,...current])].join(' ');
}
function localResponse({question,history=[],language,quickData,stats}){
 const resolved=contextQuestion(question,history,quickData);
 const id=quickIntent(resolved,quickData),fact=quickData.facts.find(f=>f.id===id);
 if(fact){
  const text=language==='roman'?fact.answer:fact.answers?.[language];
  if(!text)return null;
  // Existing reviewed records are reused, not new example-specific answers.
  const refs=fact.hits.map(h=>({id:h.id,kind:h.kind,label:h.kind==='quran'?`Quran ${h.surah}:${h.number}`:`${h.title} · App edition ${h.number}`,
   verified:true,basis:'reviewed-fact',source:h}));
  return {status:'answered',answerMode:'conversation-v1',language,
   statements:[{text,kind:'answer',sourceIds:refs.map(r=>r.id)}],references:refs,notices:[],
   answer:{text,reference:refs.map(r=>r.label).join('\n')},hits:fact.hits,route:'reviewed'};
 }
 const operation=countIntent(resolved);
 if(operation&&stats){
  const value=operation==='quran_surahs'?stats.quranSurahs:stats.quranVerses;
  if(!Number.isSafeInteger(value))return null;
  const surahs={en:`The Quran has ${value} surahs.`,roman:`Quran mein ${value} surah hain.`,hi:`कुरआन में ${value} सूरह हैं।`,ur:`قرآن میں ${value} سورتیں ہیں۔`};
  const verses={en:`The app's Quran numbering contains ${value} verses. Verse-counting conventions can differ without changing the text.`,roman:`App ki Quran numbering mein ${value} aayatein hain. Ginti ke tareeqe mukhtalif ho sakte hain; matn nahi badalta.`,hi:`ऐप की कुरआन संख्या-पद्धति में ${value} आयतें हैं। गिनती की पद्धति बदल सकती है; पाठ नहीं बदलता।`,ur:`ایپ کی قرآنی نمبرنگ میں ${value} آیات ہیں۔ گنتی کے طریقے مختلف ہو سکتے ہیں؛ متن نہیں بدلتا۔`};
  const text=(operation==='quran_surahs'?surahs:verses)[language];
  return {status:'answered',answerMode:'conversation-v1',language,statements:[{kind:'answer',text,sourceIds:[]}],references:[],notices:[],answer:{text,reference:'App Quran dataset'},hits:[],route:'metadata'};
 }
 return null;
}
module.exports={localResponse,contextQuestion};
