'use strict';
// Deployment check with the real corpus, no Gemini/Firebase credentials needed.
const path=require('node:path');
const assert=require('node:assert/strict');
const {readCorpus}=require('./corpus-loader');
const {normalize,retrieve,contextFor}=require('./core');
(async()=>{
  const docs=await readCorpus(path.join(__dirname,'corpus.ndjson.gz'));
  const manifest=require('./corpus_manifest.json');
  assert.equal(docs.length,manifest.count);
  assert.ok(docs.length>=40000);
  assert.equal(new Set(docs.map(d=>d.id)).size,docs.length);
  for (const d of [docs[0],docs[7000],docs[docs.length-1]])
    assert.equal(d.normalized,` ${normalize(`${d.en} ${d.ur} ${d.roman || ''} ${d.context || ''} ${d.title} ${d.chapter || ''}`)} `);
  for(const must of [[['parents','mother','father']],[['prayer'],['hands','hand']],
    [['revelation','prophethood']]]) {
    const hits=retrieve(docs,{searches:[{must,boost:[]}]});
    assert.ok(hits.length>0);
    assert.ok(contextFor(hits).length>0);
  }
  const peakMiB=Math.ceil(process.resourceUsage().maxRSS/1024);
  assert.ok(peakMiB<900,`Corpus check peak RSS ${peakMiB} MiB exceeds budget`);
  console.log({records:docs.length,peakRssMiB:peakMiB,check:'passed'});
})().catch(error=>{console.error(error);process.exitCode=1;});
