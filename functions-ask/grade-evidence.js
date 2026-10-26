'use strict';
const classes=[['sahih',/\b(?:sahih|saheeh|authentic)\b|صحیح|सहीह/iu],['hasan',/\bhasan\b|حسن|हसन/iu],['weak',/\b(?:daif|zaeef|weak)\b|ضعیف|ज़ईफ़/iu],['fabricated',/\b(?:fabricated|mawdu|mawdoo)\b|موضوع|गढ़ी/iu]];
function gradeClaims(text){
 // Mentioning the book title Sahih Muslim or weak faith is not grading a Hadith.
 if(!/\b(?:hadith|hadees|hadis|narration|riwayat|riwayah|graded|classified)\b|حدیث|روایت|हदीस|रिवायत/iu.test(text))return [];
 const cleaned=text.replace(/\bsahih\s+(?:al[- ]?)?(?:bukhari|muslim)\b/giu,'');
 return classes.filter(([,re])=>re.test(cleaned)).map(([name])=>name);
}
function supportsGrades(text,docs){
 const claimed=gradeClaims(text);if(!claimed.length)return true;
 const available=new Set();
 for(const d of docs){
  if(d?.kind!=='hadith')continue;
  if(['bukhari','muslim'].includes(d.book))available.add('sahih');
  for(const grade of d.grades||[])for(const [name,re] of classes)if(re.test(grade))available.add(name);
 }
 return claimed.every(g=>available.has(g));
}
module.exports={gradeClaims,supportsGrades};
