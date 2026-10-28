'use strict';
const {parsePhoneNumberFromString,getCountries}=require('libphonenumber-js/max');
const {createHash}=require('node:crypto');
const COUNTRIES=new Set(getCountries());
function email(v){if(typeof v!=='string'||v.length>254||!/^\S+@[^\s@]+\.[^\s@]+$/.test(v.trim()))throw Error('Enter a valid email address.');return v.trim().toLowerCase();}
function contact(raw,country='IN'){
 if(!COUNTRIES.has(country)||typeof raw!=='string'||raw.length>50||!/^\+?[\d\s().-]+$/.test(raw))throw Error('Select a valid country and mobile number.');
 const p=parsePhoneNumberFromString(raw,country);
 if(!p?.isValid()||p.country!==country)throw Error('Enter a valid number for the selected country.');
 return {mobile:p.number,countryIso:country,dialCode:'+'+p.countryCallingCode};
}
function canonicalLegacy(v){return typeof v==='string'?(v.startsWith('+')?v:'+91'+v.trim()):'';}
function isOwner(m,t){
 if(!t?.uid)return false;
 if(m.adminUid&&m.adminUid!==t.uid)return false;
 if(m.adminVerificationMethod==='email_password')return !!m.adminUid&&m.verificationStatus==='Verified'&&t.firebase?.sign_in_provider==='password'&&t.email?.toLowerCase()===m.adminEmail?.toLowerCase();
 if(m.adminVerificationMethod==='email')return !!m.adminUid&&t.email_verified===true&&(t.adminEmailOtp===true||t.firebase?.sign_in_provider==='password')&&t.email?.toLowerCase()===m.adminEmail?.toLowerCase();
 return !!t.phone_number&&t.phone_number===canonicalLegacy(m.adminMobile);
}
function recipientIdentity(t,input,now,purpose='transfer',masjidId=''){
 const c=contact(input.mobile,input.countryIso||'IN');
 if(!t?.uid||!Number.isFinite(t.auth_time)||now-t.auth_time>600||t.auth_time>now+60)throw Error('Verify the new administrator with a fresh OTP.');
 if(t.firebase?.sign_in_provider!=='phone'||t.phone_number!==c.mobile)throw Error('Verify the new administrator phone with a fresh OTP.');
 return {...c,email:input.email?email(input.email):'',verificationMethod:'phone',mobileVerified:true};
}
function adminPatch(uid,name,r){if(typeof name!=='string'||!name.trim()||name.length>120)throw Error('Enter a valid administrator name.');return {adminUid:uid,adminName:name.trim(),adminMobile:r.mobile,adminEmail:r.email,adminCountryIso:r.countryIso,adminDialCode:r.dialCode,adminVerificationMethod:r.verificationMethod,adminMobileVerified:r.mobileVerified,adminEmailVerified:false};}
const emailUid=e=>'email-admin-'+createHash('sha256').update(e).digest('hex').slice(0,48);
module.exports={isCountry:c=>COUNTRIES.has(c),email,contact,canonicalLegacy,isOwner,recipientIdentity,adminPatch,emailUid};
