# Registration and AI reliability update

## Apply and deploy
This ZIP includes the previous guides/timezone update and the present registration/AI changes. Copy the contents to the same repository-relative paths, merging any newer edits in your repository.

1. GitHub Actions: run **Deploy international admin verification**. It deploys the existing `functions-international` codebase with `firebase.registration.json`, then checks that `registerVerifiedMasjid` exists in **actual-masjid-prayer-time / us-central1**. It does not deploy ownership-transfer or reminder codebases.
2. GitHub Actions: run **Deploy Ask Islam Connect AI (Gemini)** using the current workflow already in your repository. It rebuilds the corpus from the current Quran, Hadith, stories and dua assets, runs checks and deploys the Gemini backend. Do not change the provider or secret names.
3. Build/install a test APK with the normal workflow. Test international registration end to end, not merely the OTP step. Verify India registration and existing admin login as well.
4. Test AI with prayer, Quran, Hadith, dua and Prophet-story questions and follow-ups. Confirm the returned reference supports the answer. Try a repeated question and an exact nonexistent reference.

The code is not deployed from this session. Existing Play Console API/16 KB policy issues are separate and are not fixed in this package.

## Registration finding
The screenshot shows phone verification succeeded, followed by `firebase_functions/not-found` at `MasjidRepository.register`. Available source calls `registerVerifiedMasjid` in us-central1; the backend source exports the same name and region. That endpoint's registration handler does not deliberately throw not-found for normal registration. This strongly suggests a missing endpoint, wrong project/region or deployed-version mismatch. Without the production function inventory/logs this cannot be proved. Running only the AI or ownership deployment does not deploy this registration endpoint.

The new deploy inventory check verifies presence and region, not successful authentication/database writes. Live SMS-to-registration remains a required device test. Do not bypass the server with client-side masjid writes. Phone proof, ownership checks, pending approval and user data protections are retained.

The OTP screen now maps errors to concise English/Urdu messages and a support code. It no longer renders raw Cloud Functions stack traces. Concurrent post-verification callbacks are guarded; a failed completion can be retried with the existing fresh phone session.

## AI findings and changes
The available conversational path used a repeated scan of all 41,049 records for each query group and recomputed normalized bodies. A warm-instance inverted index plus cached candidate features preserves whole-word/alias matching and existing ranking, with lower repeated-query CPU work. Relevant source-type diversity remains: Quran, Hadith, Prophet-story editorial content, scholarly notes and duas. Explicit Hadith requests remain Hadith-only. Source excerpts are bounded to six records, with larger excerpts for connected procedures. No new canned answers were added.

The old validator could retain uncited religious statements as answered, adding only a notice. It now rejects unsupported factual religious statements (including inherited follow-up topics) instead of silently presenting them as grounded. Exact quotes still must match supplied source text and IDs must belong to retrieved evidence; no automatic decoration with unrelated sources. Typographic quotation marks/spacing are normalized without accepting changed words. Short full Quran verses can validate without an arbitrary 16-character minimum. These checks establish source membership/text matching, not complete theological or entailment review.

Timeouts no longer automatically launch a second lengthy Gemini generation. Fast transient HTTP failures can retry once within an 18-second provider deadline; first-attempt generation timeout is 14 seconds. Quota/auth/parsing failures are not retried. Normal output budget remains 1700 tokens; detailed output is 2600. Smaller evidence input is intended to reduce provider work; actual live Gemini speed/accuracy has not been measured here.

Optional persistent cache reads/writes have smaller latency budgets. The private answer-cache revision is bumped so older uncited responses are not reused. User/global quota policy and reviewed-answer bypass are unchanged. Logs record retrieval duration, evidence kinds and source count, without question text, OTPs or API keys.

## Actual validation and limits
- 100 AI unit/regression tests passed with mocked provider calls; no live API calls.
- 13 registration identity/endpoint-contract tests passed.
- Four deployment-inventory checks passed (correct endpoint, absent endpoint, wrong region, malformed inventory).
- Nine real-corpus relevance scenarios and six source-diversity/memory scenarios passed.
- See AI_RETRIEVAL_BENCHMARK.json for measured before/after timings. Warm scenarios averaged about 75% less local retrieval time. The first indexed search was slower (about 2.7 seconds versus 1.2 seconds) because the index is built lazily. This is not an end-to-end production latency claim. Peak process memory in the nine-question run was about 679 MiB; service configuration remains 2 GiB.
- No authenticated Firebase deployment, real OTP registration, live Gemini, complete Flutter analysis, APK build or Android UI test was run. The environment does not currently contain Flutter/Android SDK. A successful local test does not establish that production has these files.
