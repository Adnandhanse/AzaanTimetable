# Compact UI, reliable artwork and automatic reminders

Apply these changed/new files over GitHub main 0e114a7 (the international + nearby-address updates). Preserve the original folder paths. No user documents are deleted or migrated.

## Release steps
1. Upload all files from this ZIP to their original paths and commit to main.
2. Let **UI Regression Checks** and the normal **Build Android APK** workflows finish. Do not release if the UI tests fail. Download the APK from this new build for device testing.
3. Run **Deploy prayer timing reminders**. This updates the automatic reminder device registration and English/Urdu push messages. No changes to the 10-day first check / 5-day repeat policy.
4. Run **Deploy Ask Islam Connect AI (Gemini)** once. Story prose changed, so this rebuilds the AI library from the same content. AI quotas and answer-generation logic are unchanged by this patch.
5. Test the APK: light/dark themes; Hadith page; readable OTP field; English AI UI; English and Hindi/Hinglish questions; all story covers; map zoom/selection; admin confirmation and reminders. Use an approved admin account and allow Android notifications.

## What changed and why
- ThemeData now declares dark brightness for dark palettes. Screens that branch on brightness previously chose light surfaces with dark-theme text, causing the washed-out Hadith screen.
- Compact Inter headings and smaller general body styles. Prayer clocks and Quran/Arabic reading styles remain dedicated. System accessibility scaling is preserved.
- Both broken assets (night.webp and table.webp) were zero-byte files. Restored the original valid artwork from the repository history. All 34 scenes referenced by the 25 stories now decode locally with Pillow. The new Flutter test checks engine decoding as well when CI runs.
- Geographic map uses bundled Natural Earth coastlines (public domain), a parchment palette, traditional regional names and tappable name circles. Approximate markers describe associated accounts, not verified birthplaces or exact historical boundaries. All 25 stories remain available in the library.
- Roman narrative uses respectful references to Allah Ta'ala; informal speech wording was refined where present. Added English titles to all 183 chapters. Existing source references, page IDs, scene assignments and saved reading-progress keys remain unchanged. English-selected app opens English stories by default; Roman Urdu remains an explicit reader option. This is editorial presentation work, not a new scholarly authentication of every narrative sentence.
- Removed the reminder opt-in button. Approved-admin device registration starts automatically, retries temporary failures, refreshes on resume/token changes and registers newly approved masjids. Android notification permission cannot be bypassed. If blocked, the only action shown opens phone settings. A pending connection is reported honestly; missing backend deployment/IAM still needs fixing.
- Unknown historical dates are not invented. Confirmation/update dates appear when recorded; otherwise a short useful prompt replaces the repeated missing-date placeholders.
- English app chrome on AI/home/stories/admin reminder surfaces no longer uses Roman Urdu copy. Response language follows the question in automatic mode. Hindi/Hinglish transcripts are Romanized locally; English text remains English. Explicit Hindi/Urdu/English answer selections still take precedence. Voice recognition defaults to English in the English app; choose Hindi/Hinglish under Voice Input for Hindi speech. Recognition quality still depends on the phone's speech service.
- The AI personal quota is still 5 new provider-backed answers per day, plus supported reviewed/cached answers. This patch makes the limit message clear; it does not increase provider costs or promise unlimited answers.

## Validation actually completed
- 10 reminder backend tests passed, including language-separated pushes, cadence and ownership-change cancellation.
- 7 standalone offline Dart transliteration/language cases passed.
- All 34 referenced story images fully decoded with Pillow.
- Story validation: 25 stories, 183 chapters, 234 reference ranges passed. Existing stable IDs and exact reference objects compared unchanged.
- Contrast calculations passed for secondary text on both primary surfaces in all 6 palettes (12 combinations, minimum 5.63:1).
- Changed Dart files syntax parsed/formatted; JavaScript syntax and git whitespace checks passed.

## Pending validation
Local Flutter setup was blocked by automatic safety review because it attempted cloud metadata access. Consequently Flutter widget tests, analyzer, Android build, real-device UI, live Gemini calls and live FCM delivery were NOT verified here. The dedicated CI workflow runs the new Flutter regressions without deployment/signing secrets. Actual Android notification permission, deployed callable availability/IAM and scheduler activation must be checked in the project/device.

Map data: Natural Earth 1:110m land, cropped to 23–62 E / 10–42 N. https://www.naturalearthdata.com/about/terms-of-use/ . Source URL is recorded in lib/data/prophet_map_land.dart. No online map API, new key or runtime map download is required.
