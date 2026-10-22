'use strict';
// Exact known words only. Unknown words and negation remain intact; no fuzzy
// transliteration may erase a qualifier and turn a new ruling into a basic fact.
const words={
'तरीका':'tarika','तरीक़ा':'tareeqa','आखिरी':'aakhri','आख़िरी':'aakhri','आखरी':'aakhri','अंतिम':'last','नबी':'nabi','पैगंबर':'nabi','पैगम्बर':'nabi',
'नाम':'naam','कौन':'kaun','क्या':'kya','का':'ka','की':'ki','के':'ke','है':'hai','हैं':'hain','था':'tha','थी':'thi','बताओ':'batao','बताइए':'batao','मुझे':'mujhe',
'नमाज':'namaz','नमाज़':'namaz','फजर':'fajr','फ़ज्र':'fajr','फज्र':'fajr','फ़जर':'fajr','सुबह':'subah','में':'mein','कितनी':'kitni','कितने':'kitne','रकात':'rakat','रकाअत':'rakat','रकातें':'rakat','रकाते':'rakat','फर्ज':'farz','फ़र्ज़':'farz','सुन्नत':'sunnat',
'नहीं':'nahi','नही':'nahi','बाद':'baad','पहले':'pehle','कजा':'qaza','क़ज़ा':'qaza',
'कुरान':'quran','क़ुरान':'quran','कुरआन':'quran','क़ुरआन':'quran','आयत':'ayat','आयतें':'ayatein','सूरह':'surah','सूरते':'surahs',
'इब्राहिम':'ibrahim','इब्राहीम':'ibrahim','बीवी':'biwi','पत्नी':'biwi','हजरत':'hazrat','हज़रत':'hazrat','अलैहिस्सलाम':'alaihissalam','अलैहिस':'alaihis','सलाम':'salam',
'ईसा':'isa','याह्या':'yahya','यहया':'yahya','माँ':'maa','मां':'maa','पिता':'father','भाषा':'language','जुबान':'zaban','ज़बान':'zaban',
'آخری':'aakhri','آخِری':'aakhri','نبی':'nabi','پیغمبر':'nabi','نام':'naam','کیا':'kya','کون':'kaun','کا':'ka','کی':'ki','کے':'ke','ہے':'hai','ہیں':'hain','تھا':'tha','تھی':'thi','بتاؤ':'batao','بتائیں':'batao',
'فجر':'fajr','نماز':'namaz','میں':'mein','کتنی':'kitni','کتنے':'kitne','رکعت':'rakat','رکعات':'rakat','رکعتیں':'rakat','فرض':'farz','سنت':'sunnat','نہیں':'nahi','بعد':'baad','پہلے':'pehle','قضا':'qaza',
'قرآن':'quran','قران':'quran','آیات':'ayatein','ابراہیم':'ibrahim','بیوی':'biwi','حضرت':'hazrat','علیہ':'alaihis','السلام':'salam','عیسی':'isa','یحیی':'yahya','والد':'father','والدہ':'mother'
};
function romanQuestion(text){
 return String(text).normalize('NFKC').replace(/[\u064B-\u065F\u0670]/g,'').replace(/[\p{L}\p{M}\p{N}]+/gu,w=>words[w]||w);
}
module.exports={romanQuestion};
