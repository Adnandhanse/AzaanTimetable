'use strict';
const path=require('node:path'),assert=require('node:assert/strict');
const {readCorpus}=require('./corpus-loader');
const {retrieveEvidence}=require('./assistant-retrieval');
(async()=>{
 const started=Date.now(),docs=await readCorpus(path.join(__dirname,'corpus.ndjson.gz'));
 const loadMs=Date.now()-started,results=[];
 for(const question of ['How should we treat our parents?','ibrahim ki biwi ka naam','namaz mein haath uthana','Does touching my wife break wudu? Hanafi Shafii differences','dua before sleeping','What happened to Yusuf in prison?']){
  const t=Date.now(),r=retrieveEvidence(question,[],docs);
  assert.ok(r.evidence.length,question);
  if(question.includes('Hanafi'))assert.ok(r.evidence.some(e=>e.kind==='scholarly'));
  if(question.includes('prison'))assert.ok(r.evidence.some(e=>e.kind==='story'));
  results.push({question,retrievalMs:Date.now()-t,ids:r.evidence.slice(0,3).map(e=>e.id)});
 }
 const result={records:docs.length,loadMs,peakRssMiB:Math.ceil(process.resourceUsage().maxRSS/1024),checks:results,liveGemini:false};
 assert.ok(result.peakRssMiB<1100,'Assistant retrieval memory budget');
 console.log(JSON.stringify(result,null,2));
})().catch(e=>{console.error(e);process.exitCode=1;});
