# Play Console — Data Safety & Content Rating answers

These are the answers to give, derived from what the code actually does. Google
cross-checks this form against your manifest permissions **and** your privacy
policy. A contradiction between the three is the single commonest cause of
rejection, so these are worded to match the policy exactly.

---

# DATA SAFETY

**Policy → App content → Data safety**

## Section 1: Data collection and security

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** — all Firebase traffic is HTTPS |
| Do you provide a way for users to request that their data is deleted? | **Yes** — by email, stated in the privacy policy |

---

## Section 2: Which data types

Declare **exactly these three**. Nothing else.

### 1. Personal info → Phone number

| Field | Answer |
|---|---|
| Collected | **Yes** |
| Shared | **No** |
| Processed ephemerally | **No** — it is stored |
| Required or optional | **Optional** — only masjid administrators provide it |
| Purpose | **Account management** |

*Why:* `register_masjid_screen.dart` collects a mobile number, verified by SMS,
and it is stored on the masjid document so the person can manage that masjid
later. Ordinary users are never asked.

### 2. Location → Approximate location

| Field | Answer |
|---|---|
| Collected | **Yes** |
| Shared | **No** |
| Processed ephemerally | **YES** — this is the important one |
| Required or optional | **Optional** — the app works if the permission is refused |
| Purpose | **App functionality** |

*Why:* Geolocator reads the position, the app compares it against masjid
coordinates **on the device**, and nothing is uploaded. "Processed ephemerally"
is the correct declaration for exactly this — used in memory, not stored.

**Declare approximate, not precise**, even though the manifest requests
`ACCESS_FINE_LOCATION`. Google asks what you *use*, and a 7 km radius and a qibla
bearing do not need street-level accuracy. If you want the form and the manifest
to agree perfectly, remove `ACCESS_FINE_LOCATION` and keep only
`ACCESS_COARSE_LOCATION` — tell me and I will.

### 3. App activity → Other user-generated content

| Field | Answer |
|---|---|
| Collected | **Yes** |
| Shared | **No** |
| Processed ephemerally | **No** |
| Required or optional | **Optional** |
| Purpose | **App functionality** |

*Why:* masjid administrators post announcements and upload azan audio. That is
user-generated content and must be declared, even though only verified admins can
create it.

---

## What to declare as NOT collected

Say **no** to all of these. Every one is true of your app:

- Name, email address, user IDs, address, race, religious beliefs *(the app never
  asks; following a masjid is not a declaration of belief)*
- Financial info *(the Zakat calculator runs entirely on the device and stores
  nothing — verify: `zakat_service.dart` writes only to SharedPreferences)*
- Health, fitness, messages, contacts, calendar
- Photos, videos, audio files, music *(admins upload azan audio, which is covered
  under user-generated content above)*
- App interactions, in-app search history, installed apps
- Crash logs, diagnostics, performance data *(you have no Crashlytics)*
- Device or other IDs *(the anonymous Firebase UID is not a device ID; it is not
  linked to the device and changes on reinstall)*

**The follower count and the daily active count** do not need declaring. They are
aggregate counters with no user data in them — one number per masjid, one number
per date.

---

# CONTENT RATING

**Policy → App content → Content rating**

Answer the questionnaire. For this app:

| Category | Answer |
|---|---|
| Violence | No |
| Sexuality | No |
| Language | No |
| Controlled substances | No |
| Gambling / contests | No |
| **Users can interact** | **YES** — see below |
| Users can share their location with other users | **No** |
| App shares user-provided personal info with third parties | **No** |
| Digital purchases | No |

## The one question to answer carefully

**"Does the app allow users to interact or exchange content?"** — answer **yes**.

Masjid announcements are content created by one user and shown to others. It
would be inaccurate to say no.

In the explanation field, say plainly:

> Masjid administrators, verified by SMS, can post short text announcements which
> are shown only to users who have chosen to follow that masjid. There is no
> user-to-user messaging, no comments, no public feed, and no way for ordinary
> users to post anything. Announcements expire automatically within one month.

Answering yes with that explanation does **not** raise your age rating. Concealing
it and being found out later does far more damage than declaring it.

Expected result: **Rated for 3+** in most territories.

---

# PERMISSION DECLARATIONS

Two permissions require a written justification.

## SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM

**USE_EXACT_ALARM has been removed from the manifest** (see `build.yml`) - Play
restricts it to apps whose core functionality IS an alarm clock or calendar
app. This app's actual listing - masjid directory, prayer times, Qur'an,
Hadith, duas - does not read as either of those to a reviewer, and claiming
otherwise on the "core functionality" question is a misrepresentation risk far
worse than losing this permission.

If Play Console still asks "What is the core functionality of your app?"
(Alarm clock / Calendar) for an already-uploaded build, that question is about
that build specifically. Once a build without `USE_EXACT_ALARM` is uploaded,
the question should not appear again.

Losing `USE_EXACT_ALARM` has no real functional impact: the app already has a
complete `SCHEDULE_EXACT_ALARM` permission flow (`NotificationService
.openExactAlarmSettings`, surfaced in `setup_wizard_screen.dart` and
`alarm_health_screen.dart`) for exactly this case - it just becomes the path
every user goes through, rather than a rare fallback for the few who did not
qualify for the automatic grant.

`SCHEDULE_EXACT_ALARM` itself is still declared and does need justifying, if
asked, under **App content → Sensitive app permissions**:

> The app sounds the call to prayer (azan) at the exact times published by the
> user's chosen mosque. Prayer times are religious obligations tied to precise
> moments in the day, and an alarm delivered even a few minutes late fails its
> purpose. The user chooses which mosque to follow and can disable alarms at any
> time.

## SYSTEM_ALERT_WINDOW

This is the one that attracts most scrutiny, and **it is worth reconsidering
whether you need it**.

It exists for the full-screen azan overlay. The foreground service now plays the
azan itself and posts a full-screen-intent notification, so the overlay may be
redundant. Test one prayer with it off. If the experience is not noticeably worse,
removing it removes both a review risk and a permission.

If you keep it, justify it as:

> When a prayer time arrives the app shows a full-screen prayer alert with a stop
> control, so the user can silence the call to prayer without unlocking the phone.
> It is shown only at prayer times chosen by the user and never over other apps at
> any other moment.

---

# FOREGROUND SERVICE TYPE JUSTIFICATIONS

**Policy → App content → Declare foreground service permissions** (only appears
for whichever `foregroundServiceType` values are actually declared on the
service in `android/app/src/main/AndroidManifest.xml` — check that file for
the exact list before answering).

## FOREGROUND_SERVICE_MEDIA_PLAYBACK

**Answer: Media playback**

*Why:* This is the whole reason the service exists. `PrayerAlarmTaskHandler`
runs so the azan can play reliably even when the OS would otherwise kill a
plain scheduled alarm (see the class comment in
`foreground_alarm_service.dart`) — `_playAzan` plays the call to prayer
through `audioplayers` with `AndroidUsageType.alarm`. Not picture-in-picture,
nothing else applies.

## FOREGROUND_SERVICE_DATA_SYNC

**You no longer need to answer this question.**

Traced this to the source: `.github/workflows/build.yml` generates
`android/app/src/main/AndroidManifest.xml` fresh on every build (it is not a
committed file - see the "Generate platform folders" step), and two separate
steps in that script write to it:

- The "Add location and notification permissions" step used to add
  `FOREGROUND_SERVICE_DATA_SYNC` as a bare `<uses-permission>`.
- The "Add required foreground service declaration" step attaches
  `android:foregroundServiceType="mediaPlayback"` to the actual `<service>`
  element - `dataSync` was never in that list.

So `dataSync` was declared but never attached to any service - dead weight
in the manifest, not something the app actually does. Removed the line from
the workflow (see the diff to `build.yml`). Once a build runs with that
change, Play Console's declaration form should not ask about
`FOREGROUND_SERVICE_DATA_SYNC` at all, because the permission will no longer
be declared.

---

# APP ACCESS

Play asks whether any part of the app is behind a login. Answer **yes**, and
provide instructions — otherwise the reviewer cannot see the admin side and may
reject for "incomplete functionality".

Give them:

> The masjid administrator area is reached from the "I manage a masjid" option on
> first launch, or Settings → How you use the app.
>
> Access requires a mobile number that is already registered as an administrator
> of a masjid. To review this area, use: **[REGISTER A TEST MASJID AND PUT ITS
> NUMBER HERE]**
>
> All prayer times, Qur'an, Hadith, duas and qibla features are available with no
> login of any kind.

**You must register a real test masjid and give the reviewer its admin number**,
or leave a note that the admin area requires a verified mosque and cannot be
demonstrated. The first is much better.

---

# TARGET AUDIENCE

- **Target age group:** 13+ or 18+. Choose **13 and over**. Selecting "children"
  triggers the Families policy, which brings extra requirements you do not want
  and do not need.
- **Appeals to children?** No.

---

# ONE LAST CROSS-CHECK BEFORE YOU SUBMIT

Read these three side by side and make sure they agree:

1. This form
2. Your privacy policy at the GitHub Pages URL
3. The permission list in your manifest

Specifically, confirm your policy says location is **not stored** — it does — and
that you have therefore ticked **processed ephemerally** on the form. Those two
must match. If they ever stop matching, fix the policy before shipping the change.
