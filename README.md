# Masjid Namaz Alarm App — Phase 1

Flutter skeleton app: Splash → Login (mobile number) → OTP → Home →
Masjid Search → Masjid Details → Prayer Times → Settings.

This phase uses **mock data** (see `lib/data/mock_masjids.dart`) so the
app is fully clickable and buildable before Firebase is connected.
Phase 2 will replace the mock data and fake OTP check with real Firebase
Authentication + Firestore.

## How to get your APK

1. Create a new GitHub repository (Private recommended).
2. Upload **all files in this folder**, keeping the folder structure
   exactly as-is — including the hidden `.github/workflows/build.yml`
   file (GitHub's web upload lets you type the full path
   `.github/workflows/build.yml` into the filename box when dragging
   that file in).
3. Go to the **Actions** tab on your repo. A build will start
   automatically (or click "Run workflow" if it doesn't).
4. Once the run finishes (green check ✅), open it and download
   `masjid-alarm-app-apk` from the **Artifacts** section at the bottom.
5. That zip contains `app-release.apk` — install it on any Android
   phone (you may need to allow "install from unknown sources" since
   it isn't from the Play Store yet).

## What's next (Phase 2)

- Firebase project setup (Auth, Firestore, Cloud Messaging)
- Real OTP login
- Real-time prayer times per masjid
- Local + push Azan alarm notifications
