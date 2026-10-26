# Latest combined update: India default + Gemini answer quality

This ZIP contains all changed/new files for the conversational Gemini assistant, international admin approval and 10/5-day timing reminders. Apply this ZIP at the original repository paths. Do not overwrite these newer files with any older ZIP afterwards. The source baseline is badbf30. Retain any unrelated newer local changes, particularly custom pubspec additions.

## India remains the default
Registration, admin login and transfer each initialize their country to India (+91). Users can choose another country. Changing country changes the calling-code prefix; backend validation stores canonical E.164 numbers. The included international flow now uses email/password plus Platform Admin approval, without OTP or an external email service. See INTERNATIONAL_ADMINS_SETUP.md.

## Gemini improvements in this revision
- Request instructions such as “tareeqa”, “method” and “step by step” no longer have to appear verbatim in scripture to retrieve relevant evidence. Broad prayer-method questions prioritize narrations containing multiple prayer actions.
- Roman Hindi daily-life concepts have more semantic aliases, including parents' rights, anger, forgiveness, truthfulness, children and provision. This is still local retrieval plus Gemini interpretation, not universal semantic understanding.
- Elliptical follow-up retrieval inherits known topics from user messages without blindly carrying the old relationship (wife → son, for example). Explicit new topics override the old topic. Full recent conversation still goes to Gemini.
- Quran/Hadith source context-only and abbreviated Hadith matches are reduced. General advice demotes weak/fabricated-graded material rather than promoting it as practice evidence. An authenticity question can still retrieve such material with its real grading metadata.
- Bedtime dua queries prioritize the collection's bedtime chapter. Reviewed facts can anchor relevant references for paraphrases without adding hardcoded answers to the new test questions.
- Generation instructions distinguish count, method, name and ruling questions. The answer comes first, with conditions/differences and references after it as appropriate.
- Model citations must be among evidence actually supplied to that generation and must match source text. Grading claims require the actual claimed grade in source metadata; a Sahih collection does not justify calling a narration fabricated or weak.
- Answer cache version bumped: stale generated responses from the old implementation are not reused. Existing usage-limit counters remain unchanged. There are no extra sequential Gemini calls and no provider switch.

## What was tested
89 AI Node tests passed. International approval, transfer and reminder tests are reported in functions-international/VALIDATION.json; previous OTP test totals are superseded. Tests include mocked providers; these are not live email/FCM/Gemini results.

Six additional REAL bundled-library retrieval checks passed for Roman/English prayer procedure, bedtime dua, parents' rights, anger management and the final Prophet. See docs/gemini-quality-validation.json for measured timings and selected source IDs. These tests examine candidate evidence, not a generated Gemini answer's semantic correctness. Local retrieval takes roughly a fraction of a second to about one second per question on this environment; that is not an end-to-end service latency guarantee. Library loading adds cold-start time. Existing full-library retrieval/memory checks also passed at about 420 MiB peak RSS.

Modified Dart files syntax-parse, and workflow YAML/shell and JavaScript syntax were checked. No Flutter analyzer/Android build, live Firebase account signup, device notification, deployed-rule check or live Gemini generation was performed here. No project API key was supplied. Correctness of every model interpretation is NOT guaranteed by matching a source-text anchor. Broad fiqh coverage is still limited by the available scholarly source data.

## Deploy
1. Upload all files in this ZIP in their original folders and commit together.
2. If international email verification/reminders are not configured, first complete INTERNATIONAL_ADMINS_SETUP.md, including enabling Email/Password and merging the Firestore/Storage ownership rules. No email sender/API key is needed. The combined ZIP includes these features, but setup credentials/rules cannot be inferred from source files.
3. Actions → Deploy international admin verification → Run workflow → main, when using those features. This deploys compatible international, ownership and reminder backends only.
4. Actions → Deploy Ask Islam Connect AI (Gemini) → Run workflow → main. It builds the source corpus, checks relevance/memory/tests and provider compatibility, then deploys Ask AI. Keep the existing ASK_GEMINI_API_KEY secret; no OpenAI key is needed.
5. Recommended live check: Actions → Evaluate Ask Islam Connect (Gemini) → Run workflow. The expanded opt-in evaluation uses up to 40 Gemini requests. Download the actual answer report and review directness, language, references and timing. It does not automatically certify religious correctness.
6. Run Build Android APK on the SAME commit, install that APK and check Fajr → Sunnah follow-up, natural prayer-method questions, parents, bedtime dua, spelling mistakes, language changes and an unverifiable exact reference. Recheck international transfer and notification behaviour before release.

Generated corpus files are deliberately omitted from the ZIP. Actions rebuilds them from current app assets. Existing users/masjid data are not migrated or deleted. India defaults are already set; no additional setting is needed for that requirement.
