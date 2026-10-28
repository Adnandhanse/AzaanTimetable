const {test}=require('node:test');
const assert=require('node:assert/strict');
const {reserveQuota}=require('../quota');
function fixture() {
 const store=new Map();
 const db={collection:()=>({doc:id=>id}),runTransaction:async fn=>fn({get:async id=>({data:()=>store.get(id)}),set:(id,data)=>store.set(id,data)})};
 const call=(uid,now,limits={})=>reserveQuota({db,uid,now,timestamp:x=>x,limited:()=>Error('limited'),...limits});
 return {call,store};
}
test('per-user and short-interval quota reject requests before provider calls',async()=>{
 const {call}=fixture(),now=Date.UTC(2026,0,1,12);
 await call('u1',now);await assert.rejects(call('u1',now+1000),/limited/);
 await call('u1',now+6000,{userLimit:2});await assert.rejects(call('u1',now+12000,{userLimit:2}),/limited/);
});
test('global limit applies across independent anonymous users',async()=>{
 const {call}=fixture(),now=Date.UTC(2026,0,1,12);
 await call('a',now,{globalLimit:2});await call('b',now,{globalLimit:2});
 await assert.rejects(call('c',now,{globalLimit:2}),/limited/);
});
test('day rollover resets quota; records contain no question or plain UID',async()=>{
 const {call,store}=fixture(),now=Date.UTC(2026,0,1,12);
 await call('private-uid',now,{userLimit:1});await call('private-uid',now+86400000,{userLimit:1});
 assert.equal(store.size,4);for(const [id,value] of store){assert.ok(!id.includes('private-uid'));assert.ok(value.expiresAt>now);assert.equal(value.question,undefined);}
});
test('quota resets at Pacific midnight, not UTC midnight',async()=>{
 const {call}=fixture();
 await call('u',Date.UTC(2026,0,1,23,59),{userLimit:1});
 await assert.rejects(call('u',Date.UTC(2026,0,2,0,1),{userLimit:1}),/limited/);
 await call('u',Date.UTC(2026,0,2,8,1),{userLimit:1});
});
test('250 reserved questions bound the two-call flow to at most 500 calls',async()=>{
 const {call}=fixture(),now=Date.UTC(2026,0,1,12);
 for(let i=0;i<250;i++)await call('u'+i,now);
 await assert.rejects(call('extra-user',now),/limited/);
});
test('unsuccessful requests refund the personal quota once but never the provider budget',async()=>{
 const {call,store}=fixture(),now=Date.UTC(2026,0,1,12);
 const reservation=await call('u',now,{userLimit:1,globalLimit:2});
 await reservation.refund();await reservation.refund();
 const entries=[...store.entries()];assert.equal(entries.find(([id])=>id.endsWith('-global'))[1].count,1);
 assert.equal(entries.find(([id])=>!id.endsWith('-global'))[1].count,0);
 await assert.rejects(call('u',now+1000,{userLimit:1}),/limited/);
 await call('u',now+6000,{userLimit:1,globalLimit:2});
 await assert.rejects(call('another',now+12000,{globalLimit:2}),/limited/);
});

test('default personal budget is ten; reservation reports accurate counters',async()=>{
 const {call}=fixture(),now=Date.UTC(2026,0,1,12);
 for(let i=0;i<10;i++) {
  const r=await call('u',now+i*6000);
  assert.equal(r.usage.userUsed,i+1);assert.equal(r.usage.globalUsed,i+1);
  assert.equal(r.usage.userLimit,10);assert.equal(r.usage.globalLimit,250);
 }
 await assert.rejects(call('u',now+60000),/limited/);
});
