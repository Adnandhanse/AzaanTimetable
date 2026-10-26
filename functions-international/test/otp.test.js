const {test}=require('node:test');const a=require('node:assert/strict');const {digest,codeMatches,checkChallenge}=require('../otp-policy');
const key='test-key-not-production',id='challenge',code='012345',now=1000;
const data={uid:'requester',status:'ready',attempts:0,expiresAt:{toMillis:()=>2000},codeHash:digest(key,id,code)};
test('hashed six-digit OTP is bound to challenge and secret; leading zero survives',()=>{a.equal(codeMatches(key,id,code,data.codeHash),true);a.equal(codeMatches(key,'other',code,data.codeHash),false);a.equal(codeMatches('other',id,code,data.codeHash),false);a.equal(codeMatches(key,id,'12345',data.codeHash),false);a.equal(JSON.stringify(data).includes(code),false);});
test('expired, consumed, unsent, over-attempt, wrong-session and wrong-code challenges fail',()=>{
 const args={uid:'requester',now,code,key,id};a.equal(checkChallenge(data,args),'ok');
 for(const change of [{uid:'other'},{status:'consumed'},{status:'sending'},{status:'failed'},{attempts:5},{expiresAt:{toMillis:()=>1000}}])a.equal(checkChallenge({...data,...change},args),'expired');
 a.equal(checkChallenge(data,{...args,code:'999999'}),'incorrect');
});
