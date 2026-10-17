# Prayer notification fixes

Changes:
- Android screen on/off events stop the service-owned Azaan player. A local Flutter plugin is registered in the background service engine, independent of MainActivity. No extra permission is requested.
- Settings > Azan sound alarm now persists its value. Turning it off stops current playback; future prayer notifications remain visible without Azaan audio.
- Home has one notification bell per prayer, including Juma. Choices persist on this device across app restarts and masjid changes. Disabled prayers are skipped by both the OS scheduler and background polling; automatic scheduler repair respects the choice.
- Platform admin > open a masjid > Masjid Details now shows its live Followers count, using the same field as the masjid admin. Loading and read errors are shown explicitly.
- Scheduled backup notifications use a new silent channel: audio has one owner and cannot continue separately after pressing Stop.

Build with the existing GitHub Actions workflow. It includes the local plugin and runs the added preference tests. Flutter/Dart and an Android device were unavailable in the editing workspace, so compilation, Flutter tests and device behaviour have NOT been verified here. Source whitespace checks and YAML validation passed for the changed files.

Required device checks before release:
1. Turn Azaan sound off, leave Settings and reopen it; restart the app and confirm it remains off. Trigger a prayer: visual notification should arrive without audio. Re-enable and repeat.
2. Disable Fajr, enable Asr, restart the app and verify both bell states. Trigger each using test prayer times: only Asr should notify. Test Juma on Friday and Dhuhr/Juma replacement behaviour.
3. With Azaan playing, press power while screen is on, then repeat with the screen already off. Check background/locked mode, bundled and custom audio, and Stop during custom audio loading. Verify the next prayer still plays.
4. Check Stop on both notifications and the ringing screen.
5. As platform admin, open masjids with zero and nonzero followers. Compare with masjid admin. A permission error requires reviewing your deployed Firestore rules; no rules were supplied or changed here.
6. Verify layout with and without jamat times, in English/Urdu and on a small screen.

Android limitation: the app observes screen state changes, not the physical power key. Screen timeout, raise-to-wake or another screen wake can also stop active playback. A power press that produces no screen state event cannot be guaranteed. Validate on Samsung S22 Ultra/Android 16 and other supported phones.

The original upload's existing unrelated files and git history are preserved. No release version number was changed; use an unused version code for the next Play upload.
