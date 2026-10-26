'use strict';
const {normalize}=require('./core');
const {romanQuestion}=require('./question-language');
const entities=[
 ['ibrahim','ibraheem','abraham'],['musa','moses'],['isa','jesus'],['nuh','noah'],['adam'],['ismail','ishmael'],['ishaq','isaac'],['yaqub','jacob'],['yusuf','joseph'],['yunus','jonah'],['muhammad','mohammad'],['maryam','mary'],
 ['fajr','fajar'],['dhuhr','zuhr','zohar'],['asr','asar'],['maghrib','magrib'],['isha','esha'],['wudu','wuzu','wudhu'],['namaz','salah','prayer'],['roza','fasting'],['zakat','zakah']
];
function focusQuestion(question,history=[]){
 let q=normalize(romanQuestion(question)).replace(/\b(?:maa|ma|ammi)\s+(?:(?:aur|or|and)\s+)?(?:baap|abbu|walid)\b/g,'parents');
 const words=new Set(q.split(' '));
 const elliptical=/\b(?:isme|ismein|usme|usmein|unka|unki|unke|iska|iski|uska|uski|it|its|they|their|those|that|this|aur|more|also)\b/u.test(q);
 if(!elliptical)return {query:q,inheritedTopic:null};
 const explicit=entities.filter(g=>g.some(w=>words.has(w)));
 if(explicit.length)return {query:q,inheritedTopic:null};
 // Only known topic names from user messages supplement retrieval. A previous
 // assistant's generated claims never become trusted evidence or search facts.
 for(const turn of [...history].reverse()){
  if(turn.role!=='user')continue;
  const old=new Set(normalize(romanQuestion(turn.content)).split(' '));
  const topics=entities.filter(g=>g.some(w=>old.has(w)));
  if(topics.length){const topic=topics[0][0];return {query:topic+' '+q,inheritedTopic:topic};}
 }
 return {query:q,inheritedTopic:null};
}
module.exports={focusQuestion};
