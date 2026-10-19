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
 const {call}=fixture(),now=Date.UTC(2026,0,1);
 await call('u1',now);await assert.rejects(call('u1',now+1000),/limited/);
 await call('u1',now+6000,{userLimit:2});await assert.rejects(call('u1',now+12000,{userLimit:2}),/limited/);
});
test('global limit applies across independent anonymous users',async()=>{
 const {call}=fixture(),now=Date.UTC(2026,0,1);
 await call('a',now,{globalLimit:2});await call('b',now,{globalLimit:2});
 await assert.rejects(call('c',now,{globalLimit:2}),/limited/);
});
test('day rollover resets quota; records contain no question or plain UID',async()=>{
 const {call,store}=fixture(),now=Date.UTC(2026,0,1);
 await call('private-uid',now,{userLimit:1});await call('private-uid',now+86400000,{userLimit:1});
 assert.equal(store.size,4);for(const [id,value] of store){assert.ok(!id.includes('private-uid'));assert.ok(value.expiresAt>now);assert.equal(value.question,undefined);}
});
