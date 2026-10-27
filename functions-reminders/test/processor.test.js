const {test}=require('node:test');const a=require('node:assert/strict');
const {createProcessor}=require('../processor');const {DAY}=require('../policy');
const ts=ms=>({toMillis:()=>ms});
function fixture({devices=true,fail=false}={}){
 let now=20*DAY,sends=0,txCount=0,afterClaim; const payloads=[];
 const data=new Map([['masjids/m',{name:'Test',verificationStatus:'Verified',adminUid:'owner',timesUpdatedAt:ts(DAY)}]]);
 if(devices)data.set('_timingReminderDevices/d',{token:'secret-token',masjidId:'m',uid:'owner',updatedAt:ts(now)});
 const ref=path=>({path,id:path.split('/').at(-1),get:async()=>snap(path),set:async(v,o)=>data.set(path,{...(o?.merge?data.get(path):{}),...v}),delete:async()=>data.delete(path)});
 const snap=path=>({exists:data.has(path),data:()=>data.get(path),ref:ref(path)});
 const db={collection:name=>({doc:id=>ref(name+'/'+id),where:(key,op,value)=>({get:async()=>({docs:[...data.keys()].filter(p=>p.startsWith(name+'/')&&data.get(p)[key]===value).map(snap)})})}),runTransaction:async f=>{const out=await f({get:async r=>r.get(),set:(r,v,o)=>r.set(v,o),update:(r,v)=>r.set(v,{merge:true})});txCount++;if(txCount===1&&afterClaim)afterClaim();return out;}};
 const messaging={sendEachForMulticast:async payload=>{sends++;payloads.push(payload);a.equal(payload.android.ttl,3600000);a.equal(payload.data.masjidId,'m');if(fail)throw Error('network');return {successCount:payload.tokens.length,responses:payload.tokens.map(()=>({success:true}))};}};
 const processor=createProcessor({db,messaging,Timestamp:{fromMillis:ts},stamp:()=>ts(now),clock:()=>now});
 return {payloads,run:()=>processor(ref('masjids/m'),{sent:0,failed:0}),data,sends:()=>sends,setNow:v=>now=v,afterClaim:f=>afterClaim=f};
}
test('successful push records cadence; rerun does not duplicate; repeat after five days',async()=>{const f=fixture();await f.run();await f.run();a.equal(f.sends(),1);f.setNow(25*DAY);await f.run();a.equal(f.sends(),2);});
test('saving timings cancels old cadence and waits ten more days',async()=>{const f=fixture();await f.run();f.data.get('masjids/m').timesUpdatedAt=ts(21*DAY);f.setNow(26*DAY);await f.run();a.equal(f.sends(),1);f.setNow(31*DAY);await f.run();a.equal(f.sends(),2);});
test('concurrent timing change after claim cancels before push',async()=>{const f=fixture();f.afterClaim(()=>f.data.get('masjids/m').timesUpdatedAt=ts(20*DAY));await f.run();a.equal(f.sends(),0);a.equal(f.data.get('_timingReminderState/m').leaseUntil.toMillis(),0);});
test('former owners and missing devices never count as delivered',async()=>{for(const devices of [true,false]){const f=fixture({devices});if(devices)f.data.get('_timingReminderDevices/d').uid='old';await f.run();a.equal(f.sends(),0);a.equal(f.data.get('_timingReminderState/m').lastSentAt,undefined);}});
test('FCM failure clears lease without starting a five day cooldown',async()=>{const f=fixture({fail:true});await a.rejects(f.run());const s=f.data.get('_timingReminderState/m');a.equal(s.leaseUntil.toMillis(),0);a.equal(s.lastSentAt,undefined);});

test('automatic reminders separate English and Urdu payloads; legacy devices default to English',async()=>{
 const f=fixture();
 f.data.set('_timingReminderDevices/urdu',{token:'urdu-device',masjidId:'m',uid:'owner',language:'ur',updatedAt:ts(20*DAY)});
 await f.run();a.equal(f.sends(),2);
 const en=f.payloads.find(p=>p.tokens.includes('secret-token')),ur=f.payloads.find(p=>p.tokens.includes('urdu-device'));
 a.equal(en.notification.title,'Review Prayer Timings');a.equal(ur.notification.title,'نماز کے اوقات کا جائزہ');
 a.equal(en.tokens.length,1);a.equal(ur.tokens.length,1);
});
