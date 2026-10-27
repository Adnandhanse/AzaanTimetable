# Compact UI, language and timing reminders

Based on main 74558ad. Copy the ZIP contents into the existing repository, keeping paths. Only changed/new source files are included; existing data is not replaced.

## Changes
- Compact 12–13sp Latin body text and restrained serif headings; Arabic/Quran styles and accessibility scaling remain intact.
- Dashboard displays only the last prayer-time Save timestamp. No reminder opt-in or confirmation controls. Saving prayer times always records a server timestamp, including when values are unchanged.
- Automatic reminders retain the existing 10-day initial / 5-day repeat policy, reset by a Save. Device notification permission and a registered device are still required. Legacy records use the existing honest monitoring baseline until their first recorded Save.
- Roman Hindi/Urdu language recognition includes common informal grammar and spelling variants. The obsolete answer-language override is removed; voice language can still be selected. Explicit language requests remain supported.
- Retrieval recognizes prophethood/revelation variants and ranks relevant temporal evidence. The model is instructed to attach supporting source IDs and exact quotations. Existing citation validation remains mandatory; unverifiable sources are never invented. If no exact reference is verified, an honest notice appears instead.
- Cache version changes prevent reuse of prior wrong-language/no-reference responses. Existing quotas are unchanged.

## Deployment
1. Upload these files to the repository and commit them.
2. Run the existing `deploy-ask-islam-connect.yml` workflow with Gemini selected. It regenerates the corpus and deploys the updated AI backend.
3. Run `deploy-timing-reminders.yml` for the Save-based reminder policy and notification copy.
4. Wait for `ui-regression.yml` checks and `build.yml` APK build. Install the APK produced from this same commit.
5. Save timings once, confirm Last saved changes, and test the AI using Roman Hindi and English. Check scheduled reminder delivery on a notification-enabled device.

## Validation and limits
93 AI Node tests and 10 reminder Node tests passed. Changed Dart files passed syntax parsing; git diff whitespace checks passed. Retrieval was checked against the actual bundled corpus. Model calls in regression tests were mocked: live Gemini, Flutter analyzer/widget tests, APK/device rendering and push delivery were not run locally. The CI Flutter checks and device test remain necessary. Reference inclusion and Roman-language prose still depend on model output; validation rejects fabricated references but cannot guarantee every response has a verified citation.
