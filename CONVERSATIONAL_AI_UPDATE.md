> Latest additions and current validation: see LATEST_UPDATE_SETUP.md. The original patch notes below are retained for context.

# Conversational Gemini update

Base: origin/main badbf30 (AI update), inspected 24 October 2026. Apply every file in this ZIP at its original repository path. No existing user records, admin roles, authentication configuration, stories or unrelated screens are migrated or deleted.

## Root cause
The previous prompt expressly prohibited writing an answer. It planned a keyword search and selected excerpts in two sequential Gemini calls. The Flutter client sent no conversation history and expected sources-only responses. Two slow provider calls could exhaust the request budget; different failures also produced misleading user messages.

## Changed behaviour
The updated APK uses protocol 2 on the existing callable. Reviewed basic facts (the existing 28 entries, not new hardcoded example answers) have English, Hindi and Urdu versions alongside Roman Urdu. Generic follow-up matching carries a previous subject while preserving new conditions and negation. General questions retrieve local evidence once, then use one Gemini answer-generation stage with recent conversation. Answers precede vertically stacked references. Language/script follows the question or the explicit reply-language setting.

History is bounded to eight messages and exists in app memory only. Generated-answer caches are scoped to the authenticated user and language, signed, versioned and expire after 24 hours. Contextual requests bypass caching. Old APKs retain their existing legacy response contract; install the new APK for conversation mode.

Gemini remains the provider. The existing model default is retained; model access must pass the workflow's real provider check. Runtime generation permits at most two attempts, only on transient failures, within a 35-second provider budget. The callable's existing timeout is unchanged. Corpus initialization has a separate eight-second budget. No streaming is introduced.

Existing quota policy remains: five uncached questions per user/day, global 250 reservations/day, five-second cooldown. At most two provider attempts per reservation preserves the existing 500-attempt upper bound. Failures refund personal allowance using the existing reservation mechanism; global budget reservations are retained. Basic reviewed responses run before quota reservation. No usage counters are reset. Logs distinguish authentication, quota, timeout, provider, network, corpus and output parsing without logging keys or conversation text.

## Reference accuracy and limits
Displayed IDs, labels, links and source text come from the bundled library. Model citations require an exact contiguous source-text anchor. Missing exact references are explicitly unverified. Hadith numbers are labelled as app-edition numbers because editions differ. Quran/Hadith, historical editorial retellings, duas and scholarly editorial summaries are distinguished. Two official scholarly summaries support a limited example of madhhab differences; this is not a complete fiqh database.

A source-text match checks provenance, not semantic entailment of every generated interpretation. Gemini can still misunderstand a question or source. Human review of live outputs remains necessary, particularly disputed rulings and historical detail. Unsupported exact quotations, school claims and grade claims are constrained, but this is not a guarantee of religious correctness.

## Validation actually performed
- 85 Node tests passed: orchestration, reviewed facts and translations, generic context, spelling variation, English/Hindi/Urdu, citation rejection, madhhab provenance, invalid exact reference, cache isolation, quota/refunds and simulated provider failures/deadlines.
- Full bundled library built: 41,039 records (6,236 Quran, 34,353 Hadith, 183 story passages, 267 dua entries).
- Six real-library retrieval checks passed. Local retrieval took approximately 0.16–1.48 seconds, corpus loading 1.44 seconds, peak RSS 415 MiB. These are local measurements, not end-to-end Gemini response times.
- Legacy full-corpus memory check passed at 413 MiB. Workflow YAML/shell syntax, JavaScript checks and git whitespace checks passed. Both modified Dart files parsed successfully.
- NO live Gemini evaluation was run here: no project API key was supplied to this environment. NO Flutter analyzer, Android build or device test was run: Flutter SDK is unavailable. Passing mocked tests does not establish live answer correctness or latency.

## Deploy and test
1. Upload all ZIP files into the repository preserving folders; commit them together on main. Do not upload generated corpus files: Actions rebuilds them.
2. Keep existing repository secrets FIREBASE_DEPLOY_CREDENTIALS and ASK_GEMINI_API_KEY. No OpenAI secret is needed. Do not put keys in Dart or commit them.
3. Actions → Deploy Ask Islam Connect AI (Gemini) → Run workflow → main. This runs corpus validation, tests and a live provider-access check, then deploys only Ask AI. A failed provider check deliberately blocks deployment.
4. Recommended: Actions → Evaluate Ask Islam Connect (Gemini) → Run workflow. This opt-in live evaluation can consume up to 28 provider requests. Download its report and review the actual answers and reference relevance; it does not certify semantics automatically. It does not reset application limits or write user records.
5. Run the existing Android build workflow on the SAME commit. Install that newly built APK, not an older artifact. Existing Play Store installations need the new release for conversation mode.
6. Test Fajr then “isme sunnat kitni hai?”, Ibrahim Alaihis Salam's wife, equivalent Hindi/English questions, a spelling mistake, wife-contact/wudu differences, and an unverifiable exact Hadith number. Check direct answer, correct script, follow-up, relevant references and response time. Test a genuinely novel question too.

The new page keeps normal text size, chat history, microphone input, reply-language settings, copy, and expandable references. Existing English/Urdu text-to-speech remains; Hindi/Roman answer speech is not newly implemented. UI labels remain mainly Roman Hindi/English. Provider outages/real quota exhaustion can still occur and are shown as friendly messages.
