'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {createAnswerCache}=require('../answer-cache');
test('successful cache expires, isolates models/kinds, and returns independent values',()=>{
 let time=0;const cache=createAnswerCache({now:()=>time,ttlMs:10});
 const key=cache.key('model','all',' My Question ');
 assert.equal(key,cache.key('model','all','my question'));
 assert.notEqual(key,cache.key('other','all','my question'));
 assert.notEqual(key,cache.key('model','story','my question'));
 cache.put(key,{status:'answered',hits:[{id:'trusted'}]});
 const r=cache.get(key);r.hits[0].id='changed';assert.equal(cache.get(key).hits[0].id,'trusted');
 time=10;assert.equal(cache.get(key),null);
});
test('cache bounds entries and bytes and never caches insufficient results',()=>{
 const cache=createAnswerCache({maxEntries:1,maxBytes:200});
 cache.put('bad',{status:'insufficient',hits:[]});assert.equal(cache.get('bad'),null);
 cache.put('a',{status:'answered',hits:[{id:'a'}]});
 cache.put('b',{status:'answered',hits:[{id:'b'}]});assert.equal(cache.get('a'),null);
 cache.put('large',{status:'answered',hits:[{id:'x'.repeat(300)}]});assert.equal(cache.get('large'),null);
 assert.equal(cache.get('b').hits[0].id,'b');
});
