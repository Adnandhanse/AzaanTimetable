'use strict';
const fs=require('node:fs');
function check(payload){
 const rows=Array.isArray(payload)?payload:payload.result;
 if(!Array.isArray(rows))throw Error('Cannot verify deployment: unrecognised function inventory.');
 const found=rows.find(f=>{
  const name=String(f.id||f.name||'').split('/').at(-1);
  return name==='registerVerifiedMasjid'&&f.region==='us-central1';
 });
 if(!found)throw Error('registerVerifiedMasjid is not deployed in us-central1. Do not release the registration APK yet.');
 return true;
}
if(require.main===module){try{check(JSON.parse(fs.readFileSync(process.argv[2],'utf8')));console.log('Registration endpoint found in us-central1. SMS-to-registration still requires a device test.');}catch(e){console.error(e.message);process.exitCode=1;}}
module.exports={check};
