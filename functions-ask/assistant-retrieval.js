'use strict';
const {normalize,excerpt}=require('./core');
const {romanQuestion}=require('./question-language');
const {focusQuestion}=require('./question-focus');
const notes=require('./scholarly-notes.json');
const reviewed=require('./quick_answers.json').facts;
const indexes=new WeakMap();
const stop=new Set('a an the is are was were what who how many does do did can could please tell explain about me my i you your in on of to for and or it this that have has hain hai tha thi kya ka ki ke ko se mein me mujhe batao btao kitni kitne kitna isme usme alaisalam alaihis salam alaihissalam hazrat number reference exact give why where when teaching teachings teach say says said ruling hukm s not no should would we our us they their them he she his her had be been being am being must was were related regarding happened happen step steps by kaise kese karu karoon karein karna krna kab kb mili mila mile milti hoga hogi hua hui aap ap saws sawas bata dena samjhao pehle phele before after baad'.split(' '));
const groups=[
 ['namaz','namaaz','namaj','salah','salaah','salat','prayer','نماز','صلاة'],
 ['rakat','rakaat','rakatain','rakate','rakatein','rakaatein','rakah','rakahs','rakats','rakate','رکعت','رکعات'],
 ['farz','fard','obligatory','فرض'],['sunnat','sunnah','supererogatory','voluntary','سنت'],
 ['biwi','wife','wives','begum','spouse','بیوی'],['walida','mother','maa','ammi','والدہ'],['walid','father','baap','والد'],
 ['ibrahim','ibraheem','abraham','ابراہیم'],['isa','jesus','عیسی'],['musa','moses','موسی'],['nuh','noah','نوح'],
 ['adam','آدم'],['idris','ادریس'],['hud','ہود'],['salih','saleh','صالح'],['lut','lot','لوط'],
 ['ismail','ishmael','اسماعیل'],['ishaq','isaac','اسحاق'],['yaqub','jacob','یعقوب'],['ayyub','job','ایوب'],
 ['shuayb','shuaib','شعیب'],['harun','aaron','ہارون'],['dhulkifl','ذوالکفل'],['dawud','david','داود'],
 ['sulayman','solomon','سلیمان'],['ilyas','elijah','الیاس'],['alyasa','elisha','الیسع'],['zakariya','zechariah','zachariah','زکریا'],['yahya','john','یحیی'],
 ['yunus','jonah','یونس'],['yusuf','joseph','یوسف'],['maryam','mary','مریم'],['hajar','hagar','hajra','ہاجرہ'],
 ['sarah','sara','سارہ'],['muhammad','mohammad','محمد'],['fajr','fajar','fazr','فجر'],
 ['wuzu','wudu','wudhu','ablution','وضو'],['toot','tut','tootta','break','invalidate','invalidates','invalidated','nullify','ٹوٹ'],
 ['chhoona','chhuna','chhune','choone','touch','touched','touches','touching','contact','چھونا'],['haath','hath','hand','hands','ہاتھ'],
 ['uthana','uthane','uthate','raise','raising','raised','اٹھانا'],['baandhna','bandhna','baandhne','fold','folding','placed','باندھنا'],
 ['ungli','finger','forefinger','انگلی'],['harkat','hilana','hilane','move','moving','motion','حرکت'],
 ['roza','roze','fast','fasting','روزہ'],['dua','duaa','supplication','invocation','دعا'],
 ['nabuwwat','nabuwat','nabuat','nabuat','naboowat','prophethood','commissioned','appointed','divine inspiration','revelation','نبوت'],
 ['umar','umr','age','old','عمر'],
 ['quran','kuran','quraan','koran','قرآن'],['hadees','hadis','hadith','narration','حدیث'],
 ['tarika','tareeqa','method','perform','procedure','طریقہ'],['qaza','missed','قضا'],
 ['hanafi','hanfi','حنفی'],['shafii','shafi','shafie','shafii','شافعی'],['maliki','مالکی'],['hanbali','حنبلی'],
 ['ikhtilaf','differences','difference','madhhab','schools','مسلک'],['nam','naam','name','نام'],
 ['kitni','kitne','kitna','count','many','کتنی'],['aakhri','akhri','akhiri','last','final','seal','khatam','آخری'],
 ['nabi','nabee','prophet','prophets','apostle','messenger','anbiya','paigambar','نبی'],['patience','sabr','صبر'],['parents','parent','walidain','والدین'],
 ['kindness','kind','good','ihsan','neki','احسان'],['neighbour','neighbor','neighbours','neighbors','padosi','پڑوسی'],
 ['sleep','sleeping','bed','bedtime','sone','sona','سونے'],['prison','prisoners','prisonmates','imprisoned','jail','qaid','قید'],
 ['zakat','zakah','charity','زکات'],['qibla','direction','قبلہ'],
 ['gussa','gusse','ghussa','ghusse','anger','angry','rage','غصہ'],
 ['jhoot','jhut','jhooth','lie','lies','lying','falsehood','جھوٹ'],
 ['sach','truth','truthful','honesty','honest','سچ'],
 ['maaf','maafi','forgive','forgiveness','pardon','معاف'],
 ['rizq','rozi','provision','sustenance','livelihood','رزق'],
 ['huqooq','haqooq','rights','duties','respect','kindness','kind','dutiful','obedience','treatment','good','حقوق'],
 ['bachay','bachche','bache','children','child','بچے'],
 ['beta','bete','son','sons','بیٹا'],['beti','betiyan','daughter','daughters','بیٹی'],
 ['salam','salaam','greeting','greetings','سلام'],
 ['khana','khaana','eating','eat','food','کھانا'],
 ['control','restrain','restraining','suppress','repress','قابو']
].map(g=>[...new Set(g.map(normalize))]);
const dictionary=new Map(groups.flatMap(g=>g.map(t=>[t,g])));
function near(a,b){if(a.length<5||Math.abs(a.length-b.length)>1)return false;let i=0,j=0,n=0;while(i<a.length&&j<b.length){if(a[i]===b[j]){i++;j++;}else{if(++n>1)return false;if(a.length>=b.length)i++;if(b.length>=a.length)j++;}}return n+(a.length-i)+(b.length-j)<=1;}
function queryGroups(question,history=[]){
 const focused=focusQuestion(question,history);
 const words=focused.query.split(' ').filter(w=>w.length>1&&!stop.has(w));
 const result=[];
 for(const w of words){
  let g=dictionary.get(w);
  if(!g&&/^[a-z]+$/.test(w)){
   const matches=[...new Set([...dictionary.keys()].filter(t=>near(w,t)).map(t=>dictionary.get(t)))];
   if(matches.length===1)g=matches[0];
  }
  g=g||[w];if(!result.some(r=>r===g||r[0]===g[0]))result.push(g);
 }
 // Request-format words need not appear verbatim in scripture. A person
 // asking for a method still needs the subject's relevant evidence.
 const content=result.filter(g=>!['tarika','nam','kitni'].includes(g[0]));
 return (content.length?content:result).slice(0,12);
}
function corpusIndex(docs){
 if(indexes.has(docs))return indexes.get(docs);
 const all=[...docs,...notes.map(n=>({...n,ur:'',ar:'',grades:[],normalized:` ${normalize(n.en+' '+n.tags.join(' '))} `}))];
 const byId=new Map(all.map(d=>[d.id,d]));const index={all,byId};indexes.set(docs,index);return index;
}
function exactLookup(question,index){
 const q=romanQuestion(question).toLowerCase().replace(/[٠-٩۰-۹०-९]/g,c=>{const n=c.charCodeAt(0);return String(n-(n>=2406?2406:n>=1776?1776:1632));});
 const verse=q.match(/(?:quran|قرآن|surah|سورہ|सूरह)\s*(?:[^\d\n]{0,25})?(\d{1,3})\s*[:/]\s*(\d{1,3})/u);
 if(verse){const id=`quran:${Number(verse[1])}:${Number(verse[2])}`;return {requested:true,doc:index.byId.get(id),id};}
 const books={bukhari:/(bukhari|bukhaari|بخاری|बुखारी|बुख़ारी)/u,muslim:/(muslim|مسلم|मुस्लिम)/u,abudawud:/(abu\s*daw[ou]+d|ابو داود)/u,tirmidhi:/(tirmidhi|ترمذی)/u,nasai:/(nasai|نسائی)/u,ibnmajah:/(ibn\s*majah|ابن ماجہ)/u};
 for(const [book,re] of Object.entries(books)){
  const m=q.match(re);if(!m)continue;
  const n=q.slice(m.index+m[0].length).match(/^[\s#:(-]*(?:(?:hadith|hadees|number|no|reference|حدیث|نمبر)\s*[#.:]?\s*){0,3}(\d{1,6})([a-z])?\b/u);
  if(n){const id=`hadith:${book}:${Number(n[1])}${n[2]||''}`;return {requested:true,doc:index.byId.get(id),id};}
 }
 return {requested:false,wantsExact:/(?:exact|precise|sahi|saheeh|حوالہ|حوالا|सटीक|हवाला).*(?:reference|hadith|hadees|حوال|حدیث|हदीस)|(?:exact reference|حوالہ|सटीक संदर्भ)/iu.test(question)};
}
function retrieveEvidence(question,history,docs){
 const index=corpusIndex(docs),exact=exactLookup(question,index),terms=queryGroups(question,history),matches=[];
 if(exact.doc)matches.push({doc:exact.doc,score:1e6,terms:terms.flat()});
 if(!exact.requested){
  const frequencies=new Array(terms.length).fill(0),rows=[];
  const domain=g=>g.includes('quran')||g.includes('hadith')||g.includes('dua');
  for(const doc of index.all){
   const matched=[];
   for(let i=0;i<terms.length;i++) {
    const g=terms[i];
    const hit=(g.includes('quran')&&doc.kind==='quran')||(g.includes('hadith')&&doc.kind==='hadith')||(g.includes('dua')&&doc.kind==='dua')||g.some(t=>doc.normalized.includes(` ${t} `));
    if(hit){matched.push(i);frequencies[i]++;}
   }
   if(matched.length)rows.push({doc,matched});
  }
  const useful=terms.map((g,i)=>frequencies[i]&&!domain(g)?i:-1).filter(i=>i>=0);
  const strong=new Set(['adam','idris','hud','salih','lut','ismail','ishaq','yaqub','ayyub','shuayb','harun','dhulkifl','dawud','sulayman','ilyas','alyasa','zakariya','yahya','fajr','ibrahim','musa','isa','nuh','yunus','yusuf','nabuwwat','parents','biwi','haath','ungli','wuzu','roza','sleep','prison']);
  const required=useful.filter(i=>strong.has(terms[i][0]));
  const threshold=Math.min(2,useful.length);
  const broadSubject=terms.length===1&&terms[0].includes('prayer');
  const procedural=broadSubject&&/tarika|tareeqa|method|perform|step|how.*(?:pray|salah)|طریق|तरी/iu.test(question);
  const reviewedBoost=new Map();
  // Reuse the existing reviewed knowledge set as evidence anchors across
  // paraphrases, without turning the whole assistant into a fixed FAQ router.
  for(const fact of reviewed){
   const text=` ${normalize([fact.answer,...Object.values(fact.answers||{}),...(fact.questions||[])].join(' '))} `;
   const found=useful.filter(i=>terms[i].some(t=>text.includes(` ${t} `)));
   if(required.some(i=>!found.includes(i))||found.length<Math.max(2,threshold))continue;
   for(const hit of fact.hits||[])reviewedBoost.set(hit.id,Math.max(reviewedBoost.get(hit.id)||0,found.length*18));
  }
  if(threshold)for(const {doc,matched} of rows){
   if(matched.filter(i=>useful.includes(i)).length<threshold||required.some(i=>!matched.includes(i)))continue;
   const body=` ${normalize(doc.en||doc.ur||doc.roman||'')} `;
   if(doc.kind==='hadith'&&(body.length<60||required.some(i=>!terms[i].some(t=>body.includes(` ${t} `)))))continue;
   let score=matched.reduce((n,i)=>n+(domain(terms[i])?.5:1+Math.log((index.all.length+1)/(frequencies[i]+1))),0);
   score+=reviewedBoost.get(doc.id)||0;
   if(broadSubject&&doc.kind==='hadith'&&/prayer|salat/i.test(doc.context||''))score+=3;
   if(procedural&&doc.kind==='hadith') {
    const stages=[/qibla/i,/takbir|allahu akbar/i,/recit/i,/bow|ruku/i,/prostrat|sujud/i,/sit|sitting/i];
    const covered=stages.filter(re=>re.test(doc.en||'')).length;
    if(covered>=3)score+=covered*6;
   }
   if(terms.some(g=>g.includes('dua'))&&doc.kind==='dua')score+=5;
   if(doc.kind==='dua'&&terms.some(g=>g.includes('sleep'))&&/sleep|bed/i.test(doc.chapter||''))score+=20;
   if(doc.kind==='dua'&&/before|pehle/i.test(question)&&/before/i.test(doc.chapter||''))score+=6;
   if(terms.some(g=>g.includes('parents'))) {
    if(/parents be sacrificed|parents.*ransom|father and mother.*sacrificed/i.test(doc.en||''))score-=25;
    if(/(?:kind|good|dutiful|obey|honou?r|treat)/i.test(doc.en||''))score+=4;
   }
   const asksGrade=/grade|authentic|sahih|saheeh|zaeef|daif|ضعیف|صحیح/iu.test(question);
   if(doc.kind==='hadith'&&!asksGrade){
    const gs=(doc.grades||[]).join(' ');
    if(['bukhari','muslim'].includes(doc.book))score+=4;
    else if(/daif|weak|fabricated|mawdu|ضعیف/iu.test(gs+' '+(doc.en||'')))score-=25;
   }
   if(doc.kind==='scholarly'&&terms.some(g=>g.includes('madhhab')))score+=5;
   if(doc.kind==='story'&&terms.some(g=>g.includes(doc.storyId)))score+=3;
   if(terms.some(g=>g.includes('prophethood'))&&/\b(?:kab|kb|when|age|umar|umr)\b/i.test(question)&&doc.kind==='hadith'&&/(?:at (?:the )?age of|when he was|reached the age of)/i.test(doc.en||''))score+=45;
   const prophetAliases={ismail:'ishmael',ishaq:'isaac',yaqub:'jacob',ayyub:'job',harun:'aaron',dawud:'david',sulayman:'solomon',ilyas:'elijah',alyasa:'elisha',zakariya:'zechariah',yahya:'john',ibrahim:'abraham',musa:'moses',isa:'jesus',nuh:'noah',yunus:'jonah',yusuf:'joseph'};
   for(const i of required){const preferred=prophetAliases[terms[i][0]];
    if(preferred&&doc.normalized.includes(` ${preferred} `))score+=5;
   }
   matches.push({doc,score,terms:terms.flat()});
  }
 }
 matches.sort((a,b)=>b.score-a.score||a.doc.normalized.length-b.doc.normalized.length);
 const seen=new Set();const unique=matches.filter(x=>{const key=normalize(x.doc.en||x.doc.ur||x.doc.roman||'');if(seen.has(key))return false;seen.add(key);return true;});
 // Avoid letting near-identical narrations crowd every other relevant source
 // type out of the evidence window. Generation still decides what to cite.
 const selected=unique.slice(0,4);
 for(const kind of ['quran','story','scholarly','dua']){
  if(selected.some(x=>x.doc.kind===kind))continue;
  const next=unique.find(x=>x.doc.kind===kind);if(next&&selected.length<8)selected.push(next);
 }
 for(const next of unique){if(selected.length===8)break;if(!selected.includes(next))selected.push(next);}
 const evidence=selected.map(({doc,terms})=>({id:doc.id,kind:doc.kind,title:doc.title,
  publisher:doc.publisher||'',contentType:doc.contentType||(doc.kind==='story'?'editorial-retelling':'source-text'),
  text:excerpt(doc.en||doc.ur||doc.roman,terms,1400),grades:doc.grades||[],sources:doc.sources||[]}));
 return {index,evidence,exact};
}
module.exports={retrieveEvidence,corpusIndex,exactLookup,queryGroups};
