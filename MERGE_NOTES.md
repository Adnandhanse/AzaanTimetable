# Illuminated UI merge — what changed

Merged into your `AzaanTimetable` repo. This was a restyle, not a rewrite: no
logic, no data layer, no service, no model was touched.

## Files added (2)

    lib/theme/app_theme.dart      palette, three type families, type scale
    lib/widgets/ornaments.dart    girih pattern, arch header, rules, medallions

Everything decorative is drawn with `CustomPainter` — the eight-point star
watermark, the arch, the dome, the octagon medallions, the compass dial and the
Kaaba glyph. No new package, no new image asset, nothing added to
`dependencies:`. If CI fails on this commit it will not be a plugin.

## Files changed (7)

    pubspec.yaml                        commented Cormorant block only
    lib/main.dart                       theme swapped for AppTheme.light()
    lib/screens/home_screen.dart        presentation replaced, logic intact
    lib/screens/quran_home_screen.dart  presentation replaced, logic intact
    lib/screens/hadith_home_screen.dart presentation replaced, logic intact
    lib/screens/qibla_screen.dart       presentation replaced, logic intact
    lib/screens/prayers_home_screen.dart presentation replaced, logic intact

## Files deliberately NOT touched

All 48 other files in `lib/`. Notably every service, every model,
`overlay_main.dart`, the whole admin flow, `azan_ringing_screen`,
`splash_screen`, `settings_screen`, and the CI workflow.

## The thing to be careful about

`_maybeScheduleNotifications` is called from inside Home's `StreamBuilder`.
Alarm scheduling hangs off the Home build path — if Home stops calling it,
prayer alarms silently stop being scheduled and nothing in the UI tells you.
It's preserved exactly, with a comment above it saying so. Don't refactor Home
without re-reading that comment.

Same for the exact-alarm permission banner, the `_lastScheduledSignature`
de-duplication, `_parseTimeToday`, `_nextPrayer`, the masjid `StreamBuilder`,
the change-masjid FAB and the five-tab routing. All unchanged in behaviour.

On Qibla: the bearing maths, the great-circle distance, the `FlutterCompass`
stream, the counter-rotating dial and the 5° alignment threshold are all
untouched. Only the painting changed.

On Quran: `TabController`, the three-language popup, favourites persistence and
the juz list all behave as before.

## What you'll see that's different

Home now leads with an arch-and-dome header carrying the masjid name and the
Hijri date, then the next prayer time as a large serif figure between two
ornamented gold rules, then the six times as a hairline-ruled list with Arabic
names in the middle column. The live ticking HH:MM:SS clock is gone — the
countdown reads in hours and minutes, because the exact second isn't useful and
was the noisiest thing on the screen. The 1-second timer is still there, so if
you want seconds back it's a one-line change in `_countdownLabel`.

Hadith keeps the two-column grid you already had, now with numbered medallions,
Arabic titles and volume counts. Volume counts and Arabic names live in a
private map at the top of the screen file, not in the model, so `hadith.dart`
didn't need changing.

Qibla is now light instead of dark green, with a gold dial drawn in code.

## Three images are now unused

    assets/images/mosque_header.jpg
    assets/images/quran_artwork.jpg
    assets/images/kaaba_qibla.jpg

Nothing in `lib/` references them any more. I left them in place and left them
declared in `pubspec.yaml`, because deleting files is your call, not mine.
Removing all three saves about 368 KB. That's noise next to the 94 MB of Hadith
JSON, which is still the only thing that actually matters for your app size.

## The display face

The UI uses `'serif'` — Android's built-in Noto Serif — so this builds today with
nothing added. It looks good. Cormorant Garamond looks better.

To upgrade: drop `CormorantGaramond-Regular.ttf` and
`CormorantGaramond-SemiBold.ttf` into `assets/fonts/`, uncomment the block at
the bottom of `pubspec.yaml`, and change `AppFonts.serif` in
`lib/theme/app_theme.dart` from `'serif'` to `'Cormorant'`. All three, or none.

One caveat on Inter: it's bundled as a variable font declared without weights,
so the `w500` in the type scale will be synthesised rather than a real weight.
It's fine, but if the small caps labels ever look slightly off, that's why.

## Not compile-checked

There's no Flutter toolchain where I did this work, so these files have not been
compiled. I stayed on APIs stable in 3.24 and checked for dangling references
from the methods I removed, but the first CI run is the real test. Send me the
log if it complains.

## Security

Your zip included `android_keystore/release.keystore` and
`firebase_config/google-services.json`. I left both where they were, since your
build needs them. The `google-services.json` is client-side config and isn't
really a secret. The keystore is your app signing key and has now travelled
through a chat — if you haven't published to Play yet, generate a fresh one and
keep it out of the repo.
