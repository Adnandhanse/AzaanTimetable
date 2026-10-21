'use strict';
// One constant smoke request; never log API keys, provider bodies or user data.
const {geminiJson,DEFAULT_MODEL}=require('./gemini-client');
async function checkGemini({key,model=DEFAULT_MODEL,call=geminiJson}) {
 if(!key)throw Error('missing-key');
 const result=await call({key,model,instructions:'Return the JSON object {"ok":true}.',
  input:{test:'deployment compatibility check'},maxTokens:512,
  schema:{type:'object',properties:{ok:{type:'boolean'}},required:['ok'],additionalProperties:false}});
 if(result?.ok!==true)throw Error('invalid-smoke-output');
}
if(require.main===module)checkGemini({key:process.env.AI_KEY,model:process.env.ASK_GEMINI_MODEL||DEFAULT_MODEL})
 .then(()=>console.log('Gemini structured-output compatibility check passed.'))
 .catch(e=>{console.error('Gemini compatibility check failed.',{status:e.status||null,
  action:e.status===404?'Model unavailable for this API key/project.': 'Check API key, model quota and API compatibility.'});process.exitCode=1;});
module.exports={checkGemini};
