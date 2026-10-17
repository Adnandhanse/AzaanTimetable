const {test} = require('node:test');
const assert = require('node:assert/strict');
const {transferPatch} = require('../transfer_validation');
const current = {adminUid:'A', adminMobile:'9000000001', followerCount:85,
  prayerTimes:{fajr:'5:00 AM'}, photoUrls:['photo'], customAzanAudioUrl:'audio', verificationStatus:'Verified'};
const caller = {uid:'A', phone_number:'+919000000001'};
const recipient = {uid:'B', phone_number:'+919000000002', auth_time:1000, firebase:{sign_in_provider:'phone'}};
const input = {expectedAdminMobile:'9000000001',expectedAdminUid:'A', name:'B',mobile:'9000000002',email:''};
test('changes only admin fields, preserving every existing masjid data field', () => {
  const patch=transferPatch(current,caller,recipient,input,1100);
  assert.deepEqual(Object.keys(patch).sort(),['adminEmail','adminMobile','adminName','adminUid']);
  const result={...current,...patch};
  assert.equal(result.adminUid,'B');
  for(const key of ['followerCount','prayerTimes','photoUrls','customAzanAudioUrl','verificationStatus'])
    assert.deepEqual(result[key],current[key]);
});
test('legacy masjid without adminUid requires verified matching current phone',()=>{
  const legacy={...current};delete legacy.adminUid;
  assert.equal(transferPatch(legacy,caller,recipient,{...input,expectedAdminUid:null},1100).adminUid,'B');
  assert.throws(()=>transferPatch(legacy,{...caller,phone_number:'+919999999999'},recipient,input,1100));
});
test('wrong current UID, old admin after transfer, and stale screen cannot transfer',()=>{
  assert.throws(()=>transferPatch(current,{...caller,uid:'X'},recipient,input,1100));
  assert.throws(()=>transferPatch({...current,adminUid:'B',adminMobile:'9000000002'},caller,recipient,input,1100));
  assert.throws(()=>transferPatch(current,caller,recipient,{...input,expectedAdminUid:'old'},1100));
});
test('wrong recipient phone, stale OTP, non-phone account and self-transfer are denied',()=>{
  for(const invalid of [{...recipient,phone_number:'+919000000003'}, {...recipient,auth_time:1},
    {...recipient,firebase:{sign_in_provider:'password'}}, {...recipient,uid:'A'}])
    assert.throws(()=>transferPatch(current,caller,invalid,input,1100));
});
