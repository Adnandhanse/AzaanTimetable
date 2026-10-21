'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {checkGemini}=require('../check-gemini');
test('deployment check verifies actual structured output with the production default',async()=>{
 await checkGemini({key:'test',call:async request=>{
  assert.equal(request.model,'gemini-3.5-flash-lite');
  assert.equal(request.input.test,'deployment compatibility check');
  assert.equal(request.schema.required[0],'ok');return {ok:true};
 }});
 await assert.rejects(checkGemini({key:'test',call:async()=>({ok:false})}),/invalid-smoke-output/);
 await assert.rejects(checkGemini({key:'test',call:async()=>{const e=Error();e.status=404;throw e;}}),e=>e.status===404);
});
