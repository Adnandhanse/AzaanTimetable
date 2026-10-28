# AI limit, usage and cleaner UI

Copy these changed/new files to the same repository paths. This is a separate patch from Global SMS OTP; apply both patches if using both features.

- Personal daily allowance: 10 new successful AI answers. Basic/direct and eligible cached answers bypass reservation. Failed or unanswered responses refund personal allowance.
- Project allowance stays 250 reservations/day. Each reserved request has a bounded provider attempt budget (up to two calls), so the app budget permits at most 500 attempts; Gemini may impose a smaller quota. In the ideal case 25 users can each use 10 uncached answers; failures consume global reservations too, so this is not a guarantee of 250 delivered answers. One anonymous Firebase UID represents a user; it is not a guaranteed unique person.
- Quota date resets at midnight America/Los_Angeles. It is not India midnight.
- Deployment workflow explicitly writes ASK_USER_DAILY_LIMIT=10; global budget remains unchanged.

## Usage check
Google Cloud Logs Explorer: project actual-masjid-prayer-time. Query:

resource.type="cloud_run_revision"
resource.labels.service_name="askislamconnect"
"ask-quota-reserved"

Each new reservation records quotaDay, userUsed, globalUsed, userLimit and globalLimit. No prompt, email, phone or API key is logged by this new event. Global remaining = globalLimit - globalUsed. These are budget reservations, not actual Gemini token consumption or unique-user counts. Concurrent events may appear out of order; use the highest globalUsed for the same quotaDay. Cache/basic responses do not create this event.

For authoritative current counters, use Firebase Firestore console > _askAiUsage > YYYY-MM-DD-global (Pacific date) > count. Personal records have hashed UIDs. Do not open client read/write access to this private collection. Provider actual usage is shown separately in Google AI Studio's usage view for the key's project.

## UI / notifications
Removed example-question buttons; New Chat and Voice Language are in one menu. Copy and Listen remain answer actions. Replaced spinning loader with a restrained fading icon and Preparing your answer label; system reduce-animation preference is respected. No fabricated progress percentage. Prayer notification format: Fajr Prayer / Masjid name • It's time for Fajr. Reminder message asks the admin to review and save only if needed.

## Deploy
1. Upload and commit files.
2. Run the existing Gemini AI deployment workflow. Run timing reminders deployment for server reminder wording.
3. Build/install APK from the same commit for AI UI and local notification text. Existing scheduled prayer alarms may retain old text until rescheduled by the app.
4. Verify ten-question allowance, copy/listen, follow-up and loading in light/dark themes.

## Validation
104 AI/reminder Node tests passed, including new ten-question boundary/counter checks. Changed Dart syntax and JS syntax checks passed. No live Gemini, SMS, push delivery or Flutter build/device test was performed locally. Existing reference-verification logic remains intact; this patch does not add fabricated references.
