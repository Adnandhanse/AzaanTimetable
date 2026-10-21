# Ask Islam Connect — Gemini Flash free-tier setup

This bundle REPLACES Ask_Islam_Connect_Real_AI_Update.zip (the OpenAI version).
Apply it last, after Ask_And_Prophet_Stories_Improved_Update.zip. You do not need
to upload the old OpenAI AI ZIP first. Keep the earlier Prophet Stories/Learn
assets and voice plugin. Only AI feature files/configuration are supplied here.

The local code now calls **gemini-3.5-flash-lite** using the Gemini Developer API.
It does not call OpenAI, attach Google Search tools or switch providers on error.
No actual Gemini key was supplied here; this has NOT been deployed or live-tested.

## Important: 500/day is NOT a confirmed model quota

The official pricing page's 500 RPD row refers to Google Search grounding.
This app searches its OWN Quran/Hadith/Stories corpus and does not use that tool.
The actual model RPM, RPD and token limits must be read for your own project in
Google AI Studio. A Google Search allowance is not a model-request entitlement.

Application-side default budget: 250 attempted questions/project/Pacific day,
5 questions/user/day, with at most 2 model requests per question and no automatic
retries. That bounds this app's direct model calls to at most 500/day. It does
NOT grant 500 calls if Google gives your project a smaller quota. If a provider
limit is reached earlier, AI requests stop with a clear limit message. Other applications using the same key/project consume its quota too.

## Setup, in order

1. Open https://aistudio.google.com/ and sign in with your Google account.
2. Create a SEPARATE project for AI, e.g. **Islam Connect AI Free**. Do not link
   a billing account to this new AI project. Check that its tier says **Free**.
   Do not disable/unlink billing from the existing Firebase app project.
3. In that AI project's Usage / Rate limits page, find **Gemini 3.5 Flash-Lite**.
   Verify that the model is available and has a nonzero quota. Record RPM/RPD/TPM.
   Do not buy credits or upgrade this project as part of the free pilot.
4. Create an API key for that FREE AI project. Do not send the key in chat,
   screenshots or source files. GitHub repo → Settings → Secrets and variables
   → Actions → New repository secret:
   Name: **ASK_GEMINI_API_KEY**. Secret: paste your Gemini key. Save.
   Keep the existing FIREBASE_DEPLOY_CREDENTIALS deployment secret unchanged.
5. Check the existing Firestore rules BEFORE enabling anonymous authentication.
   The _askAiUsage counter collection must be inaccessible to app clients:

   ```text
   match /_askAiUsage/{document} {
     allow read, write: if false;
   }
   ```

   Put this inside the existing database documents block, preserving existing
   masjid/prayer rules. A deny does not override another matching allow.
   Narrow any authenticated-write catch-all so it cannot grant access to this
   collection. Also ensure admin/timing writes require the authorized admin,
   not merely request.auth != null: anonymous users are authenticated too.
   Existing deployed rules were not supplied here, so this bundle does not
   overwrite them or claim that they have been audited.
6. Firebase Console → actual-masjid-prayer-time → Authentication → Sign-in method
   → Anonymous → Enable → Save. The AI service uses a separate anonymous app
   session so it does not replace the masjid admin's phone login.
7. Enable Secret Manager API in the EXISTING Firebase project:
   https://console.cloud.google.com/apis/library/secretmanager.googleapis.com?project=actual-masjid-prayer-time
   The GitHub deployment service account (client_email in your credential JSON)
   needs Secret Manager Admin in addition to its existing successful Functions /
   Cloud Run deployment roles. The runtime service account needs Cloud Datastore
   User for quota counters. Firebase CLI binds Secret Accessor during deployment.
   Check actual runtime identity on the function; the usual Gen2 default here is
   532564834976-compute@developer.gserviceaccount.com. Do not grant roles to an
   unrelated personal account expecting GitHub to inherit them.
8. Upload these extracted files to their matching repo paths. GitHub → Actions
   → **Deploy Ask Islam Connect AI (Gemini Flash)** → Run workflow → main.
   It builds the corpus from current repo assets, runs tests, stores the GEMINI
   key in Firebase Secret Manager and deploys only the Ask AI codebase.
9. After the AI deployment is green, run Build Android APK, install the newest
   APK and test Poochhein. The in-app notice now names Google Gemini and requires
   fresh consent even if someone had accepted the earlier OpenAI notice.

A key belonging to a PAID Gemini project can be billed. Code cannot turn such a
key into a free one. Keep the AI key's project on Free tier and verify this in
AI Studio; a failure never triggers an OpenAI or other provider fallback.
Firebase backend/Secret Manager/Firestore usage in your existing project is
separate and can still be billed. This is not a promise of a zero-cost whole app.

## What the app does: strict sources-only mode

Gemini interprets natural full questions and makes English/Urdu/Roman retrieval
terms dynamically. The server searches its trusted Quran, six Hadith books and
25 Prophet Stories corpus. A second Gemini call can choose up to four relevant
source IDs. It is NOT asked to write a religious answer or explanation.

The server validates the selected IDs and returns the original database records.
Any extra model prose, fabricated source text or voice text is ignored. The app
requires the sources-only response contract, so an older free-form backend must
be redeployed rather than silently showing generated religious prose.

Quran/Hadith text is the existing Arabic/Urdu/English source text; audio reads the
existing translation. Prophet Story results are explicitly marked as sourced
editorial retellings and open the story's references. Prewritten daily meanings
may still be available through their existing Aasaan matlab action. This mode
DOES NOT generate a new easy Roman explanation or new speech translation.

Missing evidence and ambiguity show fixed messages. No model-generated fatwa,
Quran quote, Hadith text, event detail or account-specific religious ruling is
forwarded. AI may still misunderstand a question/select a less relevant source;
source-ID validation does not prove relevance or authenticity grading. Read the
full reference/context and check grading. A weak narration does not become sahih
because search finds it.

There is no automatic provider retry, paid fallback, Google Search grounding,
embedding service, semantic answer cache or conversation-history upload. Each
question is independent. Quota exhaustion is shown as a limit message, without switching providers.

## Updating content and limits

After changing Quran/Hadith/Stories assets, rerun the Gemini AI deployment so its
corpus uses those same IDs/texts, then build the APK if app assets also changed.
The generated server corpus is built by GitHub; it is intentionally omitted
from this changed-files ZIP. Current validated corpus: 40,758 records (6,236
Quran verses, 34,353 merged Hadith records and 169 Story parts). Hadith record
count includes narrations/variants and does not mean that many unique sayings.

ASK_AI_ENABLED=false disables AI. ASK_USER_DAILY_LIMIT defaults to 5;
ASK_GLOBAL_DAILY_LIMIT defaults to 250 questions, hard-clamped to at most 250
in this free pilot. Quota day follows America/Los_Angeles (Pacific, DST-aware).
ASK_GEMINI_MODEL defaults to gemini-3.5-flash-lite. The client adapter also accepts
explicit legacy gemini-2.5-flash / gemini-2.5-flash-lite for accounts that still have access; it never switches automatically.
An unavailable model/key requires checking the actual account quota first.

Quota counters contain hashed anonymous UIDs, counts, request time and expiresAt;
no question/answer/audio history is written by our code. Close this collection to
client access or users could tamper with the application-side quota. Enable TTL
on expiresAt if automatic counter cleanup is desired. App Check is not enabled
by this bundle. Service-account permissions and actual deployed rules still
need project-level verification.

## Privacy / public release

Before publishing, update your policy and review Data Safety for optional AI
text processing. Adapt this factual paragraph to your existing policy:

"When you choose Ask Islam Connect AI, your typed or transcribed question and
relevant library passages are sent through our Firebase server to Google Gemini
to interpret the question and choose related references. The displayed source text is returned from our own database, not generated by Gemini. Audio, phone number and location are not
included in this AI request. Avoid including personal or confidential details
in questions. Under Google's free-tier terms, submitted content and responses
may be used to improve Google's products. An anonymous account and pseudonymous
usage counters help limit abuse. Our code does not save question/answer history;
Google's own processing/retention terms still apply."

The existing phone speech provider can process audio separately as explained in
the original voice notice. We do not claim zero provider retention.

## Validation and remaining checks

Completed: automated backend tests using mocked Gemini transport; REST request
shape/schema handling; quota/no-retry/no-provider-fallback checks; citation and
retrieval checks; Firebase module load; Dart parsing and workflow YAML parsing.
No live Gemini model call, account/quota lookup, Firebase deployment, APK build
or device test was possible without your key/account/environment.

After setup, test full natural questions, source links and Urdu/English audio;
ask about hands/fingers, parents, debt, Yusuf, Musa/Firaun and Zamzam. Check
selected passages against the full source context. Test quota exhaustion and setup/network errors.

## Official references

https://ai.google.dev/gemini-api/docs/pricing
https://ai.google.dev/gemini-api/docs/rate-limits
https://ai.google.dev/gemini-api/docs/billing
https://ai.google.dev/api/generate-content
https://ai.google.dev/gemini-api/docs/structured-output
https://firebase.google.com/docs/functions/config-env
https://firebase.google.com/docs/firestore/security/rules-structure

## Clean page update
The page now has one editable question field, microphone and Poochhein button. Voice and translation options are in the top settings icon. Library mode, topic chips and repeated notices were removed. All questions go to the Gemini callable; missing deployment, disabled Anonymous auth and API setup failures show distinct messages. No silent offline fallback.

The deployment workflow makes one constant structured-output Gemini request before deploying. It counts against your provider quota. If ASK_GEMINI_MODEL is overridden in Cloud Run or a functions environment file, update it to gemini-3.5-flash-lite too; the default applies only when no override exists.
