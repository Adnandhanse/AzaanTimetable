/// Local phonetic transliteration of a recognizer's Hindi transcript. This is
/// not translation and does not change Quran/Hadith text. English/Urdu stay as
/// received. Common conversational spellings are normalized for readability.
String askRomanTranscript(String input) => input.replaceAllMapped(
  RegExp(r'[\u0900-\u097F]+'), (match) {
    final word = match.group(0)!;
    final known = _words[word];
    if (known != null) return known;
    final letters = word.runes.map(String.fromCharCode).toList();
    final out = StringBuffer();
    for (var i = 0; i < letters.length; i++) {
      final c = letters[i];
      if (_consonants.containsKey(c)) {
        final next = i + 1 < letters.length ? letters[i + 1] : '';
        out.write(next == '़' ? (_nukta[c] ?? _consonants[c]) : _consonants[c]);
        final afterNukta = next == '़' && i + 2 < letters.length ? letters[i + 2] : next;
        if (!_vowels.containsKey(afterNukta) && afterNukta != '्' && i < letters.length - 1) out.write('a');
      } else {
        out.write(_vowels[c] ?? _other[c] ?? c);
      }
    }
    return out.toString();
  });

const _words = <String, String>{
 'आखिरी':'aakhri','आख़िरी':'aakhri','आखरी':'aakhri','अंतिम':'aakhri','नबी':'nabi','नाम':'naam','पैगंबर':'paigambar','रकातें':'rakatein','रकाते':'rakate','फज्र':'fajr','फ़ज्र':'fajr',
 'आग':'aag','फिरौन':'firaun','फ़िरऔन':'firaun','फिरऔन':'firaun',
 'कुआं':'kuan','कुएं':'kuen','कुआँ':'kuan','ख्वाब':'khwaab','ख़्वाब':'khwaab',
 'जेल':'jail','कैद':'qaid','क़ैद':'qaid','कश्ती':'kashti','समंदर':'samandar',
 'समुद्र':'samandar','मछली':'machhli','काबा':'kaaba',
 'कुर्बानी':'qurbani','क़ुर्बानी':'qurbani','हिजरत':'hijrat','पैदाइश':'paidaish',
 'मौत':'maut','वफात':'wafat','वफ़ात':'wafat','धुल':'dhul','किफ्ल':'kifl',
 'अल':'al','यसा':'yasa','धुलकिफ्ल':'dhulkifl',
 'आदम':'adam','इदरीस':'idris','नूह':'nuh','हूद':'hud','सालेह':'salih',
 'इब्राहिम':'ibrahim','इब्राहीम':'ibrahim','लूत':'lut','इस्माइल':'ismail',
 'इस्माईल':'ismail','इसहाक':'ishaq','याकूब':'yaqub','यूसुफ':'yusuf','युसूफ':'yusuf',
 'अय्यूब':'ayyub','अयूब':'ayyub','शुऐब':'shuayb','मूसा':'musa','हारून':'harun',
 'दाऊद':'dawud','सुलेमान':'sulayman','इलयास':'ilyas','यूनुस':'yunus',
 'जकरिया':'zakariya','ज़करिया':'zakariya','यहया':'yahya','ईसा':'isa',
 'मुहम्मद':'muhammad','मोहम्मद':'muhammad','जमजम':'zamzam','ज़मज़म':'zamzam',
 'हाजरा':'hajar','हाजिरा':'hajar','कहानी':'kahani','किस्सा':'kissa',
 'वाकिया':'waqia','वाक़िया':'waqia','बताना':'batana','जानना':'janna',
 'अलैहिस':'alayhis','सलाम':'salam','हज़रत':'hazrat','हजरत':'hazrat',
 'नमाज':'namaz','नमाज़':'namaz','नमाज़ों':'namazon','सलात':'salat',
 'मुझे':'mujhe','हमें':'humein','मैं':'main','में':'mein','है':'hai','हैं':'hain',
 'हूं':'hoon','हूँ':'hoon','क्या':'kya','क्यों':'kyun','कैसे':'kaise','कब':'kab',
 'कहां':'kahan','कहाँ':'kahan','कौन':'kaun','कितना':'kitna','कितनी':'kitni',
 'का':'ka','की':'ki','के':'ke','को':'ko','से':'se','पर':'par','और':'aur',
 'यह':'yeh','ये':'ye','वह':'woh','वो':'wo','एक':'ek','भी':'bhi','नहीं':'nahi',
 'ना':'na','तो':'to','ही':'hi','जो':'jo','लिए':'liye','बारे':'baare',
 'बताओ':'batao','बताएं':'batayein','बताइए':'bataiye','चाहिए':'chahiye',
 'सवाल':'sawal','पूछना':'poochna','पूछूं':'poochun','पूछूँ':'poochun',
 'हुक्म':'hukm','हुकुम':'hukum','हदीस':'hadees','हदीसें':'hadeesein',
 'कुरान':'quran','क़ुरान':'quran','आयत':'ayat','सही':'sahi',
 'हाथ':'haath','हाथों':'haathon','बांधना':'baandhna','बाँधना':'baandhna',
 'बांधने':'baandhne','बाँधने':'baandhne','बांधते':'baandhte',
 'रखना':'rakhna','रखने':'rakhne','रखते':'rakhte','रखें':'rakhein',
 'उठाना':'uthana','उठाने':'uthane','उठाते':'uthate','उठाएं':'uthayein',
 'उंगली':'ungli','उँगली':'ungli','हिलाना':'hilana','हिलाने':'hilane',
 'हिलाते':'hilate','हरकत':'harkat','सीने':'seene','सीना':'seena',
 'छाती':'chhati','नाभि':'naaf','नाफ':'naaf','नीचे':'neeche','ऊपर':'upar',
 'दायां':'dayan','दायाँ':'dayan','दाहिना':'dahina','बायां':'bayan',
 'बायाँ':'bayan','बाएं':'bayein','रकात':'rakat','रुकू':'ruku',
 'सजदा':'sajda','सजदे':'sajde','तशह्हुद':'tashahhud','वुजू':'wuzu',
 'वुज़ू':'wuzu','रोजा':'roza','रोज़ा':'roza','सब्र':'sabr',
 'गुस्सा':'gussa','माँ':'maa','मां':'maa','पिता':'baap','पड़ोसी':'padosi',
 'झूठ':'jhoot','सच':'sach','दुआ':'dua','माफी':'maafi','सफाई':'safai',
 'कर्ज':'qarz','क़र्ज़':'qarz','निकाह':'nikah','जकात':'zakat',
 'बच्चे':'bachche','खाना':'khana','खाने':'khane','पीना':'peena',
 'पानी':'paani','सोना':'sona','सोने':'sone','सफर':'safar','सफ़र':'safar',
 'करना':'karna','करने':'karne','करते':'karte','करें':'karein','कर':'kar',
 'होता':'hota','होती':'hoti','होते':'hote','हो':'ho','था':'tha','थी':'thi',
 'आप':'aap','मेरा':'mera','मेरे':'mere','अब':'ab','अगर':'agar','बस':'bas',
 'इस्लाम':'islam','अल्लाह':'Allah','सुन्नत':'sunnat','तरीका':'tareeqa',
 'तरीक़ा':'tareeqa','इशारा':'ishara','इशारे':'ishare','रीलेटेड':'related',
};
const _consonants = <String, String>{
 'क':'k','ख':'kh','ग':'g','घ':'gh','ङ':'ng','च':'ch','छ':'chh','ज':'j',
 'झ':'jh','ञ':'ny','ट':'t','ठ':'th','ड':'d','ढ':'dh','ण':'n','त':'t',
 'थ':'th','द':'d','ध':'dh','न':'n','प':'p','फ':'f','ब':'b','भ':'bh',
 'म':'m','य':'y','र':'r','ल':'l','व':'v','श':'sh','ष':'sh','स':'s','ह':'h',
 'क़':'q','ख़':'kh','ग़':'gh','ज़':'z','ड़':'r','ढ़':'rh','फ़':'f','ळ':'l',
};
const _nukta = <String, String>{'क':'q','ख':'kh','ग':'gh','ज':'z','ड':'r','ढ':'rh','फ':'f'};
const _vowels = <String, String>{
 'ा':'a','ि':'i','ी':'ee','ु':'u','ू':'oo','ृ':'ri','े':'e','ै':'ai','ो':'o',
 'ौ':'au','ॅ':'a','ॉ':'o','्':'','़':'',
};
const _other = <String, String>{
 'अ':'a','आ':'aa','इ':'i','ई':'ee','उ':'u','ऊ':'oo','ऋ':'ri','ए':'e',
 'ऐ':'ai','ओ':'o','औ':'au','ं':'n','ँ':'n','ः':'h','।':'.','॥':'.',
 '०':'0','१':'1','२':'2','३':'3','४':'4','५':'5','६':'6','७':'7','८':'8','९':'9',
};
