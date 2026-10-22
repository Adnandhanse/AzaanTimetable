'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {checkProvider}=require('../check-provider');
function error(status,name='Error'){const e=new Error('private provider details must not be logged');e.status=status;e.name=name;return e;}
const quiet=()=>{};
test('503 and timeout retry with bounded backoff, then validate a successful response',async()=>{
 let calls=0;const delays=[],logs=[];
 await checkProvider({key:'secret-test-only',random:()=>0,
  sleep:async ms=>delays.push(ms),log:(event,fields)=>logs.push([event,fields]),check:async r=>{
   assert.equal(r.model,'gemini-3.5-flash-lite');
   if(++calls===1)throw error(503);
   if(calls===2)throw error(null,'TimeoutError');
  }});
 assert.equal(calls,3);assert.deepEqual(delays,[2000,5000]);
 assert.equal(logs.at(-1)[0],'provider-check-passed');
 assert.ok(!JSON.stringify(logs).includes('secret-test-only'));assert.ok(!JSON.stringify(logs).includes('private provider'));
});
test('persistent timeout fails after three attempts and never reports success',async()=>{
 let calls=0;const logs=[];
 await assert.rejects(checkProvider({key:'test',check:async()=>{calls++;throw error(null,'TimeoutError');},
  sleep:async()=>{},random:()=>0,log:e=>logs.push(e)}),e=>e.name==='TimeoutError');
 assert.equal(calls,3);assert.ok(!logs.includes('provider-check-passed'));
});
test('auth, model, request, quota and malformed-output errors are not retried',async()=>{
 for(const failure of [error(400),error(401),error(403),error(404),error(429),new SyntaxError('bad-json'),Error('invalid-smoke-output')]){
  let calls=0,sleeps=0;
  await assert.rejects(checkProvider({key:'test',check:async()=>{calls++;throw failure;},sleep:async()=>{sleeps++;},log:quiet}),e=>e===failure);
  assert.equal(calls,1);assert.equal(sleeps,0);
 }
});
test('first success makes one request; jitter remains bounded; OpenAI never gains automatic paid retries',async()=>{
 let calls=0;
 await checkProvider({key:'test',check:async()=>{calls++;},log:quiet});assert.equal(calls,1);
 calls=0;const delays=[];
 await checkProvider({key:'test',random:()=>1,sleep:async ms=>delays.push(ms),log:quiet,check:async()=>{if(++calls<3)throw error(502);}});
 assert.deepEqual(delays,[2500,5500]);
 calls=0;
 await assert.rejects(checkProvider({provider:'openai',key:'test',log:quiet,sleep:async()=>assert.fail('must not retry'),check:async()=>{calls++;throw error(503);}}));
 assert.equal(calls,1);
});
test('missing keys and unknown providers never make an outbound check',async()=>{
 for(const options of [{},{provider:'other',key:'test'}])
  await assert.rejects(checkProvider({...options,check:async()=>assert.fail('no request')}));
});
