const {test}=require('node:test'),a=require('node:assert/strict'),I=require('../identity');
const t={uid:'B',email:'b@example.com',email_verified:false,auth_time:1000,firebase:{sign_in_provider:'password'}};
const input={countryIso:'AE',mobile:'0501234567',email:'b@example.com'};
test('country validation keeps canonical contacts and legacy India',()=>{
 a.equal(I.contact('9876543210','IN').mobile,'+919876543210');a.equal(I.contact('0501234567','AE').mobile,'+971501234567');
 a.equal(I.contact('07400123456','GB').mobile,'+447400123456');a.equal(I.canonicalLegacy('9876543210'),'+919876543210');
 a.throws(()=>I.contact('+919876543210','AE'));a.throws(()=>I.contact('123','AE'));
});
test('all international recipients need a fresh matching phone token, including transfer',()=>{
 const phone={...t,phone_number:'+971501234567',firebase:{sign_in_provider:'phone'}};
 for(const purpose of ['registration','transfer','takeover']) {
  const r=I.recipientIdentity(phone,input,1100,purpose);a.equal(r.verificationMethod,'phone');a.equal(r.mobileVerified,true);
 }
 for(const changed of [{uid:null},{phone_number:'+971501234568'},{firebase:{sign_in_provider:'anonymous'}},{firebase:{sign_in_provider:'password'}},{auth_time:1}])a.throws(()=>I.recipientIdentity({...phone,...changed},input,1100,'registration'));
 a.throws(()=>I.recipientIdentity(t,input,1100,'registration'));
});
test('international owner has no authority before approval; UID and email alone do not self-approve',()=>{
 const m={adminUid:'B',adminEmail:'b@example.com',adminMobile:'+971501234567',adminVerificationMethod:'email_password',verificationStatus:'Pending Verification'};
 a.equal(I.isOwner(m,t),false);a.equal(I.isOwner({...m,verificationStatus:'Verified'},t),true);a.equal(I.isOwner({...m,verificationStatus:'Rejected'},t),false);
 a.equal(I.isOwner({...m,verificationStatus:'Verified'},{...t,uid:'X'}),false);
});
test('India still requires fresh phone OTP and old records remain supported',()=>{
 a.throws(()=>I.recipientIdentity(t,{countryIso:'IN',mobile:'9876543210',email:''},1100));
 a.equal(I.isOwner({adminMobile:'9876543210'},{uid:'P',phone_number:'+919876543210'}),true);
});

test('supported country examples all require exactly their own verified phone',()=>{
 for(const [countryIso,mobile] of [['IN','+919876543210'],['AE','+971501234567'],['GB','+447400123456'],['US','+12025550123'],['AU','+61412345678'],['SA','+966501234567']]) {
  const token={uid:'P',auth_time:1000,phone_number:mobile,firebase:{sign_in_provider:'phone'}};
  a.equal(I.recipientIdentity(token,{countryIso,mobile,email:''},1100).mobile,mobile);
  a.throws(()=>I.recipientIdentity({...token,phone_number:'+919000000002'},{countryIso,mobile},1100));
 }
});
