# Prayer timing reminders: 10 days, then every 5 days

Changed/new files only, based on repository commit badbf30. This patch does not include or overwrite the previous conversational-AI changes. Keep that ZIP's files too. If your pubspec has local additions after that commit, retain them and add just `firebase_messaging: ^15.1.3` under dependencies rather than replacing your newer pubspec.

## Behaviour
- Backend checks daily at 10:00 AM India time, using the server clock.
- Verified masjids: first reminder after 10 full days without a timing update/confirmation. If still pending, repeat after another 5 full days (then 5 again).
- A timing update OR “Timings sahi hain” confirmation resets the 10-day period. The old five-day cadence no longer applies. Other edits (photos/audio/profile) do not reset it.
- Example: checked on 1 November at 9 AM → reminder on 11 November at 10 AM, then 16 and 21 November if untouched. If checked on 13 November at 9 AM, no reminder on 16 November; next eligible check is 23 November at 10 AM.
- Saving identical times confirms them without changing “Last changed”. Registration records an initial timestamp. Existing old timestamps are retained; missing legacy dates remain visibly unknown. An unknown-date masjid starts a private monitoring period on the first backend check and becomes eligible ten days later; it is not given a fictitious historical update date.
- Platform Admin list and detail view show last changed, last confirmed and checked/pending status. These are read from Firestore; confirming does not modify prayer times.
- Only the current masjid admin's registered devices receive reminders; regular followers and Platform Admin do not receive these pushes. Platform Admin sees the dates/status in the dashboard as requested. UID is authoritative; verified phone fallback is used only for legacy records with no adminUid.
- Notification taps open the timing screen when the matching admin session exists; otherwise they open admin login. Cold-start taps wait for splash navigation. Foreground reminders use a separate ordinary notification channel and never play azan or use full-screen alarm behaviour.

## Deploy once
1. Upload these files preserving folders and commit them together. No existing user or masjid records need deleting or exporting.
2. Firebase Console → Firestore → Rules: merge `firebase_config/timing_reminders/rules.fragment.txt` with your CURRENT rules. Never replace the whole rules file with the fragment. The two new private collections must not be readable/writable by client apps, including via a broad wildcard allow. Existing masjid field allow-lists must permit the server-timestamp field `timesConfirmedAt` for the CURRENT owner, along with existing timing fields. Actual current deployed rules were not supplied here, so rules are not automatically deployed or guessed.
3. In this project, enable Cloud Scheduler and Firebase Cloud Messaging API if not already enabled:
   - https://console.cloud.google.com/apis/library/cloudscheduler.googleapis.com?project=actual-masjid-prayer-time
   - https://console.cloud.google.com/apis/library/fcm.googleapis.com?project=actual-masjid-prayer-time
   Existing Cloud Functions, Cloud Run, Cloud Build, Artifact Registry and Firestore setup remains required. Cloud Scheduler uses a billing-enabled project.
4. Runtime service account (check Cloud Run service details; normally `532564834976-compute@developer.gserviceaccount.com`) needs existing Firestore read/write access and `cloudmessaging.messages.create`. If missing, grant **Firebase Cloud Messaging API Admin** (`roles/firebasecloudmessaging.admin`) to that runtime account, not all users. Deploy credentials need existing Functions deployment/ActAs permissions and Cloud Scheduler job-management permission; the new scheduled function may require Cloud Scheduler Admin for the deploy account. Do not grant Owner as a shortcut.
5. GitHub Actions → **Deploy prayer timing reminders** → Run workflow → main. Reuses FIREBASE_DEPLOY_CREDENTIALS; no new API key/secret. Only the new `timing-reminders` codebase deploys; ownership and Ask AI functions are untouched.
6. Run your existing Android build workflow on the same commit. Flutter pub get resolves the added messaging dependency. Install that APK and open the admin dashboard once. If requested, tap Enable reminders and allow notifications. The dashboard must say “Timings reminders enabled”. Each admin needs this new APK; old APKs cannot register for push.
7. Do not disable the generated Scheduler job. Its name contains `sendPrayerTimingReminders`. It runs server-side even when the app is closed. Firestore client reads/writes continue to use your existing security rules; callable confirmation checks ownership on the backend.

## Practical acceptance test
Use a separate verified TEST masjid/admin, not live production timings. Register its device using the new APK, then set only that test record's timesUpdatedAt to eleven days ago and remove its timesConfirmedAt in Firebase Console. In Cloud Scheduler, Run now on the generated reminder job (this scans ALL eligible verified masjids; choose a test project if you cannot notify production admins). Expect one normal notification, tap to open timing page. Run again: no duplicate. Confirm unchanged timings: timestamps/status refresh and another Run now must send nothing. For five-day recurrence, move the TEST private state's lastSentAt to six days ago, preserving sentBaseline and leaving the masjid unconfirmed; run again. Test update/confirmation after a reminder, phone foreground/background, logout, token refresh and a former owner's device.

## Validation and delivery limits
Nine Node policy/processor tests pass: 10/5-day boundaries, reset on update/confirmation, unknown dates, verification status, ownership, duplicate runs, concurrent changes, absent devices and failed FCM sends. Changed Dart files were syntax-parsed; workflow/shell and JavaScript syntax were checked. No Flutter SDK, Android build, Firebase deployment or live-device push test was available in this environment. Those checks remain necessary before a Play Store release.

The scheduler claims a short lease and re-reads ownership/timestamps before each send. Accepted FCM messages cannot be recalled if an admin updates immediately after the send; TTL is one hour and the current phone clears displayed reminders after successful update/confirmation. Successful FCM acceptance is not proof of on-device delivery. Android notification permission, network, force-stop and battery settings can affect delivery. A crash between sending and recording can exceptionally produce a duplicate; this is not an exactly-once delivery guarantee. Devices inactive for 90 days are excluded until the app registers again. Failed/no-device attempts do not consume the five-day reminder window and are retried on the next daily check.

New stored data is an admin device's FCM token, UID, verified-phone ownership snapshot, masjid association, token-refresh timestamp, and per-masjid reminder state. Tokens are never shown in logs or public masjid documents. Logout unregisters the installation and deletes its FCM token where network permits; ownership is rechecked for every send. No SMS/WhatsApp is used. Standard server/Firestore/Scheduler charges can apply; no cost estimate or free-service guarantee is implied.

Official implementation references:
- https://firebase.google.com/docs/functions/schedule-functions
- https://firebase.google.com/docs/cloud-messaging/flutter/get-started
- https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
- https://docs.cloud.google.com/iam/docs/roles-permissions/firebasecloudmessaging
