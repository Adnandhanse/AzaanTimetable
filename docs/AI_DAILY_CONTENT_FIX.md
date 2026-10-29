# AI evidence and daily reminder corrections

Based on main b69e2c1. Changed/new files only. Preserve original paths when copying.

## Verified issues
- The procedural boost recognised tarika/tareeqa but not the reported tariqa spelling. Procedure detection now uses the normalised/contextual question and additional common variants.
- Conversational filler such as bare (in ke bare mein) was interpreted as the English adjective, narrowing retrieval to irrelevant records. It is now treated as query framing.
- Narration-only cross references with a chain of transmitters, but no substantive teaching, could rank highly due to their short length and chapter metadata. Such short bibliographic placeholders are excluded.
- Generic charity was conflated with obligatory zakat. Concepts are separated, zakat must occur in the actual body, and definitional questions prioritise explanatory evidence rather than only short mentions. Multiple relevant source types can be supplied, but unrelated references are never added merely to increase the count.
- An explicit Hadith request now keeps Hadith evidence rather than being crowded by Quran/story excerpts. This filter is disabled for a question explicitly requesting both Quran and Hadith.
- Citation verification now tolerates Unicode canonical equivalence/whitespace wrapping only; different words, made-up sources and out-of-list references are still rejected. Prompts require statement-level source IDs alongside quotations. The cache version changes so old weak responses are not reused.

## Daily card
25 Urdu selections contained incomplete introductions, isolated quoted words, or a different fragment from the English/Arabic matn. They now convey the short complete selected meaning, labelled as meaning rather than a verbatim complete narration. Two Arabic extracts drop narrator/context preambles and retain the relevant supplication. Three context-dependent cards are removed from this rotation, leaving 243 Hadith reminders. Quran rotation is unchanged. Full source narrations, references, Arabic library and user data remain intact. Counts have not been padded to reach an arbitrary target.

## Deployment
1. Upload these files to the same repository paths and commit.
2. Run Deploy Ask Islam Connect with Gemini, then build/install APK from that same commit.
3. AI backend changes require deployment; daily-card text and the corrected ten-question limit message require the updated APK. No reminder service/rules deployment is needed for this patch.
4. Test namaz ka tariqa kya hai, zakat kya hai, zakat ke bare me hadees batao, plus follow-ups. If a request still fails, capture its exact screen message/support code and matching ask-ai-failed log from the same time. An offline retrieval test cannot prove that the remote model completed a live call.

## Validation
97 AI Node tests passed, including procedural variants, narration-only exclusion, Hadith source filtering, and whitespace-only citation verification with rejection of changed words. Nine real-corpus retrieval queries passed. Reported prayer method retrieves Bukhari 6667/6251; zakat definition retrieves Bukhari 1395 and related actual teaching rather than chain-only records. All 243 daily-card reference targets exist in the bundled books, all four language fields are nonempty, and changed Dart files passed syntax parsing. No live Gemini key/API request, installed Android test or scholarly certification was performed. Reference matching proves source text exists, not that every generated interpretation is correct.
