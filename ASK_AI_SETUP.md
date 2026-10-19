# Ask Islam Connect — real AI language understanding

This update adds a paid OpenAI-backed, source-grounded question-and-answer flow.
It is implemented locally; it is NOT activated on your Firebase project yet.
An APK upload alone cannot activate the AI server.

## Apply this update last

Apply after Ask_And_Prophet_Stories_Improved_Update.zip. Extract files into the
same repository paths. Keep all earlier Prophet Stories/Learn illustrations.
Do not upload ZIP files themselves into .github/workflows.

No Flutter dependency/pubspec change is needed. firebase_auth and cloud_functions
are already in the project. Existing ownership services are not changed.

## One-time setup (phone/browser)

1. Open https://platform.openai.com/ and create your API project/key with API
   billing enabled. Keep the key private; do not paste it into app code, a Git
   file, chat, screenshots, or an APK.
2. GitHub repository → Settings → Secrets and variables → Actions → New repository
   secret. Name: **ASK_OPENAI_API_KEY**. Value: your API key. Keep the existing
   **FIREBASE_DEPLOY_CREDENTIALS** secret as it is.
3. After the rules checks in step 6, Firebase Console → actual-masjid-prayer-time → Authentication → Sign-in method
   → Anonymous → Enable → Save. The app uses a separate anonymous Firebase
   session for AI, leaving the masjid admin's phone login untouched.
4. Enable Secret Manager API for the existing project:
   https://console.cloud.google.com/apis/library/secretmanager.googleapis.com?project=actual-masjid-prayer-time
5. Google Cloud IAM: the service account used by FIREBASE_DEPLOY_CREDENTIALS
   (the client_email in that credential JSON) needs Secret Manager Admin to
   create/update the server secret and its access binding. Keep its existing
   successful Functions/Cloud Run deployment roles. Do not add this role to an
   unrelated personal email and expect the GitHub workflow to inherit it.
   The deployed function's runtime service account needs Cloud Datastore User
   for the quota counters; Firebase CLI binds its Secret Accessor access when
   deploying the secret-enabled function. The usual Gen2 runtime for this
   project is 532564834976-compute@developer.gserviceaccount.com; confirm the
   actual runtime service account on the new function before granting access.
6. Protect the **_askAiUsage** Firestore collection from all client reads/writes.
   Keep your existing masjid/prayer rules. Add inside the database documents
   block:

   ```text
   match /_askAiUsage/{document} {
     allow read, write: if false;
   }
   ```

   IMPORTANT: this deny does not override another matching allow rule. If your
   rules have a catch-all allowing all authenticated writes, narrow that rule
   so it cannot grant any access to _askAiUsage. Anonymous AI users are also
   authenticated users. Also check every admin/masjid timing write: a rule that
   only tests request.auth != null is insufficient once Anonymous sign-in is
   enabled. Existing admin writes must require the actual authorized admin, and
   must not become available to anonymous users. Do not publish with a catch-all authenticated-write
   rule: users could tamper with the quota counters. The current deployed
   Firestore rules were not supplied in this repository, so this update does
   not overwrite or claim to audit them.
7. GitHub → Actions → **Deploy Ask Islam Connect AI** → Run workflow → main.
   It builds the complete searchable server library from the current repository
   assets, tests the backend, stores the key in Secret Manager and deploys ONLY
   the separate ask-islam-connect codebase. Its --force flag also lets Firebase
   configure artifact cleanup without the earlier noninteractive cleanup error.
8. After this workflow is green, run **Build Android APK**, install the newest
   APK and choose AI jawab. Accept the in-app question-processing notice to test.

If the workflow reports permission denied, check the named caller/runtime from
that exact error against step 5; do not keep adding unrelated roles to yourself.
No account permissions or cloud configuration were changed from this workspace.

## What happens for a question

The server asks GPT-4.1 mini to interpret the full question and construct English,
Urdu and Roman topic expansions. Those terms are NOT from the older fixed topic
list. Server retrieval searches the actual bundled Quran, six Hadith books and
all 25 Prophet Stories. Up to 12 matching, deduplicated excerpts are passed back
to the model for a short source-derived explanation in Roman Urdu/Hinglish.

The answer has clickable source references and matching Urdu/English voice text.
Original source text is displayed separately. IDs are validated against the
actual server-selected corpus; client-provided scripture/candidates are never
accepted. Weak/unknown/disputed grading must not be represented as a sahih ruling.
AI answers still need source checking: citation-ID validation cannot prove every
sentence is a correct scholarly interpretation. There is no guarantee of an
answer to every question. Missing evidence/ambiguity/provider failure are shown
explicitly, rather than silently substituting the old keyword search.

This is AI interpretation + bilingual lexical retrieval + grounded explanation,
not a claim that an embedding/vector index or a general fatwa engine is present.
Follow-up questions currently run as independent questions; repeat context such
as the prophet/topic name. No conversation memory is uploaded or retained.

## Updating the library later

Change the existing Quran/Hadith/Stories assets as usual, then rerun **Deploy Ask
Islam Connect AI**. The workflow rebuilds the corpus automatically; there is no
manual document-by-document upload to OpenAI. Build the app too if its assets
changed, so app source links and server data use the same source IDs.

Generated corpus.json.gz is intentionally omitted from this changed-files ZIP;
GitHub creates it from the existing app assets before deployment. The local
validated build contains 40,758 references: 6,236 Quran verses, 34,353 Hadith
records, and 169 Prophet Story parts. This is a reference/record count, not a
claim of 34,353 unique nonrepeating Hadith texts.

## Limits and operating costs

Default: 20 attempts/user/day, 200 attempts/project/day, at least 5 seconds
between requests per user. Attempts reserve quota BEFORE paid provider calls,
including failed requests. Global transactions apply across function instances,
provided quota documents are protected as above. Anonymous account rotation can
consume the global allowance but cannot raise this shared cap through the API.

Each normal answer uses at most two model calls; missing evidence uses one.
Planner/output tokens and source context are bounded. Configure your OpenAI
project usage controls too. Provider API, Firebase function, Secret Manager and
Firestore usage are billed on your accounts, not included by adding these files.
No fixed monthly cost is promised here.

Optional runtime environment variables (set on the Ask function and redeploy):
ASK_AI_ENABLED=false is the kill switch; ASK_USER_DAILY_LIMIT defaults to 20;
ASK_GLOBAL_DAILY_LIMIT to 200; ASK_AI_MODEL defaults to gpt-4.1-mini. Counters use
UTC calendar days. Counter documents have expiresAt; enable a Firestore TTL policy
for that field if you want automatic cleanup. Counters store pseudonymous hashed
UIDs/counts only, not questions or answers. App Check is not configured/enforced
by this bundle; consider adding it when hardening public distribution.

## Privacy / release note

Before publishing the AI-enabled release, update your privacy policy and review
Play Data Safety for this new optional text-processing flow. Suitable factual
policy text to adapt to your actual published policy:

"When you choose Ask Islam Connect AI, your typed or transcribed question and
relevant passages from our Islamic library are sent through our Firebase backend
to OpenAI to produce an explanation. The AI request does not include your audio,
phone number or location. Please do not put personal details in questions. An
anonymous Firebase account and pseudonymous usage counters help control abuse.
Our code does not store question/answer history and requests OpenAI Responses
without response storage; OpenAI's own processing and retention policies still
apply. You can instead use the on-device Library search without AI processing."

The existing phone speech provider may separately process speech as explained in
the original voice notice. No claim of zero provider retention is made.

## Validation completed / still needed

Completed: Node backend tests (mocked model transport), real corpus build and
retrieval checks, Firebase function module load, Dart source parsing and workflow
YAML parsing. Tests include forged citations, insufficient evidence, ambiguity,
provider refusal/failure, quotas and context limits.

Still needed: real API/model evaluation with your key, Firebase deployment/IAM/
rules verification, Flutter APK build and phone testing. A green automated test
is not evidence that the live model has answered your questions correctly.

Phone tests: natural full questions about hand positions, parents/neighbours,
debt, and prophets (Yusuf, Musa/Firaun, Zamzam). Check the answer against opened
source text, listen/stop in both languages, test quota/provider failures and
switch to Library search. Keep the ownership transfer button disabled as before.

## Implementation references

https://developers.openai.com/api/docs/guides/structured-outputs
https://developers.openai.com/api/docs/models/gpt-4.1-mini
https://firebase.google.com/docs/functions/config-env
https://firebase.google.com/docs/firestore/security/rules-structure
