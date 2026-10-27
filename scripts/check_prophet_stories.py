"""Validate story assets, stable IDs and reference targets (not a scholarly review)."""
import json
import struct
from pathlib import Path
root=Path(__file__).resolve().parent.parent
def read(p):return json.loads((root/p).read_text())
data=read('assets/prophet_stories/stories.json')
quran={s['id']:{v['id'] for v in s['verses']} for s in read('assets/quran/quran_en.json')}
hadith={book:{h['hadithnumber'] for h in read(f'assets/hadith/eng_{book}.json')['hadiths'] if h.get('text','').strip()} for book in ['bukhari','muslim']}
assert len(data['books'])==25
seen=set();refs=0
for b in data['books']:
 assert b['id'] not in seen;seen.add(b['id'])
 assert ('Alaihis Salam' in b['name']) or b['id']=='muhammad',b['name']
 assert b['pages']
 ids=set()
 for page in b['pages']:
  assert page['id'] not in ids;ids.add(page['id'])
  assert page['roman'].strip() and page['english'].strip() and page['sources']
  image = root/f"assets/prophet_stories/scenes/{page['scene']}.webp"
  assert image.is_file(), page['id']
  raw = image.read_bytes()
  assert len(raw) > 100 and raw[:4] == b'RIFF' and raw[8:12] == b'WEBP', f"Invalid story artwork: {image}"
  assert struct.unpack('<I', raw[4:8])[0] + 8 == len(raw), f"Truncated story artwork: {image}"
  for ref in page['sources']:
   refs+=1
   if ref['kind']=='quran':
    assert ref['end']>=ref['start']
    for n in range(ref['start'],ref['end']+1):assert n in quran[ref['surah']],(page['id'],ref)
   else:assert ref['number'] in hadith[ref['book']],(page['id'],ref)
print(f"PASS: 25 stories, {sum(len(b['pages']) for b in data['books'])} chapters, {refs} reference ranges; scene assets and reference targets exist.")
