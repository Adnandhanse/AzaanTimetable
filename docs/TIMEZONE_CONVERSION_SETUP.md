# Masjid timezone conversion

## Apply
This patch is based on the available app checkout b69e2c1 (plus the existing AI/daily-content edits). It includes only new/changed files, at their original paths. Copy into the app repository. If your repository has newer edits in these files, merge instead of replacing those edits.

The only dependency addition is `lat_lng_to_timezone: 0.2.0` under dependencies. The full pubspec.yaml is included for convenience; retain any newer dependency/asset changes in your repository. No Firebase deployment or rules changes are required. No existing masjid documents or user data are rewritten.

Run:
```
flutter pub get
flutter analyze
 dart run test/masjid_clock_regression.dart
flutter build apk --release
```
Commit the generated pubspec.lock after dependency resolution if your app tracks it. Install the APK and open Home online once: old schedule caches contain no mosque timezone and are deliberately not used for alarms until refreshed from the mosque document. Do not clear app data.

## Root cause
The old code parsed mosque wall-clock times with DateTime(year, month, day, hour, minute), then scheduled them in tz.local. The foreground isolate independently compared these same strings against the phone's local clock. Both paths therefore fired at the follower's clock time instead of the mosque's instant. Home's countdown made the same assumption. Extra alarms also used +24 hours and did not suppress Friday Dhuhr consistently.

## Changes
- Resolve an IANA timezone offline from the mosque's stored latitude/longitude. Do not use the admin's mobile country or the follower's location.
- Persist the resolved timezone in the local schedule cache and foreground task data.
- Schedule OS notifications in the mosque timezone; use that timezone for the foreground service's date, weekday and alarm matching.
- Construct each day's additional alarms from calendar components, allowing 23/25 hour DST days.
- Juma and Dhuhr replacement use mosque Friday, including when the follower is on a different calendar day. Dhuhr uses six weekly recurrences when Juma exists, avoiding a repeating Friday Dhuhr.
- Convert Home, next-prayer countdown, next-prayer Jamat and full schedule to device local time. Mosque detail and admin editors retain mosque-local input; detail now explicitly labels this.
- Include mosque coordinates and device offset in Home's rescheduling signature.
- Missing/invalid mosque coordinates stop scheduling instead of guessing; switching to an invalid location cancels old mosque alarms.

Example: Riyadh 10:00 AM is India 12:30 PM on the same day. A New York late-night prayer can occur the next morning in India. The alarm follows the same instant, not the same clock numeral.

## Actual validation
- Dart 3.13.7 parser/formatter accepted all changed Dart files.
- Executed 31 production-helper regression assertions using timezone 0.9.4 and lat_lng_to_timezone 0.2.0: Mumbai, Riyadh, London, New York, Sydney lookup; AM/PM; invalid strings/coordinates; cross-date conversion; mosque Friday versus follower Thursday; Dhuhr suppression/fallback; DST spring/autumn; past-time rollover.
- Dart analyzer: no issues in production MasjidClock helper and its regression test.
- Full Flutter analysis, Android compilation, real notification delivery and Samsung background/reboot tests were NOT run: Flutter/Android SDK are unavailable here. Do not treat this ZIP as a tested APK.

## Required device checks before release
1. Existing India masjid: same clock time as before; toggles and Stop Azan still work.
2. International masjid with correct coordinates: compare converted Home time with the same instant on two phones in different timezones.
3. Set test times a few minutes ahead; test both foreground polling and OS notifications, including screen locked and after reboot.
4. Test Juma when source Friday differs from follower Thursday/Saturday; ensure no Friday Dhuhr when Juma exists.
5. Change followed mosque and phone timezone; open Home; verify the schedule and no previous-mosque alarms remain.
6. Upgrade with an existing cache and open online once; verify cache refresh and offline restart.
7. Review missing/incorrect mosque locations. Confirm timezone for border regions.

## Limits
The offline coordinate mapper uses geographic boundaries from a third-party package. Its map can be approximate near boundaries or outdated when borders change. Five city lookups do not establish worldwide boundary correctness. The timezone offset/DST rules come from this app's existing timezone 0.9.4 database; keep it maintained in a separately tested dependency update. This patch adds no map-correction UI. A mosque's stored coordinates must be correct.

Android force-stop, notification/exact-alarm permissions and OEM battery restrictions still apply. Existing native versus foreground duplicate-delivery behavior has not been independently validated by these mathematical tests. No new server refresh mechanism is introduced for prayer times changed while a device remains offline. Home/full schedule show the next occurrence's local clock time; detailed date labels for every row are not added.
