'use strict';
const {readCorpus}=require('./corpus-loader'),{retrieveEvidence}=require('./assistant-retrieval');
const path=require('node:path'),assert=require('node:assert/strict');
(async()=>{
 const docs=await readCorpus(path.join(__dirname,'corpus.ndjson.gz')),checks=[];
 for(const question of ['namaz ka tariqa kya hai','zakat kya hai','zakat ke bare me hadees batao','namaz ka tarika batao','How do I perform salah step by step?','sone se pehle ki dua','maa baap ke huqooq','gussa kaise control karu','aakhri nabi ka naam kya hai']){
  const start=Date.now(),r=retrieveEvidence(question,[],docs),top=r.evidence.slice(0,3);
  assert.ok(top.length,question);
  if(/tarika|tariqa|step/.test(question))assert.ok(top.some(d=>/bow/i.test(d.text)&&/prostrat/i.test(d.text)),'Procedure evidence must contain prayer actions');
  if(/sone/.test(question))assert.ok(top.some(d=>d.kind==='dua'&&/sleep/i.test(r.index.byId.get(d.id).chapter)),'Bedtime collection entry');
  if(/maa/.test(question))assert.ok(top.some(d=>d.kind==='quran'&&/parents.*(?:good|kind)/i.test(d.text)),'Parent treatment evidence');
  if(/gussa/.test(question))assert.ok(top.some(d=>/controls.*(?:anger|rage)|restrain anger/i.test(d.text)),'Anger-control evidence');
  if(/aakhri/.test(question))assert.ok(top.some(d=>/last of the prophets|seal of the prophets/i.test(d.text)),'Final Prophet evidence');
  if(/zakat/.test(question))assert.ok(top.some(d=>d.kind==='hadith'&&/zakat/i.test(d.text)),'Zakat evidence must contain the actual subject, not narrator-only text');
  if(/hadees/.test(question))assert.ok(r.evidence.every(d=>d.kind==='hadith'),'Hadith request must retain Hadith sources');
  checks.push({question,retrievalMs:Date.now()-start,ids:top.map(d=>d.id)});
 }
 console.log(JSON.stringify({checks,peakRssMiB:Math.ceil(process.resourceUsage().maxRSS/1024),liveGemini:false},null,2));
})().catch(e=>{console.error(e);process.exitCode=1;});
