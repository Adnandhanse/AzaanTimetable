'use strict';
const {createHash}=require('node:crypto');
async function reserveQuota({db,uid,now=Date.now(),userLimit=5,globalLimit=250,timestamp,limited}) {
  const date=new Intl.DateTimeFormat('en-CA',{timeZone:'America/Los_Angeles',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date(now)), hash=createHash('sha256').update(uid).digest('hex');
  const user=db.collection('_askAiUsage').doc(`${date}-success-v2-${hash}`), global=db.collection('_askAiUsage').doc(`${date}-global`);
  await db.runTransaction(async tx=>{
    const [u,g]=await Promise.all([tx.get(user),tx.get(global)]);
    const ud=u.data() || {}, gd=g.data() || {};
    if(ud.lastRequest !== undefined && now-ud.lastRequest<5000)throw limited('cooldown');
    if((ud.count||0)>=userLimit)throw limited('user');
    if((gd.count||0)>=globalLimit)throw limited('project');
    const expiresAt=timestamp(now+3*86400000);
    tx.set(user,{count:(ud.count || 0)+1,lastRequest:now,expiresAt});
    tx.set(global,{count:(gd.count || 0)+1,expiresAt});
  });
  let refunded=false;
  return {refund:async()=>{
    if(refunded)return;
    await db.runTransaction(async tx=>{
      const snapshot=await tx.get(user),data=snapshot.data()||{};
      tx.set(user,{...data,count:Math.max(0,(data.count||0)-1)});
    });
    refunded=true;
  }};
}
module.exports={reserveQuota};
