# Offline registration and transfer guides

## What is included
Settings > Help & Guides has two guides, selected using the existing app language setting (English or Urdu):
- Masjid registration: 6 pages per language.
- Administration transfer: 5 pages per language, including the previous-admin-unavailable request path.

Each includes numbered instructions and clearly labelled illustrated form diagrams with the relevant control highlighted. These are illustrations based on the current Flutter source, not real screenshots. No personal numbers, real OTPs or account details appear.

Guides open offline inside the app, with page controls, swipe and pinch zoom. Save PDF uses the existing FilePicker Android system save dialog. Share PDF opens the system share sheet; nothing is automatically sent. Cancelling Save does not display a success message. English/Urdu reader chrome and TalkBack page summaries match the selected document language.

The app displays bundled rendered pages from the exact PDFs. This avoids adding a PDF renderer native library to the Android build. Saving or sharing exports the actual PDF, not a screenshot. Urdu copy uses correctly shaped raster text in the PDF; it is not selectable text. Screen-reader summaries are supplied in-app through the manifest.

## Apply
This ZIP contains changed/new files only, preserving their app-relative paths. It also includes the previous timezone conversion patch so you can apply both together. Do not upload it as a nested folder. Merge if your repository has newer edits in the same files.

1. Copy the contents into the app repository, keeping paths.
2. pubspec.yaml includes both `lat_lng_to_timezone: 0.2.0` from the timezone update and `share_plus: 7.2.2` for PDF sharing, plus explicit guide asset directories. Preserve any newer assets/dependencies in your own pubspec.
3. Run `flutter pub get`, then `flutter analyze` and the app's tests. Keep the generated pubspec.lock if the repository tracks it.
4. Build and install a test APK using your existing workflow. No Firebase Functions, rules or Gemini redeployment is needed.
5. Settings > Help & Guides: test each guide in English and Urdu. Switch language through Settings > App Language. Check page navigation, zoom, Save, cancellation and Share. Repeat in airplane mode and in dark theme.
6. Verify the actual registration and transfer flows against your deployed backend before releasing the instructions to users. A guide does not enable a disabled transfer feature or fix an unavailable backend.

## Validation actually performed
- Parsed/formatted new and changed Dart with Dart 3.13.7.
- Inspected file_picker 8.0.0 saveFile(bytes: ...) implementation and share_plus 7.2.2 API against official package sources.
- Opened all four PDFs and verified 22 pages in total, matching the manifest and bundled page images.
- Reviewed the rendered pages, including Urdu shaping and the longest Urdu transfer page. Corrected a compressed-diagram overlap before packaging.
- Verified all guide assets exist, match manifest paths and are declared in pubspec.yaml.
- Previous timezone helper: 31 executable regression checks passed (see TIMEZONE_CONVERSION_SETUP.md).
- Flutter dependency resolution for the full app, full Flutter analysis, APK compilation and Android Save/Share UI were NOT run here: the Flutter and Android SDK are unavailable. These remain required in CI/on a device. The selected sharing package matches the older Flutter 3.24 build baseline; no upgrade of the project's unrelated dependencies is attempted.

## Files to maintain
`assets/guides/manifest.json` defines PDF paths, rendered page paths and accessibility summaries. Keep each PDF and its rendered pages in sync when editing. Flutter's asset declaration is not recursive, so all four page-image subdirectories are explicitly listed.

The PDFs describe the source available in this workspace (b69e2c1 checkout plus existing edits), not an independently inspected future APK. Admin phone verification depends on the existing Firebase SMS region/billing settings.

## Video links update
Each PDF page now has a clickable YouTube link in its footer. Registration links to bQCdNrpS2aM; administration transfer links to GFf2gKK0G1E, in both languages. The in-app reader adds Watch Video because it displays rendered PDF pages. Videos open externally using the existing url_launcher dependency and require internet. Offline reading is unchanged. All 22 PDF URI annotations and their mapping to the guide manifest were checked. Video content/playback and Android launching were not live-tested here.

## Actual registration screenshots correction
The two registration PDFs now use cropped screenshots from the supplied registration recording, replacing all six schematic diagrams in each language. Existing privacy blurs are retained. Screens reflect the recorded app version; later country selection controls may differ. Transfer remains illustrated because an actual transfer screen recording is not available in this workspace. No registration or transfer form code/layout was changed. Re-rendered the registration PDFs and retained their clickable YouTube links.

## Concise in-app guide revision
Registration: six real-screen pages, each with only 1-2 short instructions and no paragraph notes. Transfer: five short numbered steps on a single page; simulated screens removed. Both follow the existing selected app language and keep the supplied YouTube links. Settings list copy is shortened. PDFs/rendered assets/manifest and the Flutter Help screen are included in this app patch. Guide asset/link checks passed; full Flutter/Android testing remains pending.
