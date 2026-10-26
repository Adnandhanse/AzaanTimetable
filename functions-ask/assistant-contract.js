'use strict';
const {romanQuestion}=require('./question-language');
const LANGUAGES=['roman','hi','ur','en'];
function languageOf(text,history=[],requested='auto'){
 if(LANGUAGES.includes(requested))return requested;
 const q=String(text).toLowerCase();
 if(/(?:in english|english (?:mein|me)|angrezi|अंग्रेज़ी|अंग्रेजी|انگریزی)/u.test(q))return 'en';
 if(/(?:roman (?:urdu|hindi)|رومن|रोमन)/u.test(q))return 'roman';
 if(/(?:in urdu|urdu (?:mein|me)|اردو میں|उर्दू में)/u.test(q))return 'ur';
 if(/(?:in hindi|hindi (?:mein|me)|हिंदी में|ہندی میں)/u.test(q))return 'hi';
 if(/[\u0900-\u097f]/.test(text))return 'hi';
 if(/[\u0600-\u06ff]/.test(text))return 'ur';
 const romanWords=q.match(/\b(kya|kitn\w*|hai|hain|hota|ka|ki|ke|mein|me|mujhe|bata\w*|bta\w*|isme\w*|usme\w*|kaise|kyun)\b/g)||[];
 const englishWords=q.match(/\b(what|how|who|which|why|where|when|the|is|are|does|can|in|tell|please|explain|you|your|many)\b/g)||[];
 if(englishWords.length>=2&&romanWords.length<2)return 'en';
 if(romanWords.length)return 'roman';
 if(englishWords.length)return 'en';
 const previous=history.filter(x=>x.role==='user').at(-1);
 return previous?languageOf(previous.content,[], 'auto'):'en';
}
function requestData(data){
 if(!data||typeof data.question!=='string'||data.question.trim().length<3||data.question.length>500)
  throw Object.assign(Error('invalid-question'),{code:'invalid-argument'});
 const history=data.history??[];
 if(!Array.isArray(history)||history.length>8)throw Object.assign(Error('invalid-history'),{code:'invalid-argument'});
 let total=0;
 const clean=history.map(m=>{
  if(!m||!['user','assistant'].includes(m.role)||typeof m.content!=='string'||m.content.length>2000)
   throw Object.assign(Error('invalid-history'),{code:'invalid-argument'});
  total+=m.content.length;return {role:m.role,content:m.content.trim()};
 });
 if(total>10000)throw Object.assign(Error('history-too-long'),{code:'invalid-argument'});
 const requested=data.replyLanguage??'auto';
 if(!['auto',...LANGUAGES].includes(requested))throw Object.assign(Error('invalid-language'),{code:'invalid-argument'});
 return {question:data.question.trim(),history:clean,language:languageOf(data.question,clean,requested)};
}
const MESSAGES={
 reference:{roman:'Is exact reference ko available source data se verify nahi kar saka. Ise confirmed hawala nahi keh raha.',en:'I could not verify that exact reference in the available source data.',hi:'उपलब्ध स्रोतों से यह सटीक हवाला सत्यापित नहीं हो सका। इसे पक्का संदर्भ नहीं कहूँगा।',ur:'دستیاب مصادر سے اس خاص حوالے کی تصدیق نہیں ہو سکی۔ اسے مصدقہ حوالہ نہیں کہوں گا۔'},
 partial:{roman:'Kuch references verify nahi hue; sirf tasdeeq-shuda hawale neeche hain.',en:'Some references could not be verified; only checked references are listed below.',hi:'कुछ संदर्भ सत्यापित नहीं हो सके; नीचे केवल जाँचे गए संदर्भ हैं।',ur:'بعض حوالوں کی تصدیق نہیں ہو سکی؛ نیچے صرف جانچے گئے حوالے ہیں۔'},
 limited:{roman:'Is tafseel ke liye mere paas kaafi verified evidence nahi hai. Thoda specific sawal poochhein.',en:'I do not have enough verified evidence for that detail. Please make the question more specific.',hi:'इस विवरण के लिए पर्याप्त सत्यापित प्रमाण उपलब्ध नहीं हैं। कृपया सवाल थोड़ा स्पष्ट करें।',ur:'اس تفصیل کے لیے کافی مصدقہ شواہد دستیاب نہیں۔ براہ کرم سوال ذرا واضح کریں۔'}
};
function message(key,language){return MESSAGES[key][language]||MESSAGES[key].en;}
function scriptMatches(text,language){
 if(!/\p{L}/u.test(text))return true;
 if(language==='hi')return /[\u0900-\u097f]/.test(text);
 if(language==='ur')return /[\u0600-\u06ff]/.test(text);
 // Honourifics such as ﷺ are allowed, but whole Hindi/Urdu sentences are not.
 return !/[\u0900-\u097f\u0620-\u06ff]/.test(text);
}
module.exports={LANGUAGES,requestData,languageOf,message,scriptMatches};
