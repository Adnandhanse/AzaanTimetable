# Gemini deployment retry patch

Apply AFTER IslamConnect_Stories_AI_Update.zip. This is a small incremental patch, not a replacement for the earlier story/AI update.

## Files to upload

Replace `functions-ask/check-provider.js`.
Add `functions-ask/test/check-provider.test.js`.
Keep the same folders in the repo. Extract the ZIP first; do not upload the ZIP as a workflow file.

## Then

1. Commit these two files on main.
2. GitHub → Actions → Deploy Ask Islam Connect AI (Gemini / OpenAI).
3. Click **Run workflow**, choose **main**, keep **provider = gemini**, then Run workflow.
4. Start a NEW run. Re-running the old failed run would reuse its old commit.

## Behaviour

The deployment test tries Gemini up to 3 times for timeouts and HTTP 408/500/502/503/504. It waits about 2 seconds before the second try and 5 seconds before the third, with up to half a second of jitter each time.

Each existing Gemini request still has its 25-second timeout. If all three attempts time out, this check can take about 83 seconds before failing. This does not include the rest of the workflow.

Auth/key errors, missing models, 400, quota 429 and malformed output fail immediately. No fallback provider is selected. Runtime question requests and app quotas have not gained retries. The smoke check may consume up to three provider requests per workflow run.

If all attempts fail, deployment STOPS with a clear message; it never marks an unavailable provider as working. This handles temporary failures but cannot guarantee Gemini availability. An already deployed service is not replaced by a run blocked at the check.

Tests use simulated provider failures and injected waits, without live API credentials. A real successful Gemini response must still pass the workflow's check.
