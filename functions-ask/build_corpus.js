'use strict';
// Run from any cwd. Build ONLY from the existing reviewed repository assets.
const fs = require('node:fs');
const path = require('node:path');
const {createGzip} = require('node:zlib');
const {Readable} = require('node:stream');
const {pipeline} = require('node:stream/promises');
const {normalize} = require('./core');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const load = name => JSON.parse(fs.readFileSync(path.join(root, 'assets', name), 'utf8'));
const docs = [];
const english = load('quran/quran_en.json');
const urdu = new Map(load('quran/quran_ur.json').map(s => [Number(s.id), s]));
for (const s of english) {
  const uv = new Map((urdu.get(Number(s.id))?.verses || []).map(v => [Number(v.id), v.translation]));
  for (const v of s.verses) docs.push({id: `quran:${s.id}:${v.id}`, kind: 'quran',
    surah: Number(s.id), number: Number(v.id), title: s.transliteration,
    en: v.translation || '', ur: uv.get(Number(v.id)) || '', ar: v.text || '', grades: []});
}
for (const book of ['bukhari','muslim','abudawud','tirmidhi','nasai','ibnmajah']) {
  const en = load(`hadith/eng_${book}.json`), ur = load(`hadith/urd_${book}.json`), ar = load(`hadith/ara_${book}.json`);
  const map = data => new Map(data.hadiths.map(h => [Number(h.hadithnumber), h]));
  const em = map(en), um = map(ur), am = map(ar);
  for (const number of new Set([...em.keys(), ...um.keys()])) {
    const e = em.get(number), u = um.get(number), a = am.get(number);
    if (![e,u,a].some(h => (h?.text || '').trim())) continue;
    const chapter = String(e?.reference?.book ?? u?.reference?.book ?? 0);
    const grades = [...new Set([e,u,a].flatMap(h => (h?.grades || [])
      .map(g => `${g.grade || ''} — ${g.name || ''}`)).filter(g => g.replace('—','').trim()))];
    docs.push({id: `hadith:${book}:${number}`, kind: 'hadith', book, number,
      title: en.metadata.name, en: e?.text || '', ur: u?.text || '', ar: a?.text || '',
      context: en.metadata.sections?.[chapter] || '', grades});
  }
}
for (const b of load('prophet_stories/stories.json').books) {
  b.pages.forEach((p,i) => docs.push({id: `story:${b.id}:${p.id}`, kind: 'story',
    storyId: b.id, pageId: p.id, number: i+1, title: b.name, chapter: p.title,
    en: p.english, roman: p.roman, ur: '', ar: '', grades: [], sources: p.sources,
    image: `assets/prophet_stories/scenes/${p.scene}.webp`, context: `${b.id} ${b.name} ${p.title}`}));
}
if (docs.length < 40000 || new Set(docs.map(d => d.id)).size !== docs.length) throw Error('Corpus is incomplete or has duplicate IDs');
async function build() {
  const hash=crypto.createHash('sha256');
  async function* records() {
    for (const d of docs) {
      // Work is done once in CI, not at each Cloud Run cold start.
      d.normalized=` ${normalize(`${d.en} ${d.ur} ${d.roman || ''} ${d.context || ''} ${d.title} ${d.chapter || ''}`)} `;
      const line=JSON.stringify(d)+'\n';
      hash.update(line);
      yield line;
    }
  }
  await pipeline(Readable.from(records()),createGzip(),
    fs.createWriteStream(path.join(__dirname,'corpus.ndjson.gz')));
  // A stale legacy array file should never be uploaded alongside the stream.
  fs.rmSync(path.join(__dirname,'corpus.json.gz'),{force:true});
  const manifest={format:'normalized-ndjson-v1',count:docs.length,sha256:hash.digest('hex'),
    kinds:Object.fromEntries(['quran','hadith','story'].map(k=>[k,docs.filter(d=>d.kind===k).length]))};
  fs.writeFileSync(path.join(__dirname,'corpus_manifest.json'),JSON.stringify(manifest,null,2));
  const quranDocs=docs.filter(d=>d.kind==='quran');
  fs.writeFileSync(path.join(__dirname,'database_stats.json'),JSON.stringify({
    quranSurahs:new Set(quranDocs.map(d=>d.surah)).size,
    quranVerses:quranDocs.length,corpusSha256:manifest.sha256}));
  console.log(manifest);
}
build().catch(error=>{console.error(error);process.exitCode=1;});
