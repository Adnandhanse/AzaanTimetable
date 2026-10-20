'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs/promises');
const os=require('node:os');
const path=require('node:path');
const {gzipSync}=require('node:zlib');
const {readCorpus,createCorpusLoader}=require('../corpus-loader');
test('stream preserves canonical multilingual text and precomputed search index',async()=>{
 const dir=await fs.mkdtemp(path.join(os.tmpdir(),'ask-corpus-'));
 try {
  const docs=[{id:'a',en:'source',ur:'اردو',ar:'عربي',normalized:' source اردو '},
   {id:'b',roman:'Qissa',normalized:' qissa '}];
  const file=path.join(dir,'library.gz');
  await fs.writeFile(file,gzipSync(docs.map(d=>JSON.stringify(d)).join('\n')+'\n'));
  assert.deepEqual(await readCorpus(file),docs);
 } finally {await fs.rm(dir,{recursive:true,force:true});}
});
test('concurrent requests share one load and retry only after a failed load',async()=>{
 let count=0;
 const docs=[{id:'a',normalized:' a '}];
 const load=createCorpusLoader('unused',async()=>{count++;if(count===1)throw Error('read failed');return docs;});
 await assert.rejects(load());
 const [a,b]=await Promise.all([load(),load()]);
 assert.equal(count,2);assert.strictEqual(a,docs);assert.strictEqual(a,b);
});
test('missing and corrupt files reject rather than hang or return a partial corpus',async()=>{
 const dir=await fs.mkdtemp(path.join(os.tmpdir(),'ask-corpus-'));
 try {
  await assert.rejects(readCorpus(path.join(dir,'missing.gz')));
  const file=path.join(dir,'bad.gz');await fs.writeFile(file,'not gzip');
  await assert.rejects(readCorpus(file));
  await fs.writeFile(file,gzipSync('{"id":"a","normalized":" a "}\n{"id":"b"}\n'));
  await assert.rejects(readCorpus(file),/invalid-corpus-record/);
 } finally {await fs.rm(dir,{recursive:true,force:true});}
});
