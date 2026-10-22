'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');
const localRequire=require('node:module').createRequire(path.join(__dirname,'../index.js'));
function entry(provider){
 const module={exports:{}};
 vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../index.js'),'utf8'),{
  module,exports:module.exports,__dirname:path.join(__dirname,'..'),process:{env:{ASK_AI_PROVIDER:provider}},console,
  require:name=>{
   if(name==='firebase-functions/v2/https')return {onCall:(options,handler)=>({options,handler}),HttpsError:class extends Error{constructor(code,message){super(message);this.code=code;}}};
   if(name==='firebase-functions/params')return {defineSecret:name=>({name,value:()=>{throw Error('direct answer must not access provider key');}})};
   if(name==='firebase-admin/app')return {initializeApp:()=>{}};
   if(name==='firebase-admin/firestore')return {getFirestore:()=>{throw Error('direct answer must not access database');},Timestamp:{fromMillis:n=>n}};
   return localRequire(name);
  }
 });return module.exports.askIslamConnect;
}
test('actual callable bootstraps both providers and answers reported question before quota/database/provider access',async()=>{
 for(const provider of ['gemini','openai']){
  const f=entry(provider);assert.equal(f.options.secrets[0].name,provider==='openai'?'ASK_OPENAI_API_KEY':'ASK_GEMINI_API_KEY');
  for(const question of ['aakhri nabi ka kya naam tha','आखिरी नबी का क्या नाम था']){
   const result=await f.handler({auth:{uid:'test-only'},data:{question,kind:'all'}});
   assert.match(result.answer.text,/Muhammad/);assert.match(result.answer.reference,/33:40/);
  }
 }
});
test('unsupported provider fails closed at startup',()=>assert.throws(()=>entry('other'),/unsupported-ai-provider/));
