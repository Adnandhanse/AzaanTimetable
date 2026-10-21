'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {createSharedAnswerCache,optionalCache}=require('../shared-answer-cache');
const {createAnswerCache}=require('../answer-cache');
function database(){const records=new Map();return {records,collection:()=>({doc:key=>({get:async()=>({exists:records.has(key),data:()=>records.get(key)}),set:async value=>records.set(key,value)})})};}
const result={status:'answered',answerMode:'sources-only',understood:'private wording',hits:[{id:'quran:1:1',en:'canonical source'}]};
test('different server instances reuse authenticated cached source results without user interpretation',async()=>{
 const db=database(),options={db,secret:'test-secret',version:'corpus-one',now:()=>0};
 await createSharedAnswerCache(options).put('q',result);
 const r=await createSharedAnswerCache(options).get('q');assert.equal(r.hits[0].id,'quran:1:1');assert.equal(r.understood,undefined);
 assert.ok(!JSON.stringify([...db.records.values()]).includes('private wording'));
});
test('expired, content-version changed, key-rotated and tampered cache records are rejected',async()=>{
 const db=database(),options={db,secret:'test',version:'one',now:()=>0,ttlMs:10};
 const c=createSharedAnswerCache(options);await c.put('q',result);
 assert.equal(await createSharedAnswerCache({...options,version:'two'}).get('q'),null);
 assert.equal(await createSharedAnswerCache({...options,secret:'rotated'}).get('q'),null);
 assert.equal(await createSharedAnswerCache({...options,now:()=>10}).get('q'),null);
 db.records.get('q').json='{"status":"answered","answerMode":"sources-only","hits":["forged"]}';
 assert.equal(await c.get('q'),null);
 db.records.get('q').signature='z'.repeat(64);assert.equal(await c.get('q'),null);
});
test('failed and insufficient results are never shared; cache outage and slow cache are optional',async()=>{
 const db=database(),c=createSharedAnswerCache({db,secret:'test',version:'one'});
 await c.put('failed',{status:'insufficient',hits:[]});assert.equal(db.records.size,0);
 assert.equal(await optionalCache(()=>Promise.reject(Error('offline'))),null);
 assert.equal(await optionalCache(()=>new Promise(()=>{}),5),null);
});
test('same question formatting shares a key but negation and numerical differences do not',()=>{
 const c=createAnswerCache();const key=q=>c.key('model','all',q);
 assert.equal(key('Quran me kitni aayatein hain?'),key('quran me   kitni aayatein hain'));
 assert.notEqual(key('haath uthana hai'),key('haath nahi uthana hai'));
 assert.notEqual(key('1.5'),key('15'));assert.notEqual(key('1/2'),key('1 2'));
});
