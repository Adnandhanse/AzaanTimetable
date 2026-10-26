const {test}=require('node:test'),a=require('node:assert/strict'),I=require('../identity');
const t={uid:'B',email:'b@example.com',email_verified:false,auth_time:1000,firebase:{sign_in_provider:'password'}};
const input={countryIso:'AE',mobile:'0501234567',email:'b@example.com'};
test('country validation keeps canonical contacts and legacy India',()=>{
 a.equal(I.contact('9876543210','IN').mobile,'+919876543210');a.equal(I.contact('0501234567','AE').mobile,'+971501234567');
 a.equal(I.contact('07400123456','GB').mobile,'+447400123456');a.equal(I.canonicalLegacy('9876543210'),'+919876543210');
 a.throws(()=>I.contact('+919876543210','AE'));a.throws(()=>I.contact('123','AE'));
});
test('international account needs password authentication but no email verification or OTP',()=>{
 const r=I.recipientIdentity(t,input,1100,'registration');a.equal(r.verificationMethod,'email_password');a.equal(r.mobileVerified,false);
 for(const changed of [{uid:null},{email:'other@example.com'},{firebase:{sign_in_provider:'anonymous'}},{auth_time:1}])a.throws(()=>I.recipientIdentity({...t,...changed},input,1100,'registration'));
 a.throws(()=>I.recipientIdentity(t,input,1100,'transfer'));
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
