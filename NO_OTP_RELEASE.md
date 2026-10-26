# International signup without OTP

Use this latest combined ZIP; do not overwrite it with older ZIPs. Country defaults to India (+91). Gemini improvements and 10/5-day timing reminders are included.

International registration: details → create email/password login → Pending Verification → Platform Admin approval → management access. NO email/SMS OTP is sent to international applicants. Email/mobile stay unverified contact details. A password remains necessary so another person cannot log in simply by knowing the email/mobile.

International transfer: recipient signs in/creates an account in a separate session → request is saved as Pending → current owner keeps access → enabled Platform Admin reviews and approves/rejects. Ownership is never changed automatically in an international transfer. Indian-to-Indian direct SMS-verified transfer remains available.

Setup:
1. Firebase Authentication → Sign-in method → Email/Password enabled. Phone stays enabled for India. No domain, Resend, SMTP, email API key or custom-token signing setup is needed for this flow.
2. Your real Platform Admin UID must have platformAdmins/{UID} with enabled=true. Merge the CURRENT rules with the provided approval/owner helper fragment; never grant applicants permission to change their verificationStatus, adminUid or verification flags. See INTERNATIONAL_ADMINS_SETUP.md for current rules/Storage notes.
3. Upload these files, commit, run Actions → Deploy international admin verification, then build/install the APK from the same commit. Existing FIREBASE_DEPLOY_CREDENTIALS is the only secret this deployment workflow requires. Ask AI still separately uses its existing Gemini key/deployment workflow.

Validation: 120 backend tests passed (89 AI, 12 international/compatibility, 10 transfer, 9 reminder). Dart syntax parsing and workflow syntax passed. Firebase Auth/network calls in endpoint tests are mocked. No live Firebase signup, deployed-rule test, APK build, device notification or email/password device test was run here.

Test before release: unapproved international account sees pending but cannot manage; real Platform Admin approves; that UID can then manage; ordinary masjid password accounts do not receive Platform Admin access; international transfer stays pending and rejecting preserves owner/data; approving preserves timings/followers/photos/audio.

Old email-OTP endpoints fail closed and ask old APKs to update. Existing stored email OTP records/secrets are not deleted; the new implementation does not read the provider secrets or send OTPs. Existing verified email-OTP owners retain their backend compatibility branch; use Firebase password recovery to establish a password when needed, and keep the corresponding legacy-owner rule branch.
