# Islam Connect — Stories + AI update

Based on deployed repository commit **8299239**. This ZIP contains only changed/new source files. Extract it and replace matching paths in the repository. Do not upload the ZIP itself into `.github/workflows`.

## What changed

- All **25** Prophet Stories expanded in Roman Urdu and English. **183 story chapters** in total (previously 169). Nuh Alaihis Salam: 19 chapters; Yusuf Alaihis Salam: 15. The shorter Quran accounts remain shorter; they have not been given invented biographies.
- Existing page IDs retained, so reading resumes at the same named chapter. Completion badges reset for this content edition while saved positions remain.
- Reader uses the scene behind the text, with a dark layer for readable contrast. The full 3:2 scene is visible above the story and continues behind the narration. Long text expands naturally instead of being clipped into a fixed box.
- Six clickable region circles in an illustrated map: Misr, Hijr/Thamud, Madinah, Makkah, Saba, Al-Ahqaf. These are **event associations, not claimed birthplaces, GPS coordinates or travel routes**. All 25 stories remain available below the map; unknown locations are not invented.
- Hindi/Urdu and additional Roman spellings now reach the reviewed basic-answer route. “Aakhri nabi ka kya naam tha”, its Hindi form and its Urdu form were tested through the actual callable handler without database, quota or provider access.
- Broad supported Learning questions such as “namaz ka tarika” open the existing referenced guide without an AI call. Specific rulings still use retrieval.
- If source selection times out after retrieval, the app shows clearly marked **unverified reading suggestions**, not an invented answer. A planning-stage timeout can still fail; this does not claim to eliminate provider outages.
- Optional OpenAI provider adapter, pinned to `gpt-6-luna`; no automatic paid fallback. Same library/citation validation, quotas and cache. Default remains Gemini.
- Diagnostic `ask-route` logs include release `language-story-v5`, revision, source kind, detected script and a question hash, without the raw question. This makes the deployed route observable.

## Upload and build

1. Extract the ZIP. Copy the contained folders/files into their matching repo paths; commit the changes.
2. In Actions, start a **new** `Deploy Ask Islam Connect AI (Gemini / OpenAI)` run from `main`. Do not rerun an old commit.
3. For existing Gemini: keep `provider = gemini`; the existing secret is reused.
4. Run **Build Android APK** for the same commit; download the APK from that build and install it. Both the backend and APK must be updated to get all changes, particularly the unverified-source warning and provider consent notice.
5. No new pubspec dependencies or illustration files are required. Existing `assets/prophet_stories/` declarations and all bundled scene WebP files must remain.

## To select OpenAI

The adapter is implemented but has **not been live-tested with an API key here**.

1. Create an OpenAI API project with API billing/access. ChatGPT Plus is a separate subscription.
2. GitHub repo → Settings → Secrets and variables → Actions → New repository secret.
3. Name: `ASK_OPENAI_API_KEY`. Value: your API key. Never paste the key into chat, Dart code or the repository.
4. Run the new AI deployment workflow with `provider = openai`.
5. The workflow checks a small JSON response from the selected provider before deployment, saves the selected key in Firebase Secret Manager and deploys the same callable. It never switches providers automatically if a call fails.
6. If model access, billing or permissions fail, deployment stops; share the error text with the key hidden.

The existing application quotas remain: 5 uncached AI questions per user/day and 250 project question reservations/day, with up to two provider calls per question. Basic answers and successful cached results run before these quotas. These are app limits, not a promise of provider free quota. OpenAI is paid usage. Firebase hosting/Firestore/Functions charges remain separate.

Official model/API references used for the optional adapter:
- https://developers.openai.com/api/docs/models/gpt-6-luna
- https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create

## Checks completed here

- 65 Node tests passed, including callable startup for both providers, multilingual basic questions, negative/modifier guards, canonical citation validation, cache/quota behaviour and unverified-source fallback.
- Real search corpus: 40,772 records, 404 MiB peak RSS in the corpus check.
- 25 stories, 183 chapters, 234 reference ranges: targets and scene files exist. All 169 previous chapter IDs retained.
- All seven changed Dart files parsed with a Dart grammar; workflow YAML and shell syntax checked.

**Limits:** no Flutter SDK/device build or live Gemini/OpenAI requests were available here. Grammar parsing is not Flutter type checking or visual QA. Reference-target checks do not replace a scholar's review of every sentence. Narration is an original explanatory retelling, not a literal Quran translation or a full Ibn Kathir edition.

## Before production

Test on the APK first:
- Type and speak the last-prophet question in Roman Hindi and Hindi; expect Muhammad ﷺ / Quran 33:40.
- Test Fajr total, farz and Sunnah separately; then a missed-prayer question, which must not get the generic answer.
- Test “namaz ka tarika” and a specific hand-position question; they should take different routes.
- Check a new uncached question, reference opening, repeating a successful question, quota messages and a provider outage.
- Open all story books; check Nuh and Yusuf continuity, map circles, English/Roman toggle, sources, large text settings, English audio and resume after closing.

The map contains no claimed coordinates for uncertain birthplaces. Artwork is illustrative scenery; it is not evidence of the appearance of historical sites.
