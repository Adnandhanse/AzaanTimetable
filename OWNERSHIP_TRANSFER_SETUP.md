# Administration handover — same masjid, same data

## What changed
B uses registration with the same registration number and selects “previous admin left”. After OTP verification, the app creates an ownership request, NOT a new masjid. Platform Admin has a new swap-arrows button in the top bar to review requests. Approval atomically updates only admin name, mobile, email and authenticated UID on the ORIGINAL masjid document and completes the request. The ID, followers, prayer times, announcements, photo/audio URLs, verification status and all other fields remain untouched. Rejecting leaves ownership unchanged. Until approval, A remains the admin. Once approved, B logs in with the new mobile number. The existing admin dashboard query then shows the original masjid to B and no longer to A.

Requests remember the original mobile and UID. If someone else transfers ownership first, a stale request cannot overwrite that transfer. Retrying an already-pending request does not create another request. Matching registrations in any verification status go through this path. Multiple old masjid documents with the same number are blocked for manual resolution; this feature does not merge existing duplicates or follower counts.

## Required Firebase setup BEFORE releasing
1. In Firebase Authentication, copy the UID of your existing platform admin email/password account.
2. In Firestore Console, create `platformAdmins/<that UID>` with boolean `enabled: true`. Do not give clients write access to this collection.
3. Merge `firebase_config/ownership_transfer/rules.fragment.txt` into your current Firestore rules. It is a fragment, not a full deployable ruleset. The existing deployed rules were not included in the uploaded project and have not been modified remotely.
4. Add `approvedAdminTransfer(masjidId)` as an allowed update in your masjids rule. Restrict ALL other admin update paths so ordinary users cannot change admin fields. For a transferred masjid, normal administrative writes must require its `adminUid` to match the authenticated UID. Ensure existing follower-counter updates still have their own restricted rule.
5. Verify the new rules in Firebase Emulator/Rules Playground, including denial cases below, then deploy. Rules are additive: a broad existing allow-write grant defeats the new restrictions.

Masjid admin login now requires OTP unless the matching phone is already authenticated. Saved mobile numbers alone do not restore access. OTP auto-verification checks the exact requested phone, and phone-authenticated masjid users no longer qualify as platform admin email/password sessions. New masjids also store `adminUid` for server-side ownership checks. Existing masjids without this field remain compatible; after transfer it is set to B's verified UID.

## Validation before release
- Register B with A's masjid registration number, verify B's OTP, and submit. Confirm no new masjid document, no admin change, no changed public status or follower count.
- Verify the new admin's OTP, not merely an existing signed-in account. The repository checks the authenticated phone against B's mobile.
- Approve as allowlisted platform admin. Compare all original masjid fields/subcollections: only admin and audit fields may differ. Confirm followed users still see the same masjid and notifications.
- Confirm B can edit times and A is denied even from an old open edit screen. Confirm follower counters still work.
- Reject a second request: no masjid changes. Test two pending requests for one masjid: after approving one, the other must fail approval as stale.
- Deny: anonymous requests; spoofed phone/UID; requester approving own request; non-allowlisted phone/email user approving; direct writes to admin details; request approval without the matching masjid update; rewriting audit fields.
- Keep unrelated registration/photo/prayer flows working. Existing duplicate records need manual investigation, not deletion by this patch.

## Limits
Flutter/Dart and a Firebase emulator/device were unavailable here. The patch has source/diff checks but has NOT been compiled or tested on a device or against your live rules. Registration-number lookups compare trimmed text exactly, including letter case. The legacy random-ID new registration flow still has a concurrency gap if two entirely new registrations with the same number are submitted simultaneously; centralized registration-number reservation would be needed to guarantee uniqueness across old/new clients. This transfer fix never intentionally creates a replacement masjid for a matched number.
