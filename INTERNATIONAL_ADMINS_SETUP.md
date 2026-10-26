# International admins: no OTP, no domain or email service

This version REPLACES the earlier international email-OTP setup. Do not configure Resend, SMTP, ADMIN_EMAIL_API_KEY, ADMIN_EMAIL_FROM or custom-token signing for the international signup flow.

## Behaviour
- India (+91) is selected by default on registration, login and transfer.
- Indian admins keep Firebase SMS OTP.
- International applicants select country, enter details and create an email/password account. No OTP or email-verification message is sent. Their masjid is submitted as Pending Verification.
- Their email/phone are UNVERIFIED contact details, not proof of identity. New contacts are stored with country calling code in E.164 format. Passwords are handled only by Firebase Authentication, not Firestore or app preferences.
- Platform Admin reviews the masjid/applicant and approves or rejects. Before approval the applicant can see pending status but cannot manage prayer times, send announcements, confirm timings or transfer ownership.
- International login uses email/password. No one can log into an admin account simply by typing an email or phone number.
- Any direct transfer involving an international admin becomes a Pending request. The old admin keeps access until an enabled Platform Admin approves. Recipient signs in/creates their account in a separate Firebase app so the current admin stays logged in. Existing timings, followers, photos and audio are preserved.
- New admin self-initiated takeover requests also remain pending. Indian-to-Indian direct transfers retain verified SMS recipient proof.
- Old email-OTP callable endpoints remain as fail-closed compatibility stubs: older APKs are told to update. They do not send emails or load provider secrets. Old OTP helper files may remain in source for compatibility but are not used by the new screens.

## Only required setup
1. Firebase Console → Authentication → Sign-in method → Email/Password: ENABLE. Keep Phone enabled for India. There is no new email API key or sender domain to configure.
2. Ensure your actual Platform Admin account's Firebase UID has `platformAdmins/{UID}` with `enabled: true` in Firestore. Create/edit this only in Firebase Console/Admin SDK. A password login alone never grants Platform Admin privileges. Existing properly configured Platform Admin records need no change.
3. Merge `firebase_config/international_admins/rules.fragment.txt` into CURRENT Firestore rules. Do not replace the entire rules file with the fragment. Approved email/password owners need matching UID + email and masjid verificationStatus Verified for management writes. Block self-approval and client ownership/contact/verification-flag edits. Keep private backend/reminder collections inaccessible to clients. Preserve public masjid reads and current platform approval permissions. Current deployed rules were not supplied, so they are not automatically replaced.
4. Storage rules: authorize approved owners' normal uploads by masjid UID, with the same size/type restrictions. If you allow applicant photos before approval, scope that permission only to their own pending masjid's photo paths and photo-list updates; it must not allow timing/admin/status changes.
5. Upload all latest files and commit. Actions → Deploy international admin verification → main. The workflow now requires ONLY the existing FIREBASE_DEPLOY_CREDENTIALS secret. It deploys international, ownership and compatible reminder backends; no email credentials are read or uploaded.
6. Build/install a NEW APK from the same commit. Old email-OTP APKs cannot use the replacement flow. Existing Indian records remain readable without migration.

Existing Firestore/Auth/Functions runtime permissions and reminder Scheduler/FCM setup still apply. No new Resend account, domain purchase, SMTP password or signing IAM role is required by this new international flow. If you already stored the old email secrets, this version no longer reads them; do not delete secrets still used by another app/service. Gemini's ASK_GEMINI_API_KEY is separate and remains required for Ask AI.

## Device acceptance checks
- India signup/login remains SMS OTP and stores country-coded contacts.
- International signup does NOT send a code; create password, submit and see Pending Verification with disabled management controls.
- Approve using the actual Platform Admin account: the same international UID can now manage the masjid by logging in with email/password.
- Wrong password and unapproved accounts cannot manage it. Masjid email/password users cannot auto-enter Platform Admin.
- International transfers remain pending and do not change adminUid until approval. Rejecting leaves old owner intact. Approving preserves follower/timing/photo/audio data.
- Forgotten passwords can use Firebase's built-in reset email link. That optional recovery action is not an OTP/signup requirement and does not require Resend.

No live Firebase signup, deployed security-rule, Android build, device or FCM test was run here. Node policy/endpoint tests use mocks; Dart syntax parsing is not a Flutter analyzer/build result. Test on a test masjid before Play Store release.
