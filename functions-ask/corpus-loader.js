'use strict';
const fs=require('node:fs');
const {createGunzip}=require('node:zlib');
const {createInterface}=require('node:readline');

// Decode one pre-indexed record at a time. Do not inflate a whole JSON array,
// stringify its multilingual body again or normalize the library in a request.
async function readCorpus(filename) {
  const input=fs.createReadStream(filename);
  const unzip=createGunzip();
  input.on('error',error=>unzip.destroy(error));
  input.pipe(unzip);
  const lines=createInterface({input:unzip,crlfDelay:Infinity});
  const docs=[];
  try {
    for await (const line of lines) {
      if (!line.trim()) continue;
      const doc=JSON.parse(line);
      if (!doc.id || typeof doc.normalized!=='string') throw Error('invalid-corpus-record');
      docs.push(doc);
    }
    if (!docs.length) throw Error('empty-corpus');
    return docs;
  } finally { lines.close(); input.destroy(); unzip.destroy(); }
}
function createCorpusLoader(filename, reader=readCorpus) {
  let pending;
  return () => {
    // Share initialization even if callers arrive together; retry after failure.
    if (!pending) pending=Promise.resolve().then(()=>reader(filename)).catch(error=>{
      pending=undefined; throw error;
    });
    return pending;
  };
}
module.exports={readCorpus,createCorpusLoader};
