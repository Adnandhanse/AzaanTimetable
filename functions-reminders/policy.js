'use strict';
const DAY=86400000;
function millis(v){return v&&typeof v.toMillis==='function'?v.toMillis():v instanceof Date?v.getTime():0;}
function baseline(m){return millis(m.timesUpdatedAt);}
function owner(m,uid,phone){return m.adminUid?m.adminUid===uid:!!phone&&phone===(String(m.adminMobile||'').startsWith('+')?m.adminMobile:`+91${String(m.adminMobile||'').trim()}`);}
function due(m,state,now){
 if(m.verificationStatus!=='Verified')return false;
 const base=baseline(m)||millis(state.monitoringStartedAt);
 if(!base||now-base<10*DAY)return false;
 if(millis(state.leaseUntil)>now)return false;
 return state.sentBaseline!==base||now-millis(state.lastSentAt)>=5*DAY;
}
module.exports={DAY,millis,baseline,owner,due};
