'use strict';
const {isOwner,recipientIdentity,adminPatch}=require('./admin_identity');
function transferPatch(current,caller,recipient,input,nowSeconds){
 if(!isOwner(current,caller))throw Error('Only the current verified administrator can transfer this masjid.');
 if(current.adminMobile!==input.expectedAdminMobile||(current.adminUid||null)!==(input.expectedAdminUid||null))throw Error('Administration changed. Reopen the masjid and try again.');
 if((current.adminCountryIso||'IN')!=='IN'||(input.countryIso||'IN')!=='IN')throw Error('International transfers require Platform Admin approval.');
 const r=recipientIdentity(recipient,input,nowSeconds,'transfer',input.masjidId||'');
 if(caller.uid===recipient.uid)throw Error('Choose a different administrator.');
 return adminPatch(recipient.uid,input.name,r);
}
module.exports={transferPatch};
