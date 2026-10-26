'use strict';
const admin=require('firebase-admin');
const {onCall,HttpsError}=require('firebase-functions/v2/https');
const {createHash}=require('node:crypto');
const identity=require('./identity');
admin.initializeApp();const db=admin.firestore(),auth=admin.auth(),T=admin.firestore.Timestamp,F=admin.firestore.FieldValue;
const opts={region:'us-central1',invoker:'public',maxInstances:3,timeoutSeconds:60};
const safe=(fn)=>async req=>{try{return await fn(req);}catch(e){if(e instanceof HttpsError)throw e;console.error('international-admin-failed',{code:e.code||e.name||'unknown'});throw new HttpsError('internal','Unable to complete verification. Please try again.');}};
function requireAuth(req){if(!req.auth)throw new HttpsError('unauthenticated','Sign in to continue.');}
function field(v,max=200){if(typeof v!=='string'||!v.trim()||v.length>max)throw new HttpsError('invalid-argument','Please check the required details.');return v.trim();}
function parse(fn){try{return fn();}catch(e){throw new HttpsError('invalid-argument',e.message);}}
const hash=s=>createHash('sha256').update(s).digest('hex');
function id(v){if(typeof v!=='string'||!v||v.includes('/')||v.length>150)throw new HttpsError('invalid-argument','Invalid masjid.');return v;}
async function recipient(req,purpose,masjidId=''){
 requireAuth(req);return parse(()=>identity.recipientIdentity({...req.auth.token,uid:req.auth.uid},req.data,Math.floor(Date.now()/1000),purpose,masjidId));
}
// Retired endpoints fail closed for older APKs. No provider key or domain needed.
exports.startAdminEmailOtp=onCall(opts,async()=>{throw new HttpsError('failed-precondition','Update the app. International admins now use email/password and Platform Admin approval.');});
exports.verifyAdminEmailOtp=onCall(opts,async()=>{throw new HttpsError('failed-precondition','Email OTP is no longer used. Update the app.');});
exports.registerVerifiedMasjid=onCall(opts,safe(async req=>{
 const r=await recipient(req,'registration');const d=req.data,reg=field(d.registrationNo,100);
 const patch=parse(()=>identity.adminPatch(req.auth.uid,d.adminName,r));
 const lat=d.latitude,lon=d.longitude;
 if(!Number.isFinite(lat)||!Number.isFinite(lon)||lat < -90||lat>90||lon < -180||lon>180)throw new HttpsError('invalid-argument','Select a valid map location.');
 const ref=db.collection('masjids').doc(),key=db.doc('_masjidRegistrationKeys/'+hash(reg));
 const result=await db.runTransaction(async tx=>{
  const lock=await tx.get(key);
  const existing=await tx.get(db.collection('masjids').where('registrationNo','==',reg).limit(1));
  if(lock.exists){if(lock.data().uid===req.auth.uid&&!existing.empty&&existing.docs[0].id===lock.data().masjidId&&existing.docs[0].data().adminUid===req.auth.uid)return {id:lock.data().masjidId,mobile:existing.docs[0].data().adminMobile};throw new HttpsError('already-exists','Registration already exists. Request a transfer.');}
  if(!existing.empty)throw new HttpsError('already-exists','Registration already exists. Request a transfer.');
  tx.create(ref,{...patch,name:field(d.name,160),city:field(d.city,120),address:field(d.address,1000),registrationNo:reg,latitude:lat,longitude:lon,verificationStatus:'Pending Verification',prayerTimes:Object.fromEntries(['fajr','dhuhr','asr','maghrib','isha','juma'].map(k=>[k,'--:--'])),about:typeof d.about==='string'?d.about.slice(0,2000):null,capacity:Number.isInteger(d.capacity)&&d.capacity>0?d.capacity:null,photoUrls:[],timesUpdatedAt:F.serverTimestamp(),timesConfirmedAt:F.serverTimestamp()});
  tx.create(key,{masjidId:ref.id,uid:req.auth.uid});return {id:ref.id,mobile:patch.adminMobile};
 });return result;
}));
exports.requestVerifiedAdminTransfer=onCall(opts,safe(async req=>{
 const masjidId=id(req.data?.masjidId),r=await recipient(req,'takeover',masjidId),patch=parse(()=>identity.adminPatch(req.auth.uid,req.data.name,r));
 const ref=db.doc('ownershipTransferRequests/'+masjidId+'_'+req.auth.uid),masjidRef=db.doc('masjids/'+masjidId);
 await db.runTransaction(async tx=>{
  const [m,p]=await Promise.all([tx.get(masjidRef),tx.get(ref)]);if(!m.exists)throw new HttpsError('not-found','Masjid not found.');const d=m.data();
  if(d.adminUid===req.auth.uid)throw new HttpsError('already-exists','You already manage this masjid.');
  if(p.data()?.status==='Pending')return;
  tx.set(ref,{masjidId,masjidName:d.name,registrationNo:d.registrationNo,previousAdminMobile:d.adminMobile,previousAdminUid:d.adminUid||null,requesterUid:req.auth.uid,newAdminName:patch.adminName,newAdminMobile:patch.adminMobile,newAdminEmail:patch.adminEmail,newAdminCountryIso:patch.adminCountryIso,newAdminDialCode:patch.adminDialCode,newAdminVerificationMethod:patch.adminVerificationMethod,newAdminMobileVerified:patch.adminMobileVerified,status:'Pending',requestedAt:F.serverTimestamp()});
 });return {ok:true};
}));
exports.reviewVerifiedAdminTransfer=onCall(opts,safe(async req=>{
 requireAuth(req);if((await db.doc('platformAdmins/'+req.auth.uid).get()).data()?.enabled!==true)throw new HttpsError('permission-denied','Platform admin permission required.');
 const ref=db.doc('ownershipTransferRequests/'+id(req.data?.requestId)),approve=req.data?.approve;if(typeof approve!=='boolean')throw new HttpsError('invalid-argument','Choose approve or reject.');
 await db.runTransaction(async tx=>{
  const s=await tx.get(ref),d=s.data();if(!d||d.status!=='Pending')throw new HttpsError('failed-precondition','This request was already reviewed.');
  const mref=db.doc('masjids/'+d.masjidId),m=await tx.get(mref);
  if(!m.exists)throw new HttpsError('not-found','Masjid not found.');
  if(approve){if(m.data().adminMobile!==d.previousAdminMobile||(m.data().adminUid||null)!==(d.previousAdminUid||null))throw new HttpsError('failed-precondition','Ownership changed. Request a new transfer.');
   const c=parse(()=>identity.contact(d.newAdminMobile,d.newAdminCountryIso||'IN'));
   tx.update(mref,{adminUid:d.requesterUid,adminName:d.newAdminName,adminMobile:c.mobile,adminEmail:d.newAdminEmail,adminCountryIso:c.countryIso,adminDialCode:c.dialCode,adminVerificationMethod:d.newAdminVerificationMethod||'phone',adminMobileVerified:(d.newAdminVerificationMethod||'phone')==='phone',adminEmailVerified:false,ownershipTransferredAt:F.serverTimestamp(),ownershipTransferRequestId:s.id});}
  tx.update(ref,{status:approve?'Approved':'Rejected',reviewedBy:req.auth.uid,reviewedAt:F.serverTimestamp()});
 });return {ok:true};
}));
// Current-admin initiated request. Recipient proof is checked independently;
// ownership changes ONLY when a platform admin approves the saved request.
exports.submitInternationalAdminTransfer=onCall(opts,safe(async req=>{
 requireAuth(req);const d=req.data||{},masjidId=id(d.masjidId);
 let caller,target;
 const bearer=(req.rawRequest.headers?.authorization||'').replace(/^Bearer /i,'');
 try{caller=await auth.verifyIdToken(bearer,true);target=await auth.verifyIdToken(d.recipientIdToken,true);}catch(_){throw new HttpsError('unauthenticated','Sign in again and confirm the new admin account.');}
 const r=parse(()=>identity.recipientIdentity(target,d,Math.floor(Date.now()/1000),'takeover',masjidId));
 if(target.uid===caller.uid)throw new HttpsError('invalid-argument','Choose a different administrator.');
 const patch=parse(()=>identity.adminPatch(target.uid,d.name,r));
 const ref=db.doc('ownershipTransferRequests/'+masjidId+'_'+target.uid),mref=db.doc('masjids/'+masjidId);
 await db.runTransaction(async tx=>{
  const [m,p]=await Promise.all([tx.get(mref),tx.get(ref)]);const old=m.data();
  if(!old||!identity.isOwner(old,caller))throw new HttpsError('permission-denied','Current admin required.');
  if(old.adminMobile!==d.expectedAdminMobile||(old.adminUid||null)!==(d.expectedAdminUid||null))throw new HttpsError('failed-precondition','Ownership changed. Reopen this page.');
  if((old.adminCountryIso||'IN')==='IN'&&r.countryIso==='IN')throw new HttpsError('invalid-argument','Use the Indian SMS transfer flow.');
  if(p.data()?.status==='Pending')return;
  tx.set(ref,{masjidId,masjidName:old.name,registrationNo:old.registrationNo,previousAdminMobile:old.adminMobile,previousAdminUid:old.adminUid||null,requesterUid:target.uid,newAdminName:patch.adminName,newAdminMobile:patch.adminMobile,newAdminEmail:patch.adminEmail,newAdminCountryIso:patch.adminCountryIso,newAdminDialCode:patch.adminDialCode,newAdminVerificationMethod:patch.adminVerificationMethod,newAdminMobileVerified:patch.adminMobileVerified,initiatedByAdminUid:caller.uid,method:'current_admin_pending_platform_approval',status:'Pending',requestedAt:F.serverTimestamp()});
 });return {pending:true};
}));
