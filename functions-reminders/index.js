'use strict';
const admin=require('firebase-admin');
const {onCall,HttpsError}=require('firebase-functions/v2/https');
const {onSchedule}=require('firebase-functions/v2/scheduler');
const {createHash}=require('node:crypto');
const {baseline,owner,due,DAY}=require('./policy');
const {isOwner}=require('./admin_identity');
admin.initializeApp();
const db=admin.firestore(),Timestamp=admin.firestore.Timestamp;
const options={invoker:'public',region:'us-central1',maxInstances:2,timeoutSeconds:60};
const processMasjid=require('./processor').createProcessor({db,messaging:admin.messaging(),Timestamp,stamp:()=>admin.firestore.FieldValue.serverTimestamp()});
const hash=t=>createHash('sha256').update(t).digest('hex');
const stamp=()=>admin.firestore.FieldValue.serverTimestamp();
function input(req){
 if(!req.auth)throw new HttpsError('unauthenticated','Sign in again.');
 const id=req.data?.masjidId;
 if(typeof id!=='string'||!id||id.length>150||id.includes('/'))throw new HttpsError('invalid-argument','Invalid masjid.');
 return id;
}
async function owned(req,id){
 const ref=db.collection('masjids').doc(id),snap=await ref.get();
 if(!snap.exists||!isOwner(snap.data(),{...req.auth.token,uid:req.auth.uid}))throw new HttpsError('permission-denied','Current masjid admin required.');
 return ref;
}
exports.confirmPrayerTimings=onCall(options,async req=>{
 const id=input(req); const ref=db.collection('masjids').doc(id);
 await db.runTransaction(async tx=>{
  const s=await tx.get(ref);
  if(!s.exists||!isOwner(s.data(),{...req.auth.token,uid:req.auth.uid}))throw new HttpsError('permission-denied','Current masjid admin required.');
  tx.update(ref,{timesUpdatedAt:stamp(),timesConfirmedAt:stamp()});
 });
 return {ok:true};
});
exports.registerTimingReminderDevice=onCall(options,async req=>{
 const id=input(req);await owned(req,id);
 const token=req.data?.token;
 if(typeof token!=='string'||token.length<20||token.length>4096)throw new HttpsError('invalid-argument','Invalid device.');
 await db.collection('_timingReminderDevices').doc(hash(token)+'_'+hash(id)).set({token,masjidId:id,uid:req.auth.uid,phone:req.auth.token.phone_number||null,language:req.data?.language==='ur'?'ur':'en',updatedAt:stamp()});
 return {ok:true};
});
exports.removeTimingReminderDevice=onCall(options,async req=>{
 if(!req.auth)throw new HttpsError('unauthenticated','Sign in again.');
 const token=req.data?.token;
 if(typeof token!=='string'||token.length>4096)throw new HttpsError('invalid-argument','Invalid device.');
 const devices=await db.collection('_timingReminderDevices').where('token','==',token).get();
 for(const d of devices.docs)if(d.data().uid===req.auth.uid)await d.ref.delete();
 return {ok:true};
});
// Manual reminder, initiated only by an enabled Platform Admin.
exports.sendManualPrayerTimingReminder=onCall(options,async req=>{
 if(!req.auth)throw new HttpsError('unauthenticated','Please sign in as Platform Admin.');
 const adminSnap=await db.collection('platformAdmins').doc(req.auth.uid).get();
 if(!adminSnap.exists||adminSnap.data()?.enabled!==true)throw new HttpsError('permission-denied','Platform Admin permission required.');
 const id=input(req);
 const masjidRef=db.collection('masjids').doc(id),masjidSnap=await masjidRef.get();
 if(!masjidSnap.exists)throw new HttpsError('not-found','Masjid not found.');
 const masjid=masjidSnap.data();
 if(masjid.verificationStatus!=='Verified')throw new HttpsError('failed-precondition','Reminders can only be sent to verified masjids.');
 const devices=await db.collection('_timingReminderDevices').where('masjidId','==',id).get();
 const now=Date.now();
 const eligible=devices.docs.filter(d=>{
  const data=d.data();
  return owner(masjid,data.uid,data.phone)&&
   typeof data.token==='string'&&data.token.length>=20&&
   now-(data.updatedAt?.toMillis()||0)<90*DAY;
 });
 const unique=[...new Map(eligible.map(d=>[d.data().token,d])).values()];
 if(!unique.length)return {ok:true,sent:0,failed:0};
 const name=String(masjid.name||'Masjid').slice(0,100);
 const title=`Prayer Timings Update – ${name}`;
 const body=`You haven't updated the prayer timings for ${name} for many days. Please update the timings.\n\nAapne kaafi dino se ${name} ke namaz ke timings update nahi kiye hain. Please timings update kar dein.`;
 let sent=0,failed=0;
 for(let offset=0;offset<unique.length;offset+=500){
  const batch=unique.slice(offset,offset+500);
  const result=await admin.messaging().sendEachForMulticast({
   tokens:batch.map(d=>d.data().token),
   notification:{title,body},
   data:{type:'prayer_timing_reminder',masjidId:id},
   android:{priority:'normal',ttl:3600000,collapseKey:`timings-${id}`,notification:{channelId:'timing_reminders',tag:`timings-${id}`}}
  });
  sent+=result.successCount;failed+=result.failureCount;
  for(let i=0;i<result.responses.length;i++){
   if(['messaging/registration-token-not-registered','messaging/invalid-registration-token'].includes(result.responses[i].error?.code))await batch[i].ref.delete();
  }
 }
 console.info('manual-timing-reminder',{masjidId:id,sent,failed});
 return {ok:true,sent,failed};
});

// Backend clock; bounded pages; no composite Firestore index needed.
exports.sendPrayerTimingReminders=onSchedule({region:'us-central1',schedule:'0 10 * * *',timeZone:'Asia/Kolkata',timeoutSeconds:540,memory:'256MiB',maxInstances:1,retryCount:0},async()=>{
 let cursor=null,counts={sent:0,failed:0};
 for(;;){
  let q=db.collection('masjids').orderBy(admin.firestore.FieldPath.documentId()).limit(100);
  if(cursor)q=q.startAfter(cursor);
  const page=await q.get();if(page.empty)break;
  for(const m of page.docs){
   try{await processMasjid(m.ref,counts);}catch(e){counts.failed++;console.error('timing-reminder-failed',{code:e.code||'unknown'});}
  }
  cursor=page.docs[page.docs.length-1];if(page.size<100)break;
 }
 console.info('timing-reminder-summary',counts);
});
