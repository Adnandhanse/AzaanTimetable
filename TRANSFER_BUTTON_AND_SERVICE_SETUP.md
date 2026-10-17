# Transfer button and missing-service error

## Apply the app changes
Replace the included Dart files in their existing folders and rebuild the APK. The admin dashboard now has a full-width Transfer Administration button below each masjid. Platform Admin has a labelled Review Ownership Requests button. The transfer page displays a readable inline failure message rather than exposing a Firebase stack trace. Verified recipient details stay on the page so the same operation can be retried.

## Why the screenshot shows NOT_FOUND
The app calls `transferMasjidAdministration` in `us-central1` in its default Firebase project. The bundled google-services.json identifies that project as `actual-masjid-prayer-time`. The included function export and Dart region/name match.

The uppercase NOT_FOUND in the screenshot is consistent with the endpoint not being deployed in the selected project/region. A function can also deliberately return not-found for a deleted masjid, so confirm the deployment and logs rather than assuming the screenshot proves the exact cause. The included backend uses the clearer message “Masjid not found.” for that case.

An APK build does NOT deploy Firebase functions. Updating the Dart error text does NOT restore a missing backend. A successful transfer requires the deployment below and the Firestore ownership protections from the earlier patch. This workspace had no connected deployment credentials; no cloud deployment has been performed or verified here.

## Option A — deploy using GitHub Actions
1. Copy all files in this ZIP into the repository, preserving folder paths. It includes the existing transfer backend and a new manual workflow.
2. In the correct Google/Firebase project, obtain service-account deployment credentials using your existing deployment process. The account must be authorized to deploy Firebase Functions and use the runtime service account. Keep the JSON key out of the repository.
3. In GitHub: repository Settings > Secrets and variables > Actions > New repository secret. Name: `FIREBASE_DEPLOY_CREDENTIALS`. Value: that service-account JSON.
4. In Actions, select “Deploy ownership transfer service” > Run workflow. It installs dependencies, runs the transfer validation tests, deploys the ownership codebase and lists deployed functions. A missing secret stops the workflow with a readable instruction. This workflow runs manually; it is separate from the APK build.
5. Check the deploy step succeeded and the function list shows `transferMasjidAdministration` in `us-central1`, in project `actual-masjid-prayer-time`.
6. Install the rebuilt APK and test the transfer again. If B's OTP verification is older than ten minutes, verify again first.

Use a project already enabled for Cloud Functions deployment and its required billing plan. This patch does not change billing or project configuration.

## Option B — deploy from a computer
Use Node.js 22. Open a terminal at the repository root and run:

    npm --prefix functions install
    npm --prefix functions test
    npx --yes firebase-tools@14 login
    npx --yes firebase-tools@14 --config firebase.transfer.json deploy --only functions:ownership-transfer --project actual-masjid-prayer-time
    npx --yes firebase-tools@14 functions:list --project actual-masjid-prayer-time

If a different Firebase project is intentional, change both the app configuration and the deployment project together. If you deliberately deploy to a different region, change both the function region and DirectOwnershipTransfer.functionRegion. Do not create duplicate endpoints in random regions to hide the error.

## Test before release
- A's labelled transfer button opens the correct masjid.
- Verify B's mobile, confirm, and check the original masjid document changes only admin/audit details. Followers, times, photos/audio and announcements stay unchanged.
- Confirm old-admin writes are denied by the deployed Firestore rules and B can sign in and manage the original masjid.
- Missing service, expired OTP and network failure show readable messages without a stack trace. On an uncertain network result, retry on the same page; the operation ID protects the existing committed handover.
- The B-request/platform-approval scenario remains available under Review Ownership Requests.

Validation here: four existing backend unit tests passed; JavaScript syntax, JSON/YAML and source-whitespace checks passed. Flutter compilation and live function/rules/phone integration were not available here.

Official references:
https://firebase.google.com/docs/functions/callable
https://firebase.google.com/docs/functions/locations
https://firebase.google.com/docs/functions/get-started
