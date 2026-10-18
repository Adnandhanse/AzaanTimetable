const {test} = require('node:test');
const assert = require('node:assert/strict');
const {verifyTransferToken} = require('../token_verification');
const makeError = (code, message, details) => Object.assign(new Error(message), {code, details});
function attempt(code, actor='recipient') {
  return verifyTransferToken({token:'test-token', actor, makeError,
    verifyIdToken: async () => {throw Object.assign(new Error('private upstream detail'), {code});}});
}
test('always requests revoked/disabled-user verification', async()=>{
  const result=await verifyTransferToken({token:'valid',actor:'recipient',makeError,
    verifyIdToken:async(token,revoked)=>{assert.equal(token,'valid');assert.equal(revoked,true);return {uid:'B'};}});
  assert.equal(result.uid,'B');
});
test('missing and revoked recipient sessions request phone verification',async()=>{
  await assert.rejects(verifyTransferToken({actor:'recipient',token:'',makeError}),
    e=>e.code==='unauthenticated'&&e.details.reason==='recipient-session-invalid');
  await assert.rejects(attempt('auth/id-token-revoked'),
    e=>e.code==='unauthenticated'&&e.details.reason==='recipient-session-invalid');
});
test('caller expiry is not presented as new-admin OTP failure',async()=>{
  await assert.rejects(attempt('auth/id-token-expired','caller'),
    e=>e.details.reason==='caller-session-invalid');
});
test('runtime IAM failure is setup error, never OTP expiry',async()=>{
  await assert.rejects(attempt('auth/insufficient-permission'),
    e=>e.code==='failed-precondition'&&e.details.reason==='transfer-auth-setup'&&!/expired/.test(e.message));
});
test('unknown/network error permits retry and does not leak upstream details',async()=>{
  await assert.rejects(attempt('auth/internal-error'),
    e=>e.code==='unavailable'&&e.details.reason==='transfer-auth-unavailable'&&!e.message.includes('private'));
});
