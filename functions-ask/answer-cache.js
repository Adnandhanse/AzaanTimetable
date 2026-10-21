'use strict';
const {createHash}=require('node:crypto');
// Per-instance RAM only: bounded, ten minutes, no disk/database writes or raw
// question keys. Only successful canonical-source results are retained.
function createAnswerCache({now=Date.now,ttlMs=600000,maxBytes=1048576,maxEntries=32}={}) {
 const entries=new Map();let bytes=0;
 function remove(key){const old=entries.get(key);if(old){bytes-=old.bytes;entries.delete(key);}}
 return {
  key:(model,kind,question)=>createHash('sha256').update(JSON.stringify([model,kind,question.normalize('NFKC').toLowerCase().replace(/[?!؟।]+$/gu,' ').trim().replace(/\s+/g,' ')])).digest('hex'),
  get(key){const entry=entries.get(key);if(!entry)return null;
   if(entry.expires<=now()){remove(key);return null;}return JSON.parse(entry.json);},
  put(key,result){if(result.status!=='answered'||(!result.hits?.length&&!result.answer))return;
   const json=JSON.stringify(result),size=Buffer.byteLength(json);if(size>maxBytes)return;
   remove(key);for(const [k,e] of entries)if(e.expires<=now())remove(k);
   while(entries.size>=maxEntries||bytes+size>maxBytes)remove(entries.keys().next().value);
   entries.set(key,{json,bytes:size,expires:now()+ttlMs});bytes+=size;}
 };
}
module.exports={createAnswerCache};
