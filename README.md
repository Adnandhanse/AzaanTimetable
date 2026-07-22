# Masjid Namaz Alarm App — Phase 1 + Phase 3 (Admin, Audio Upload, Platform Admin)

Flutter app covering:

**User side:** Splash (animated Tawaf illustration) → Login (mobile
number) → OTP → Home → Masjid Search → Masjid Details → Prayer Times →
Settings.

**Masjid Admin side:** Login → Register Masjid → Upload Verification →
Prayer Time Dashboard → Update Prayer Times (+ upload a custom Azan
audio recording).

**Platform Admin side (new):** A separate login (tap "Platform Admin
Login" at the bottom of the Masjid Admin login screen) leads to a
dashboard where you review pending masjid registrations and
**Approve** or **Reject** them. Approving flips a masjid's status to
"Verified," which is what unlocks it for followers in the user app.

Mock Platform Admin login for testing: username `admin`, password
`admin123` (hardcoded for now — Phase 2 will replace this with a real,
securely stored account).

This phase uses **mock/in-memory data** (see `lib/data/mock_masjids.dart`)
so everything is clickable and buildable before Firebase is connected.

⚠️ **Important limitation right now:** the in-memory list resets every
time the app restarts, and lives separately on each phone. That means:
- An admin's prayer time updates, and a Platform Admin's approvals, are
  NOT visible to other users/devices yet.
- A custom Azan audio file only plays back on the admin's own device.

Both of these need a real backend — Firestore for data sync, and
Firebase Storage for the audio file — which is Phase 2 work.

## How to test right now
- **As a masjid admin:** Login screen → "Masjid Admin? Login here" →
  use `9876543210` (Masjid Noor) or register a new masjid.
- **As the platform admin:** Masjid Admin login screen → "Platform
  Admin Login" → `admin` / `admin123` → approve/reject pending masjids.

## How to get your APK
Push to GitHub (via GitHub Desktop) → check the **Actions** tab →
download the APK from **Artifacts** once the run is green.

## What's next (Phase 2)
- Firebase project setup (Auth, Firestore, Storage, Cloud Messaging)
- Real OTP login (user + masjid admin), real Platform Admin account
- Real-time prayer times synced from admin to all followers
- Custom Azan audio uploaded to Firebase Storage so it plays for
  everyone following that masjid, not just the admin's phone
- Local + push Azan alarm notifications firing at the actual prayer time


