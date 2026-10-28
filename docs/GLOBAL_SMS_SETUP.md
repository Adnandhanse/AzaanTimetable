# Global SMS admin flow

Based on main 73c6535. Copy files to their original repository paths and commit.

## Behaviour
- India stays the default country. All supported selected countries use country code + phone number + Firebase SMS OTP for login, registration and recipient verification during transfer.
- No email/password dialog is used. Email is optional contact information only.
- New registrations still require normal Platform Admin approval. A current owner can transfer directly after the recipient proves their own phone by fresh OTP, exactly as the Indian flow. Takeover requests without current-owner consent still require Platform Admin approval.
- Server validates phone provider, fresh authentication time, matching E.164 number, selected country, current ownership and expected ownership version. Existing masjid timings/photos/followers are preserved.

## Deploy in this order
1. Firebase Authentication > Settings > SMS region policy: retain India and allow intended destination countries; save. Billing and Phone provider must be enabled.
2. Upload this patch and commit. Run **Deploy international admin verification** (`deploy-international-admins.yml`). This existing workflow deploys registration, transfer and compatible reminder services together. Its name remains for compatibility; no email service or email secret is needed.
3. Build and install the APK from the same commit after the deployment is green.
4. Test one real international number with consent: registration OTP, Platform Admin approval, sign-out/sign-in, then recipient OTP and transfer. Confirm the previous owner loses access and prayer times/followers remain.

## Existing email accounts
No Firebase users or masjid ownership records are deleted or automatically reassigned. A legacy email owner with a still-valid session can use Transfer Administration to a separately OTP-verified phone account. If already signed out, the Platform Admin must arrange a verified ownership-transfer request and approve it. A previously unverified contact number must NEVER automatically claim an email-owned masjid. Old email-auth code remains only for existing-record authorization compatibility; the new app does not expose email sign-in. Do not retire a legacy APK/session before moving such an account.

## Validation
33 backend tests passed (identity, registration, direct transfer, pending takeover and reminders), including international phone matching and rejection of email/password/anonymous proofs for new registrations. Changed Dart files passed syntax parsing; whitespace checks passed. Flutter compilation, installed APK, live Firebase permissions and real international SMS delivery have not been verified locally. Allowed SMS regions alone cannot guarantee delivery on every carrier.
