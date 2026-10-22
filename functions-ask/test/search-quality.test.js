'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {excerpt,completeQuote,runAsk,prepareCorpus}=require('../core');
test('a long reference excerpt focuses on a distinguishing action, not just generic prayer words',()=>{
 const text='Prayer is important. '.repeat(300)+'He did not move his forearm during this action. '+'A different event. '.repeat(200);
 const result=excerpt(text,['forearm','prayer'],1400);
 assert.ok(result.includes('He did not move his forearm'));assert.ok(result.length<=1400);
});
test('short answers cannot drop a sentence beginning, negation or end condition',()=>{
 assert.equal(completeQuote('On a journey: He permitted this action.','He permitted this action.'),false);
 assert.equal(completeQuote('He did not permit this action.','permit this action.'),false);
 assert.equal(completeQuote('He permitted this only on a journey.','He permitted this'),false);
 assert.equal(completeQuote('Narrated X:He did not permit this action.','He did not permit this action.'),true);
});
test('an incomplete quote is removed but its valid source card remains',async()=>{
 const docs=prepareCorpus([{id:'hadith:bukhari:1',kind:'hadith',book:'bukhari',number:1,title:'Bukhari',en:'He did not permit this action.',grades:[]}]);
 let n=0;const r=await runAsk({question:'action',docs,call:async()=>++n===1?
 {intent:'search',understood:'action',clarification:'',searches:[{must:[['action']],boost:[]}]}:
 {status:'selected',source_ids:['hadith:bukhari:1'],answer_source_id:'hadith:bukhari:1',answer_quote:'permit this action.'}});
 assert.equal(r.answer,undefined);assert.equal(r.hits.length,1);
});
