# Both administration transfer scenarios

This cumulative patch includes both ownership flows. Copy its files over the project while preserving paths. Keep the earlier sound/power-button patch, including packages/azan_screen_events.

## Scenario 1: A hands over from A's phone
1. A logs in to Masjid Admin and taps the swap-arrows icon beside the masjid.
2. A enters B's name, 10-digit Indian mobile number and optional email.
3. If A is not already phone-authenticated, verify A's existing mobile first.
4. A sends an OTP to B's phone. With B present and consenting, A enters that OTP on A's device.
5. After verification, A reviews the final confirmation and transfers.
6. The server updates the same masjid's admin fields to B's verified UID/mobile. It records an audit entry. The page returns home and clears the saved admin login. A's Firebase account remains signed in as A; no B login is retained on A's phone. B can later log in on B's own phone with OTP.

No platform approval is needed in this flow because both the current admin's identity and B's phone are verified. Existing followers, prayer times, audio, photos, status and announcements are retained on the original document. If A manages other masjids, those remain A's.

## Scenario 2: A has already left
B uses the existing registration number, selects “previous admin left”, verifies B's mobile and submits a request. Platform Admin verifies the claim and approves/rejects through the Ownership requests button. Refer to OWNERSHIP_TRANSFER_SETUP.md for that flow's rules and allowlist.

## Required one-time Firebase deployment
The direct transfer is deliberately performed by a trusted Cloud Function so B's phone authentication does not replace A's login and clients cannot authorize their own ownership changes.

1. Install Node.js 22 and Firebase CLI on the build/deployment computer, and log in to the correct Firebase project.
2. From the `functions` folder run `npm install` and `npm test`.
3. From the project root deploy the included function, using the actual Firebase project ID:
   `firebase --config firebase.transfer.json deploy --only functions:ownership-transfer --project YOUR_PROJECT_ID`
   The callable is `transferMasjidAdministration` in `us-central1`. The Dart caller uses that region. This separate configuration avoids overwriting an existing firebase.json. If you already have a functions source/codebase, merge carefully rather than replacing your existing functions.
4. Cloud Functions deployment requires an appropriately enabled Firebase project/billing plan. See https://firebase.google.com/docs/functions/get-started . Firebase Phone Auth/SMS must already work for this project, including the release signing fingerprints. The secondary app uses the same Firebase project configuration.
5. Merge and validate the Firestore ownership rules from the previous setup. The Cloud Function uses Admin SDK transactions; no client permission to directly change admin fields is needed for the direct flow. Normal masjid admin writes MUST require the current `adminUid` on transferred masjids and exclude admin/audit fields. Without those restrictions, an old app/client could bypass the intended access removal. Existing broad allow-write rules must be removed or narrowed. Keep follower count updates separately constrained.
6. Deny client writes to `masjids/{masjidId}/ownershipHistory/{transferId}`. If audit reads are needed, allow only the platform admin. Do not place tokens or OTPs in documents/logs. The function never stores them.
7. Run `flutter pub get` and build via the existing workflow. The patch adds `cloud_functions` to pubspec.yaml.

The APK alone does not deploy the function or rules. Do those before testing the feature. This workspace did not have your live Firebase deployment permissions or deployed rules, so no remote configuration was changed.

## Verification before release
- A transfers to B with B's OTP, using both a legacy masjid without adminUid and one with adminUid. Confirm the original document ID, followers, timings, photo/audio URLs and announcements are unchanged.
- Confirm A stays A throughout B's OTP step; the primary auth session must never become B. On completion the temporary B session is signed out/deleted.
- Verify OTP errors, resend, back/cancel before final confirmation, network failure and retry. A cancelled or failed verification/confirmation must not transfer anything. The function uses an operation ID to avoid duplicate committed transfers on network retry.
- Confirm A loses server-side editing rights, including already-open screens; B can sign in on another phone and manage the original masjid.
- Try wrong A, wrong B, self-transfer, expired verification and concurrent ownership changes: reject all. Pending takeover requests from the earlier owner must be rejected as stale after a direct handover.
- Test scenario 2 still requires platform approval and retains the same data.

## Validation performed here
Four Node unit tests passed for ownership authorization, legacy ownership, data preservation, recipient phone/freshness, self-transfer and stale ownership. Node syntax checks passed. Source whitespace and YAML/JSON validation passed. Flutter compilation, deployed callable integration, rules/emulator validation and physical-device OTP tests have NOT run in this workspace.
