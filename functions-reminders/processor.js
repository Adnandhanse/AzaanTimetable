'use strict';
const {baseline,owner,due,DAY}=require('./policy');
function createProcessor({db,messaging,Timestamp,stamp,clock=Date.now}){
return async function processMasjid(ref,counts){
 const stateRef=db.collection('_timingReminderState').doc(ref.id),now=clock();
 const claim=await db.runTransaction(async tx=>{
  const [m,s]=await Promise.all([tx.get(ref),tx.get(stateRef)]);
  if(!m.exists)return null;
  const data=m.data(),state=s.data()||{};
  if(data.verificationStatus!=='Verified')return null;
  if(!baseline(data)&&!state.monitoringStartedAt){tx.set(stateRef,{monitoringStartedAt:Timestamp.fromMillis(now)},{merge:true});return null;}
  if(!due(data,state,now))return null;
  tx.set(stateRef,{leaseUntil:Timestamp.fromMillis(now+15*60000)},{merge:true});
  return {base:baseline(data),effectiveBase:baseline(data)||state.monitoringStartedAt.toMillis()};
 });
 if(!claim)return;
 try{
  // Re-read after claim: a concurrent update/confirmation cancels this batch.
  const current=await ref.get();if(!current.exists||baseline(current.data())!==claim.base||current.data().verificationStatus!=='Verified')return;
  const devices=await db.collection('_timingReminderDevices').where('masjidId','==',ref.id).get();
  const eligible=devices.docs.filter(d=>owner(current.data(),d.data().uid,d.data().phone)&&now-(d.data().updatedAt?.toMillis()||0)<90*DAY);
  let successes=0;
  for(let offset=0;offset<eligible.length;offset+=500){
   const fresh=await ref.get();if(!fresh.exists||baseline(fresh.data())!==claim.base||fresh.data().verificationStatus!=='Verified')break;
   const batch=eligible.slice(offset,offset+500).filter(d=>owner(fresh.data(),d.data().uid,d.data().phone));
   if(!batch.length)continue;
   const result=await messaging.sendEachForMulticast({tokens:batch.map(d=>d.data().token),notification:{title:'Namaz timings check karein',body:`${String(fresh.data().name||'Aapki masjid').slice(0,100)} ki timings check karein. Sahi hon to app mein confirm karein.`},data:{type:'prayer_timing_reminder',masjidId:ref.id},android:{priority:'normal',ttl:3600000,collapseKey:`timings-${ref.id}`,notification:{channelId:'timing_reminders',tag:`timings-${ref.id}`}}});
   successes+=result.successCount;
   for(let i=0;i<result.responses.length;i++)if(['messaging/registration-token-not-registered','messaging/invalid-registration-token'].includes(result.responses[i].error?.code))await batch[i].ref.delete();
  }
  if(successes){await db.runTransaction(async tx=>{const s=await tx.get(ref);if(s.exists&&baseline(s.data())===claim.base)tx.set(stateRef,{sentBaseline:claim.effectiveBase,lastSentAt:stamp()},{merge:true});});counts.sent++;}
 }finally{await stateRef.set({leaseUntil:Timestamp.fromMillis(0)},{merge:true});}
}

}
module.exports={createProcessor};
