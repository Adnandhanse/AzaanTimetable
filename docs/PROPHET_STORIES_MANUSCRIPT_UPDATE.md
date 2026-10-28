# Prophet Stories: manuscript frame and source-based expansion

Based on repository main f8366a1. Changed/new files only; copy with original paths.

## Design
Existing full-width scene artwork and continuous scrolling are retained. New thin antique-gold rules, mirrored geometric corner ornaments and small diamond dividers are painted by Flutter, so no new raster artwork can be truncated or fail to decode. Decoration ignores taps. A deeper olive ink wash keeps the white 13sp body text readable; title, image and text positions remain responsive. No humans or animals are added. The generated image supplied in chat is a concept preview, not a tested APK screenshot.

## Content
25 books reviewed by chapter inventory. 10 newly written bilingual chapters increase 183 to 193. Original chapters and IDs remain; new chapters have distinct IDs. New content uses Quran passages and, to identify Tabuk, the actual bundled Bukhari 4418 account. Lessons are labelled as reflections in Sources and notes, distinct from scripture. Exact dates, dialogue, battle detail and birth stories are not invented where evidence is absent. This is a selective expansion, not a claim to contain every battle or every report in seerah literature. Short accounts for Idris, Dhul-Kifl and Alyasa remain short because the chosen primary evidence is brief.

| Story | Chapters after update | Added material |
| --- | ---: | --- |
| Adam Alaihis Salam | 10 | Existing sourced account retained; no invented additions |
| Idris Alaihis Salam | 2 | Existing sourced account retained; no invented additions |
| Nuh Alaihis Salam | 19 | Existing sourced account retained; no invented additions |
| Hud Alaihis Salam | 4 | Existing sourced account retained; no invented additions |
| Salih Alaihis Salam | 4 | Existing sourced account retained; no invented additions |
| Ibrahim Alaihis Salam | 17 | Existing sourced account retained; no invented additions |
| Lut Alaihis Salam | 4 | Existing sourced account retained; no invented additions |
| Ismail Alaihis Salam | 6 | Existing sourced account retained; no invented additions |
| Ishaq Alaihis Salam | 3 | Existing sourced account retained; no invented additions |
| Yaqub Alaihis Salam | 6 | Hope Through Grief |
| Yusuf Alaihis Salam | 15 | Existing sourced account retained; no invented additions |
| Ayyub Alaihis Salam | 5 | An Oath and a Merciful Way |
| Shuayb Alaihis Salam | 4 | Existing sourced account retained; no invented additions |
| Musa Alaihis Salam | 22 | A Refusal at the Threshold; Questions Instead of Obedience; The Trial of Wealth |
| Harun Alaihis Salam | 5 | Existing sourced account retained; no invented additions |
| Dhul-Kifl Alaihis Salam | 2 | Existing sourced account retained; no invented additions |
| Dawud Alaihis Salam | 7 | The Trial Before the Battle |
| Sulayman Alaihis Salam | 9 | A Trial and a Prayer |
| Ilyas Alaihis Salam | 3 | Existing sourced account retained; no invented additions |
| Al-Yasa Alaihis Salam | 2 | Existing sourced account retained; no invented additions |
| Yunus Alaihis Salam | 5 | Existing sourced account retained; no invented additions |
| Zakariya Alaihis Salam | 5 | Existing sourced account retained; no invented additions |
| Yahya Alaihis Salam | 4 | Existing sourced account retained; no invented additions |
| Isa Alaihis Salam | 10 | Existing sourced account retained; no invented additions |
| Muhammad ﷺ | 20 | The Trial at Hunayn; Standing Firm in Hardship; Truthfulness and Repentance |

## Progress and rollout
Stable page IDs preserve the saved reading position. Only the six expanded books advance to content version 5, so prior completion does not incorrectly mark added chapters as read. The other nineteen books keep version 4 and their completion status. Saved reading positions remain keyed by original page IDs. Other user data is untouched.

Upload files, commit and build/install the APK. Existing asset declaration already includes stories.json; no pubspec or new image download is needed. Redeploy the AI workflow as well if Ask Islam Connect should search the new story text (the corpus is rebuilt during that workflow). No Firebase rules/masjid migration is needed for this story update.

## Checks
Existing check_prophet_stories.py passed: 25 stories, 193 chapters, 245 reference ranges, matching source targets and scene files. Existing page IDs and all 25 book IDs retained. Quran passages were read against the bundled English translation; Tabuk narration verified in bundled Bukhari 4418. This structural/content check is not a scholarly certification. Flutter build and phone rendering still require CI/device testing.

Five changed Dart files also passed syntax parsing (including the per-book version model).
