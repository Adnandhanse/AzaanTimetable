'use strict';
const compiled=new WeakMap();
const {romanQuestion}=require('./question-language');
const aliases={fajrr:'fajr',fazr:'fajr',namaj:'namaz',ibrahm:'ibrahim',fajar:'fajr',rakat:'rakaat',rakate:'rakaat',rakatein:'rakaat',rakaatein:'rakaat',rakah:'rakaat',rakats:'rakaat',rakates:'rakaat',sunnat:'sunnah',sunnats:'sunnah',farz:'fard',obligatory:'fard',compulsory:'fard',prayer:'namaz',prayers:'namaz',namazein:'namaz',namaze:'namaz',namaaz:'namaz',salah:'namaz',salaah:'namaz',ibraheem:'ibrahim',abraham:'ibrahim',esa:'isa',jesus:'isa',ishmael:'ismail',wife:'biwi',wives:'biwi',begum:'biwi',biwiyon:'biwi',father:'walid',mother:'walida',maa:'walida',ammi:'walida',son:'beta',bete:'beta',name:'naam',nam:'naam',language:'zaban',bhasha:'zaban',ramzan:'ramadan',ramadhan:'ramadan',roze:'roza',fasting:'roza',fast:'roza',month:'mahina',mahine:'mahina',kaabah:'kaaba',kabah:'kaaba',quraan:'quran',kuran:'quran',koran:'quran',machli:'machhli',fish:'machhli',built:'banaya',banayi:'banaya',aakhri:'last',akhri:'last',aakhiri:'last',akhiri:'last',aakhree:'last',akhree:'last',nabee:'nabi',nabbi:'nabi',naamtha:'naam',paigambar:'nabi',prophet:'nabi',prophets:'nabi',angel:'farishta',farishte:'farishta',kitne:'count',kitni:'count',kitna:'count',kitny:'count',total:'count',kaun:'who',kaunsa:'which',kaunsi:'which',kahan:'where',kaha:'where',kaisa:'how',kaise:'how',kaisein:'how'};
const stop=new Set('me mein mai main men ki ke ka ko hai hain h ho hoti hota hotay hoti hota tha thi thin the a an of in is was are were there do does did we our hamara hamare hamari mujhe batao btao batayein batayen tell please kya what alaisalam alaihissalam alayhissalam alaihis alayhis salam hazrat as'.split(' '));
const protectedWords=new Set('fajr zuhr dhuhr asr maghrib isha witr eid janaza adam idris nuh hud salih ibrahim lut ismail ishaq yaqub yusuf ayyub shuayb musa harun dhulkifl dawud sulayman ilyas alyasa yunus zakariya yahya isa muhammad sarah hajar fard sunnah nahi nahin not never without chhoot chhuti qaza after before baad pehle'.split(' '));
function tokens(text){
 const q=romanQuestion(text).normalize('NFKC').toLowerCase()
  .replace(/sub[ah]+\s+ki\s+nama[az]+/g,'fajr namaz').replace(/morning\s+prayer/g,'fajr namaz').replace(/how\s+many/g,'count')
  .replace(/sallallahu\s+alaihi\s+wa\s+sallam/g,' ')
  .replace(/[^\p{L}\p{N}\p{M}]+/gu,' ');
 return [...new Set(q.trim().split(/\s+/).map(canonical).filter(w=>w&&!stop.has(w)))].sort();
}
// One small spelling error is allowed, but never for a protected person,
// prayer, qualifier, number or negation. Unknown extra concepts are retained.
function typo(a,b){
 if(a===b)return true;
 if(a.length<5||b.length<5||protectedWords.has(a)||protectedWords.has(b)||/\d/.test(a+b)||Math.abs(a.length-b.length)>1)return false;
 if(a.length===b.length){const changed=[];for(let i=0;i<a.length;i++)if(a[i]!==b[i])changed.push(i);
  return changed.length===1||(changed.length===2&&changed[1]===changed[0]+1&&a[changed[0]]===b[changed[1]]&&a[changed[1]]===b[changed[0]]);}
 const [short,long]=a.length<b.length?[a,b]:[b,a];
 let i=0,j=0,skips=0;while(i<short.length&&j<long.length){if(short[i]===long[j]){i++;j++;}else{j++;if(++skips>1)return false;}}return true;
}
function canonical(w){
 if(aliases[w])return aliases[w];
 if(w.length<5||protectedWords.has(w)||/\d/.test(w))return w;
 const choices=new Set(Object.entries(aliases).filter(([key,value])=>!protectedWords.has(key)&&!protectedWords.has(value)&&typo(w,key)).map(([,value])=>value));
 return choices.size===1?[...choices][0]:w;
}
function vocabulary(data){
 if(compiled.has(data))return compiled.get(data);
 const rows=data.facts.flatMap(f=>(f.questions||[]).map(q=>({id:f.id,words:tokens(q)})));
 compiled.set(data,rows);return rows;
}
function quickIntent(question,data=require('./quick_answers.json')){
 const words=tokens(question);if(!words.length)return null;
 const matches=new Set();
 for(const row of vocabulary(data)){
  if(words.length!==row.words.length)continue;
  const rest=[...row.words];let edits=0,ok=true;
  // Exact tokens first; only one unmatched token may have a tiny typo.
  const unmatched=[];
  for(const w of words){const i=rest.indexOf(w);if(i>=0)rest.splice(i,1);else unmatched.push(w);}
  if(unmatched.length>1)continue;
  for(const w of unmatched){const i=rest.findIndex(v=>typo(w,v));if(i<0){ok=false;break;}rest.splice(i,1);edits++;}
  if(ok&&rest.length===0&&edits<=1)matches.add(row.id);
 }
 return matches.size===1?[...matches][0]:null;
}
function answerForFact(id,kind,data){
 const fact=data.facts.find(f=>f.id===id);if(!fact)return null;
 const hits=fact.hits.filter(h=>kind==='all'||h.kind===kind);if(!hits.length)return null;
 return {status:'answered',answerMode:'sources-only',paragraphs:[],speech_urdu:'',speech_english:'',hits,
  followup:fact.answer,answer:{type:'reviewed-source',text:fact.answer,
   reference:hits.map(h=>h.kind==='quran'?`Quran ${h.surah}:${h.number}`:`${h.title} ${h.number}`).join('\n')}};
}
function quickAnswer(question,kind,data){return answerForFact(quickIntent(question,data),kind,data);}
module.exports={quickIntent,quickAnswer,answerForFact,tokens};
