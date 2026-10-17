# Azaan notification Stop fix

Apply all files in this patch, retaining their folder paths. This patch builds on the previously supplied sound/power-button changes and keeps the existing per-prayer preferences and ownership features.

## What changed
- The local Android plugin manifest now declares flutter_local_notifications' ActionBroadcastReceiver. It is merged into the generated Android app manifest on build.
- Both main and background notification initialization retain the same top-level background Stop callback. The service previously initialized notifications without that callback.
- Stop writes an Android-persisted sequence and broadcasts it to the active service, with the existing foreground-task message as a second path. While audio is active, a 400 ms fallback check catches a missed broadcast. This keeps Stop independent of the UI being open.
- Audio sources are prepared before playback starts. A stop during custom recording loading invalidates that attempt; a late load must not resume playback.
- The foreground service owns the only audio player. The reminder screen no longer has an unused second player.
- The live prayer notification shows the prayer and masjid, clearer expanded text and STOP AZAAN. The active notification becomes a dismissible “Azaan stopped” or “Azaan finished” notice with no Stop action after playback ends.
- The reminder screen has a larger rounded Stop button, a stop icon and a stopping state to prevent repeated taps.
- The persistent service notice is not overwritten by a diagnostic heartbeat during playback.

Android controls the notification action layout; a custom button background/size is not guaranteed there. The app's reminder-screen button is fully styled. The OS may require expanding the notification to show its actions.

## Build and verify
No Firebase function/rules changes are needed for this notification patch. Rebuild the APK through the existing workflow; hot reload alone cannot install the manifest/native plugin changes. Keep packages/azan_screen_events in the project.

Static checks passed: changed-source whitespace checks; Android manifest XML; callback wiring; presence of stop-action receiver; notification sound remains service-controlled; no source .play() calls that start audio during loading. Flutter/Dart and Android device/emulator were unavailable, so this patch has NOT been compiled or validated in a release build here.

Before release, test:
1. Normal prayer and service test alarm: press STOP AZAAN in the prayer notification. Confirm sound ends and notification changes state.
2. Repeat with app in background and phone locked, on Samsung/Android 16 and another supported device.
3. Press Stop immediately while custom audio is loading, including on a slow connection; wait at least 20 seconds and confirm playback does not restart.
4. Repeat using the permanent service notification's Stop action, the app's large Stop button and the power-button screen-state behaviour.
5. Let Azaan finish naturally: no stale active Stop action. The next prayer must still play.
6. Azaan sound off: visual reminder without service audio/Stop action. Per-prayer OFF: no reminder or Azaan.
7. Verify notification and alarm permissions. This fix does not bypass Android permission or battery restrictions.
