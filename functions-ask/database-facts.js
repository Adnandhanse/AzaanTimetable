'use strict';
// Counts are calculated during CI from the bundled Quran, never guessed by AI.
function countIntent(question) {
 const q=question.normalize('NFKC').toLowerCase().replace(/[^\p{L}\p{N}]+/gu,' ').trim();
 if(!/(?:qur[ae]?a?n|قرآن|कुरान|क़ुरआन)/u.test(q))return null;
 if(!/(?:kitn|total|count|how many|number of|کتن|कितन|कुल)/u.test(q))return null;
 // Avoid answering a total when asked about a subset, a surah, or a topic.
 if(/(?:surah?\s+\w+\s+(?:mein|me|has)|about|regard|related|mention|bare|baare|mutalliq|namaz|salah|roza|women|aurat|jihad|sajd|ruku|para|juz|حکم|نماز|سجد|آیت.*سور|ay.*surah)/u.test(q))return null;
 if(/\d/u.test(q))return null;
 const verse=/(?:aaya?t|aaya?h|aya?t|ayah|verses?|آیات|آیت|आयत)/u.test(q);
 const surah=/(?:sur[ae]?h|سورت|سورہ|सूर)/u.test(q);
 if(verse&&surah)return null;
 const filler=new Set('quran quraan qur an kuran me mein mai men main ki ke ka ko hai hain h kitni kitne kitna kitny total kul aayat aayate aayatein aayaten aayaat ayat ayate ayatein ayaten ayaat ayah ayahs aayah aayats aayatey verses verse surah surahs surat suratein suraten sura suras how many are there in the holy noble number of count tell please mujhe batao btao بتائیں قرآن میں کی کل کتنی کتنے آیات آیت سورتیں سورت سورہ ہیں है हैं में कितनी कितने कुल कुरान क़ुरआन आयतें आयत सूरह'.split(' '));
 if(q.split(' ').some(word=>!filler.has(word)))return null;
 if(verse)return 'quran_verses';if(surah)return 'quran_surahs';return null;
}
function databaseAnswer(operation,stats) {
 if(!stats || !Number.isSafeInteger(stats.quranVerses)||!Number.isSafeInteger(stats.quranSurahs))return null;
 if(!['quran_verses','quran_surahs'].includes(operation))return null;
 const text=operation==='quran_verses'
  ? `App ke Quran dataset ki numbering ke mutabiq Quran mein ${stats.quranVerses.toLocaleString('en-IN')} aayatein hain. Ayaton ko number karne ke tareeqe mukhtalif ho sakte hain; isse Quran ka matn nahi badalta.`
  : `Quran mein ${stats.quranSurahs} surah hain.`;
 return {status:'answered',answerMode:'sources-only',paragraphs:[],speech_urdu:'',speech_english:'',hits:[],
  followup:text,answer:{text,reference:'App ka bundled Quran dataset · har surah ke verse records ka count',type:'database'}};
}
module.exports={countIntent,databaseAnswer};
