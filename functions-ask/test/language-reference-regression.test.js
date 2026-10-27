'use strict';
const {test}=require('node:test');const a=require('node:assert/strict');
const {languageOf}=require('../assistant-contract');
const {retrieveEvidence,corpusIndex}=require('../assistant-retrieval');
const {answerConversation,validateAnswer}=require('../conversational');
const {normalize}=require('../core');
const source={id:'hadith:bukhari:3902',kind:'hadith',book:'bukhari',number:3902,title:'Sahih al-Bukhari',
 en:"Allah's Messenger started receiving the Divine Inspiration at the age of forty.",ur:'',ar:'',grades:[]};
const doc={...source,normalized:` ${normalize(source.en+' '+source.title)} `};
test('Hinglish grammar and spelling variants stay Roman; English grammar remains English',()=>{
 for(const q of ['aap sawas ko nabuat kab mili','aap saws ko nabuwat kb mili','unko ye kab mila','nabuwwat kb mili','namaz ka waqt kab hota','mujhe batao ye kyu hua','ap ko kab mili thi','isko kaise kru','ye krna chahoye ya ni'])a.equal(languageOf(q),'roman',q);
 for(const q of ['When did Prophet Muhammad receive prophethood?','What is the age at which he received revelation?','Can you tell me about the Prophet?','Who was he?','What did he say?'])a.equal(languageOf(q),'en',q);
 a.equal(languageOf('aap ko kab mili, answer in English'),'en');
});
test('prophethood spellings retrieve supporting source text rather than only the final-prophet topic',()=>{
 for(const q of ['aap sawas ko nabuat kab mili','aap saws ko nabuwwat kb mili','When did Prophet Muhammad receive prophethood?']){
  const result=retrieveEvidence(q,[],[doc]);a.ok(result.evidence.some(d=>d.id===source.id),q);
 }
});
test('single-call Roman answer receives evidence and renders a verified canonical reference',async()=>{
 let calls=0;
 const result=await answerConversation({question:'aap sawas ko nabuat kab mili',language:'roman',docs:[doc],call:async req=>{
  calls++;a.equal(req.input.replyLanguage,'roman');a.ok(req.input.evidence.some(d=>d.id===source.id));a.match(req.input.referencePolicy,/Cite/);
  return {status:'answered',language:'roman',statements:[{text:'Nabi Muhammad ﷺ ko chalis saal ki umar mein nabuwwat ata hui.',kind:'answer',source_ids:[source.id]}],
    citations:[{source_id:source.id,quote:source.en}],uncertainty:'none'};
 }});
 a.equal(calls,1);a.equal(result.language,'roman');a.equal(result.references[0].verified,true);a.match(result.answer.reference,/3902/);
});
test('missing evidence is acknowledged; no reference is invented to decorate an answer',()=>{
 const raw={status:'answered',language:'en',statements:[{text:'The event happened in his early life.',kind:'answer',source_ids:[]}],citations:[],uncertainty:'none'};
 const result=validateAnswer(raw,{language:'en',index:corpusIndex([doc]),exact:{requested:false,requiresEvidence:true}});
 a.equal(result.references.length,0);a.ok(result.notices.some(n=>/could not be verified/.test(n)));
});
