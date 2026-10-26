'use strict';
const {createHmac,timingSafeEqual}=require('node:crypto');
const digest=(key,id,code)=>createHmac('sha256',key).update(id+':'+code).digest('hex');
function codeMatches(key,id,code,stored){if(!/^\d{6}$/.test(code)||typeof stored!=='string'||stored.length!==64)return false;return timingSafeEqual(Buffer.from(digest(key,id,code),'hex'),Buffer.from(stored,'hex'));}
function checkChallenge(d,{uid,now,code,key,id}){
 if(!d||d.uid!==uid||d.status!=='ready'||d.expiresAt.toMillis()<=now||d.attempts>=5)return 'expired';
 return codeMatches(key,id,code,d.codeHash)?'ok':'incorrect';
}
module.exports={digest,codeMatches,checkChallenge};
