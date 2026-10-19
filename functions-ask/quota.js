'use strict';
const {createHash}=require('node:crypto');
async function reserveQuota({db,uid,now=Date.now(),userLimit=20,globalLimit=200,timestamp,limited}) {
  const date=new Date(now).toISOString().slice(0,10), hash=createHash('sha256').update(uid).digest('hex');
  const user=db.collection('_askAiUsage').doc(`${date}-${hash}`), global=db.collection('_askAiUsage').doc(`${date}-global`);
  await db.runTransaction(async tx=>{
    const [u,g]=await Promise.all([tx.get(user),tx.get(global)]);
    const ud=u.data() || {}, gd=g.data() || {};
    if ((ud.count || 0)>=userLimit || (gd.count || 0)>=globalLimit ||
        (ud.lastRequest !== undefined && now-ud.lastRequest<5000)) throw limited();
    const expiresAt=timestamp(now+3*86400000);
    tx.set(user,{count:(ud.count || 0)+1,lastRequest:now,expiresAt});
    tx.set(global,{count:(gd.count || 0)+1,expiresAt});
  });
}
module.exports={reserveQuota};
