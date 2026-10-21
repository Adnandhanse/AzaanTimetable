'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {classifyFailure}=require('../failure');
test('database access failure is distinguished from Gemini key permissions',()=>{
  assert.equal(classifyFailure({code:7},'quota').supportCode,'AI-DATABASE');
  assert.equal(classifyFailure({status:403},'gemini').supportCode,'AI-KEY');
});
test('provider quota, request and model failures retain distinct codes',()=>{
  for(const [status,expected] of [[429,'AI-LIMIT'],[400,'AI-PROVIDER-REQUEST'],[404,'AI-MODEL']])
    assert.equal(classifyFailure({status},'gemini').supportCode,expected);
});
test('invalid model output cannot be presented as no supporting evidence',()=>{
  assert.equal(classifyFailure(new SyntaxError('private response'),'gemini').supportCode,'AI-OUTPUT');
  assert.equal(classifyFailure(new Error('gemini-blocked-or-incomplete'),'gemini').supportCode,'AI-OUTPUT');
});
test('fixed diagnostic payload never includes arbitrary error contents',()=>{
  const result=classifyFailure(new Error('private secret question database path'),'corpus');
  assert.deepEqual(result,{code:'failed-precondition',supportCode:'AI-CORPUS'});
});
test('provider timeout reports a retryable timeout instead of server setup failure',()=>{
 for(const name of ['TimeoutError','AbortError'])assert.deepEqual(classifyFailure({name},'gemini'),{code:'deadline-exceeded',supportCode:'AI-TIMEOUT'});
});
