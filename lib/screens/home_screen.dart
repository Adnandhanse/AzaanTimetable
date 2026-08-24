import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hijri/hijri_calendar.dart';
import '../models/masjid.dart';
import '../services/masjid_repository.dart';
import '../services/user_repository.dart';
import '../services/notification_service.dart';
import '../services/announcement_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/foreground_alarm_manager.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';
import '../widgets/daily_hadith_card.dart';
import '../widgets/artwork_header.dart';
import '../widgets/sky_artwork.dart';
import 'masjid_search_screen.dart';
import 'prayer_times_screen.dart';
import 'settings_screen.dart';
import 'hijri_calendar_screen.dart';
import 'role_selection_screen.dart';
import 'setup_wizard_screen.dart';
import 'quran_home_screen.dart';
import 'hadith_home_screen.dart';
import 'prayers_home_screen.dart';
import 'qibla_screen.dart';
import 'admin_login_screen.dart';

/// Arabic prayer names for the gold middle column. Deliberately separate from
/// S.*: those return English or Urdu depending on the language toggle, and this
/// column is always Arabic script whatever the app language.
const Map<String, String> _arabicPrayerNames = <String, String>{
  'fajr': 'الفجر',
  'dhuhr': 'الظهر',
  'asr': 'العصر',
  'maghrib': 'المغرب',
  'isha': 'العشاء',
  'juma': 'الجمعة',
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// Drives the one-off entrance animation: the artwork settles and the
  /// content below it fades and slides up. Runs once on open, not on every
  /// rebuild - the 1-second clock timer would otherwise restart it 60 times a
  /// minute.
  late final AnimationController _intro;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  String? _selectedMasjidId;
  bool _loading = true;
  String? _lastScheduledSignature;
  bool _exactAlarmWarningDismissed = false;
  bool? _hasExactAlarmPermission;
  bool? _hasBatteryExemption;

  /// True only when the user said they manage a masjid.
  ///
  /// The Masjid Admin tab used to be shown to everyone. Having asked whether
  /// someone runs a masjid, showing them an admin login anyway makes the
  /// question pointless — and for the overwhelming majority it is a permanent
  /// tab they will never open.
  bool _isAdmin = false;

  /// Live announcements for the followed masjid. Held in state rather than
  /// rendered inline, because the banner icon needs the count and the sheet
  /// needs the list.
  List<Announcement> _announcementList = const <Announcement>[];
  StreamSubscription<List<Announcement>>? _announcementSub;

  /// Drives the header parallax.
  ///
  /// Depth on a phone comes from things moving at different rates, not from
  /// perspective transforms. A photograph that drifts slower than the text over
  /// it reads as being further away, and costs nothing in legibility or battery
  /// — which literal 3D on a reading screen would.
  final ScrollController _scroll = ScrollController();

  /// One icon per prayer, in the same order as the rows.
  /// Splits "5:40 PM" into ("5:40 pm", "") — lowercased meridiem, single space.
  ///
  /// Uppercase "PM" in the same weight as the digits takes as much width as an
  /// extra digit and reads as loudly. Lowering it buys back the room that made
  /// the times truncate.
  static (String, String) _splitTime(String t) {
    final parts = t.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return (t.trim(), '');
    return ('${parts[0]} ${parts[1].toLowerCase()}', '');
  }

  /// The Arabic name for a prayer label, for the next-prayer block.
  static String _arabicFor(String label) {
    if (label == S.fajr) return _arabicPrayerNames['fajr']!;
    if (label == S.dhuhr) return _arabicPrayerNames['dhuhr']!;
    if (label == S.asr) return _arabicPrayerNames['asr']!;
    if (label == S.maghrib) return _arabicPrayerNames['maghrib']!;
    if (label == S.isha) return _arabicPrayerNames['isha']!;
    return _arabicPrayerNames['juma']!;
  }

  /// The jamat time for a prayer, or empty if this masjid has not set one.
  static String _jamatFor(Masjid m, String label) {
    final t = m.prayerTimes;
    if (label == S.fajr) return t.fajrJamat.trim();
    if (label == S.dhuhr) return t.dhuhrJamat.trim();
    if (label == S.asr) return t.asrJamat.trim();
    if (label == S.maghrib) return t.maghribJamat.trim();
    if (label == S.isha) return t.ishaJamat.trim();
    if (label == S.juma) return t.jumaJamat.trim();
    return '';
  }

  /// The icon for a prayer label, for the next-prayer card - matches
  /// _prayerIcons' order without hardcoding an index at the call site.
  static IconData _iconFor(String label) {
    if (label == S.fajr) return _prayerIcons[0];
    if (label == S.dhuhr) return _prayerIcons[1];
    if (label == S.asr) return _prayerIcons[2];
    if (label == S.maghrib) return _prayerIcons[3];
    if (label == S.isha) return _prayerIcons[4];
    return _prayerIcons[5];
  }

  static const List<IconData> _prayerIcons = <IconData>[
    Icons.wb_twilight,        // Fajr
    Icons.wb_sunny_outlined,  // Dhuhr
    Icons.wb_sunny,           // Asr
    Icons.wb_twilight,        // Maghrib
    Icons.nightlight_round,   // Isha
    Icons.groups_outlined,    // Juma
  ];
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.045),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic));
    _intro.forward();
    // Re-check the alarms whenever the app comes back to the foreground.
    WidgetsBinding.instance.addObserver(this);
    _loadSelectedMasjid();
    _loadRole();
    _repairAlarmsIfNeeded();

    // After the first frame, so the card appears over a drawn home screen
    // rather than over an empty one — and so a slow Firestore read cannot delay
    // it. Shows once a day; the check is inside.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) DailyHadithCard.maybeShow(context);
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) _repairAlarmsIfNeeded();
  }

  /// Ask the OS what it still holds and re-arm anything missing. Alarms vanish
  /// for reasons the app cannot see — a force-stop, an OEM cleanup, a reboot.
  /// Checking on every resume turns a silent failure into a self-repair.
  Future<void> _repairAlarmsIfNeeded() async {
    try {
      final repaired = await NotificationService.verifyAndRepair();
      if (repaired) {
        // Also refresh the permission state, since a wipe is often the
        // fingerprint of the app having been frozen or force-stopped.
        final granted = await NotificationService.hasExactAlarmPermission();
        final exempt = await NotificationService.hasBatteryExemption();
        if (mounted) {
          setState(() {
            _hasExactAlarmPermission = granted;
            _hasBatteryExemption = exempt;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _announcementSub?.cancel();
    _scroll.dispose();
    _clockTimer.cancel();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedMasjid() async {
    try {
      final id = await UserRepository.getSelectedMasjidId();
      if (!mounted) return;
      setState(() {
        _selectedMasjidId = id;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load your followed masjid: $e')),
      );
    }
  }

  void _watchAnnouncements(String masjidId, String masjidName) {
    if (_watchedMasjidId == masjidId) return;
    _watchedMasjidId = masjidId;
    _announcementSub?.cancel();
    _announcementSub =
        AnnouncementRepository.streamActive(masjidId, masjidName).listen((list) {
      if (!mounted) return;
      setState(() => _announcementList = list);
      _notifyNewAnnouncements(list, masjidName);
    });
  }

  String? _watchedMasjidId;

  Future<void> _loadRole() async {
    final role = await RoleSelectionScreen.savedRole();
    if (!mounted) return;
    setState(() => _isAdmin = role == 'admin');
  }

  Future<void> _openDirections(Masjid masjid) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${masjid.latitude},${masjid.longitude}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps app.')),
        );
      }
    }
  }

  /// Alarm scheduling hangs off the Home build path. Do not remove this call or
  /// move it behind a condition — if Home stops calling it, prayer alarms
  /// silently stop being scheduled and nothing in the UI will tell you.
  void _maybeScheduleNotifications(Masjid masjid) {
    final t = masjid.prayerTimes;
    final signature =
        '${masjid.id}|${t.fajr}|${t.dhuhr}|${t.asr}|${t.maghrib}|${t.isha}|${t.juma}';
    if (signature == _lastScheduledSignature) return;
    _lastScheduledSignature = signature;
    _scheduleAndCheckPermission(masjid);
  }

  Future<void> _scheduleAndCheckPermission(Masjid masjid) async {
    try {
      await NotificationService.scheduleForMasjid(masjid);
      await ForegroundAlarmManager.startOrUpdate(masjid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not schedule prayer alarms: $e')),
        );
      }
    }
    final granted = await NotificationService.hasExactAlarmPermission();
    final exempt = await NotificationService.hasBatteryExemption();
    if (mounted) {
      setState(() {
        _hasExactAlarmPermission = granted;
        _hasBatteryExemption = exempt;
      });
    }
  }

  DateTime? _parseTimeToday(String timeStr) {
    if (timeStr.trim() == '--:--' || timeStr.trim().isEmpty) return null;
    try {
      final parts = timeStr.trim().split(' ');
      final hm = parts[0].split(':');
      int hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      final isPM = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      final isAM = parts.length > 1 && parts[1].toUpperCase() == 'AM';
      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0;
      return DateTime(_now.year, _now.month, _now.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Returns (label, DateTime) for the next upcoming prayer today, or
  /// tomorrow's Fajr if all of today's have passed.
  /// The prayer that comes soonest.
  ///
  /// THIS USED TO PICK THE FIRST FUTURE PRAYER IN LIST ORDER, NOT THE EARLIEST.
  ///
  /// It walked Fajr, Dhuhr, Asr, Maghrib, Isha and returned the first whose
  /// time had not yet passed — which is only correct if the stored times happen
  /// to be in chronological order. With Fajr at 6:35 PM and Asr at 5:40 PM it
  /// checked Fajr first, saw a future time, and stopped without ever looking at
  /// Asr, which was sooner.
  ///
  /// Now every prayer's next occurrence is computed and the minimum wins, so
  /// list order cannot affect the answer. That also removes the need for the
  /// old special case that hard-coded "otherwise, tomorrow's Fajr": once each
  /// prayer knows its own next occurrence, after Isha it is simply Fajr's turn
  /// that is nearest.
  (String, DateTime)? _nextPrayer(Masjid masjid) {
    final entries = <(String, String)>[
      (S.fajr, masjid.prayerTimes.fajr),
      (S.dhuhr, masjid.prayerTimes.dhuhr),
      (S.asr, masjid.prayerTimes.asr),
      (S.maghrib, masjid.prayerTimes.maghrib),
      (S.isha, masjid.prayerTimes.isha),
    ];

    (String, DateTime)? best;
    for (final (String label, String timeStr) in entries) {
      final DateTime? today = _parseTimeToday(timeStr);
      if (today == null) continue;

      // Today if it is still to come, otherwise the same time tomorrow.
      final DateTime when = today.isAfter(_now)
          ? today
          : today.add(const Duration(days: 1));

      if (best == null || when.isBefore(best.$2)) {
        best = (label, when);
      }
    }
    return best;
  }

  /// Tapping the date opens the calendar.
  ///
  /// It used to open an alert dialog stating today's Hijri date — which the
  /// banner was already showing directly above the thing you tapped. Now it
  /// answers the questions a date makes you ask: when is the 15th, how far away
  /// is Ramadan.
  void _showHijriInfo() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HijriCalendarScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hijri = HijriCalendar.now();
    return Scaffold(
      body: Column(
        children: [
          // Anything here being off means a prayer alarm can silently fail to
          // fire. Both are surfaced, not just the exact-alarm one — battery
          // restriction is the more common cause on Indian handsets, and it
          // used to be buried in Settings where nobody found it.
          if (!_exactAlarmWarningDismissed &&
              (_hasExactAlarmPermission == false ||
                  _hasBatteryExemption == false))
            Material(
              color: AppColors.warningBg,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.warning_amber,
                            color: AppColors.warningFg, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prayer alarms may not fire',
                              style: AppText.rowTitle.copyWith(
                                  fontSize: 15, color: AppColors.warningFg),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _hasExactAlarmPermission == false &&
                                      _hasBatteryExemption == false
                                  ? 'Two settings still need your permission.'
                                  : _hasBatteryExemption == false
                                      ? 'Battery saver can freeze the app and stop alarms.'
                                      : '"Alarms & reminders" is off for this app.',
                              style: AppText.caption.copyWith(
                                  fontSize: 12.5, color: AppColors.warningFg),
                            ),
                            const SizedBox(height: 4),
                            // One button to the full wizard, rather than a
                            // separate Fix per line. The inline buttons sent
                            // people to individual system screens with no
                            // explanation of what they were looking at; the
                            // wizard walks all four in order and shows which
                            // are done.
                            TextButton(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SetupWizardScreen(
                                      onFinished: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ),
                                );
                                final g = await NotificationService
                                    .hasExactAlarmPermission();
                                final e = await NotificationService
                                    .hasBatteryExemption();
                                if (mounted) {
                                  setState(() {
                                    _hasExactAlarmPermission = g;
                                    _hasBatteryExemption = e;
                                  });
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.warningFg,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text('Fix this now',
                                  style: AppText.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.warningFg)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: AppColors.warningFg,
                        onPressed: () =>
                            setState(() => _exactAlarmWarningDismissed = true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _selectedMasjidId == null
                    ? _buildNoMasjidSelected()
                    : StreamBuilder<Masjid?>(
                        stream: MasjidRepository.streamById(_selectedMasjidId!),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final masjid = snapshot.data;
                          if (masjid == null) return _buildNoMasjidSelected();
                          _maybeScheduleNotifications(masjid);
                          return _buildIlluminatedHome(masjid, hijri);
                        },
                      ),
          ),
        ],
      ),
      // No "Change Masjid" button. The Nearby masjid quick action already
      // opens the same search and sets the same selection, and a floating
      // button was covering the last row of prayer times to do it twice.
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.goldRule)),
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.emerald,
          unselectedItemColor: AppColors.navInactive,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          onTap: (index) {
            if (index == 1) {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuranHomeScreen()));
            } else if (index == 2) {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HadithHomeScreen()));
            } else if (index == 3) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const PrayersHomeScreen()));
            } else if (index == 4 && _isAdmin) {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
            }
          },
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined, size: 20),
                label: S.prayerTime),
            BottomNavigationBarItem(
                icon: const Icon(Icons.menu_book_outlined, size: 20),
                label: S.quran),
            BottomNavigationBarItem(
                icon: const Icon(Icons.auto_stories_outlined, size: 20),
                label: S.hadith),
            BottomNavigationBarItem(
                icon: const Icon(Icons.explore_outlined, size: 20),
                label: S.prayers),
            // Admins only. Four tabs for everyone else.
            //
            // The role question is asked at first launch; showing an admin
            // login to someone who said they are not an admin makes the question
            // pointless. Changeable any time from Settings.
            if (_isAdmin)
              BottomNavigationBarItem(
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                  label: S.masjidAdmin),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMasjidSelected() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Medallion(icon: Icons.mosque_outlined, size: 52),
            const SizedBox(height: 16),
            Text(
              S.noMasjidSelected,
              textAlign: TextAlign.center,
              style: AppText.body
                  .copyWith(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            // THE ONLY WAY OUT OF THIS SCREEN.
            //
            // This state had no button at all. The floating "Change Masjid"
            // button used to be the only route to the search, and removing it
            // left a brand-new user staring at an icon and a sentence with
            // nothing to tap — the app was unusable from a fresh install.
            //
            // The button belongs here, not floating over a list that does not
            // exist yet.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.place_outlined, size: 18),
                label: Text(S.nearbyMasjid),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  textStyle: AppText.body,
                ),
                onPressed: () async {
                  final result = await Navigator.of(context).push<Masjid>(
                    MaterialPageRoute(builder: (_) => const MasjidSearchScreen()),
                  );
                  if (result != null) {
                    await UserRepository.setSelectedMasjid(result.id);
                    if (mounted) setState(() => _selectedMasjidId = result.id);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIlluminatedHome(Masjid masjid, HijriCalendar hijri) {
    final next = _nextPrayer(masjid);
    // Start listening once we know which masjid is followed.
    _watchAnnouncements(masjid.id, masjid.name);

    return SingleChildScrollView(
      controller: _scroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The photograph drifts at 40% of scroll speed and eases fractionally
          // wider, so it sits behind the content rather than being pinned to
          // it. Clipped, so the slower drift never opens a gap at the bottom.
          ClipRect(
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_intro, _scroll]),
              builder: (context, child) {
                final double o =
                    _scroll.hasClients ? _scroll.offset.clamp(0.0, 400.0) : 0.0;
                return Transform.translate(
                  offset: Offset(0, o * 0.4),
                  child: Transform.scale(scale: 1 + o / 3000, child: child),
                );
              },
              child: AnimatedBuilder(
                animation: _intro,
                builder: (context, _) => ArtworkHeader(
              masjidName: masjid.name,
              // Address on the first line, date on the second. Two lines beat
              // one long dotted string once the address is in there — most
              // masjid addresses are too long to sit beside a date.
              metaLine: '${masjid.address.trim().isEmpty ? masjid.city : '${masjid.address}, ${masjid.city}'}\n'
                  '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH',
              phase: _skyPhase(masjid),
              settle: _fade.value,
              onDirectionsTap:
                  (masjid.latitude != 0.0 || masjid.longitude != 0.0)
                      ? () => _openDirections(masjid)
                      : null,
              announcementCount: _announcementList.length,
              onAnnouncementsTap: _announcementList.isEmpty
                  ? null
                  : () => _showAnnouncements(_announcementList, masjid.name),
              onSettingsTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              onMetaTap: _showHijriInfo,
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
          // Compact. This block was two ornamented rules around a 44pt figure
          // with generous spacing, which pushed the prayer list below the fold.
          // One rule, a smaller figure, and the name and countdown on the same
          // line as before — the information is identical, the height is about
          // half.
          // NO ANNOUNCEMENT CARD HERE ANY MORE.
          //
          // It was a full-width card between the banner and the prayer times —
          // the busiest possible place to put anything, and it pushed the
          // prayer list down the screen on every launch whether or not there
          // was anything worth reading.
          //
          // It is now an icon with a count under the settings button on the
          // banner, which is where a notification belongs.

          // The content sits on a sheet that OVERLAPS the photograph by 18px and
          // casts a soft shadow onto it. One object in front of another, which
          // is what depth actually looks like — no perspective, no tilt, and
          // nothing that makes Arabic text harder to read.
          Transform.translate(
            offset: const Offset(0, -18),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.ivory,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                boxShadow: <BoxShadow>[
                  // Two shadows, not one: a tight dark one for the contact edge
                  // and a wide soft one for the ambient lift. A single shadow
                  // reads as a sticker.
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 28,
                    offset: Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                if (next == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Prayer times for this masjid haven\u2019t been set yet.',
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: AppColors.textMuted),
                    ),
                  )
                else
                  // Off-white (AppColors.cream), not pure white - the same
                  // surface tone used for cards elsewhere in the app (the
                  // theme's surfaceContainer, the Zakat calculator card),
                  // rather than a one-off white that stood out against it.
                  // Also a size down from the first pass - smaller padding
                  // and a smaller icon circle, since the card only needed to
                  // read as a distinct object, not fill the width so fully.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          S.nextPrayer.toUpperCase(),
                          style: AppText.eyebrow
                              .copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        // Icon on the left in a subtle circular outline, name
                        // and time on the right - one clear reading order
                        // instead of the clock figure, name, Arabic name, and
                        // countdown all competing on one line.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.emerald.withOpacity(0.08),
                                border: Border.all(
                                  color: AppColors.emerald.withOpacity(0.25),
                                  width: 1.4,
                                ),
                              ),
                              child: Icon(
                                _iconFor(next.$1),
                                size: 22,
                                color: AppColors.emerald,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      // A refined serif for the name -
                                      // premium and readable, distinct from
                                      // the clean sans the time is set in
                                      // below.
                                      Text(
                                        next.$1,
                                        style: const TextStyle(
                                          fontFamily: AppFonts.serif,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _arabicFor(next.$1),
                                        style: AppText.arabic.copyWith(
                                          fontSize: 16,
                                          color: AppColors.emerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  // LIGHTER WEIGHT than AppText.hero's default
                                  // w600 - a premium display figure reads as
                                  // refined at a lighter weight, not as loud
                                  // as the rest of the card was.
                                  Text(
                                    _clockLabel(next.$2),
                                    style: AppText.hero.copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.emerald,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Countdown and jamat, EQUALLY WEIGHTED.
                        //
                        // Same size box, same font size, same font weight -
                        // the only thing that tells them apart is the icon
                        // and the colour (emerald for azan's countdown,
                        // champagne gold for jamat), not one being larger or
                        // bolder than the other.
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _NextPrayerStat(
                                icon: Icons.access_time,
                                label: _countdownLabel(next.$2),
                                color: AppColors.emerald,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _NextPrayerStat(
                                icon: Icons.groups_outlined,
                                label: _jamatFor(masjid, next.$1).isEmpty
                                    ? '${S.jamatLabel} \u2014'
                                    : '${S.jamatLabel} ${_jamatFor(masjid, next.$1)}',
                                color: AppColors.champagneGold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _prayerTimesList(masjid, next?.$1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: _quickAction(
                    Icons.explore_outlined,
                    S.findQiblaDirection,
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QiblaScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      _quickAction(Icons.place_outlined, S.nearbyMasjid, () async {
                    final result = await Navigator.of(context).push<Masjid>(
                      MaterialPageRoute(
                          builder: (_) => const MasjidSearchScreen()),
                    );
                    if (result != null) {
                      await UserRepository.setSelectedMasjid(result.id);
                      setState(() => _selectedMasjidId = result.id);
                    }
                  }),
                ),
              ],
            ),
          ),
          // The masjid name, address, date and directions are all on the image
          // now. A card repeating them under it was the same information twice.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined, size: 16),
                  label: Text(S.viewFullPrayerSchedule),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emerald,
                    side: const BorderSide(color: AppColors.gold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: AppText.body,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => PrayerTimesScreen(masjid: masjid)),
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
                ],
              ),
            ),
          ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Which sky the header shows, derived from this masjid's prayer times rather
  /// than raw clock hours — so it tracks the actual day here, and moves with
  /// the season and the city without any extra data.
  ///
  ///   before Fajr .......... night
  ///   Fajr  -> Dhuhr ....... morning   (sun rises, birds)
  ///   Dhuhr -> Asr ......... midday    (sun overhead, still)
  ///   Asr   -> Isha ........ evening   (sun sets, birds)
  ///   after Isha ........... night     (stars, crescent)
  ///
  /// Falls back to clock hours if the masjid hasn't set its times yet.
  SkyPhase _skyPhase(Masjid masjid) {
    final DateTime? fajr = _parseTimeToday(masjid.prayerTimes.fajr);
    final DateTime? dhuhr = _parseTimeToday(masjid.prayerTimes.dhuhr);
    final DateTime? asr = _parseTimeToday(masjid.prayerTimes.asr);
    final DateTime? isha = _parseTimeToday(masjid.prayerTimes.isha);

    if (fajr == null || dhuhr == null || asr == null || isha == null) {
      final int h = _now.hour;
      if (h >= 5 && h < 11) return SkyPhase.morning;
      if (h >= 11 && h < 16) return SkyPhase.midday;
      if (h >= 16 && h < 19) return SkyPhase.evening;
      return SkyPhase.night;
    }

    // The boundaries are SORTED before use. This chain of isBefore checks only
    // makes sense on times in chronological order, and the same assumption is
    // what made the next-prayer logic pick Fajr over an earlier Asr. Sorting
    // means out-of-order data gives a sensible sky instead of a nonsensical
    // one — it cannot make the phase meaningful if the times are wrong, but it
    // stops the app contradicting itself.
    final List<DateTime> bounds = <DateTime>[fajr, dhuhr, asr, isha]..sort();

    if (_now.isBefore(bounds[0])) return SkyPhase.night;
    if (_now.isBefore(bounds[1])) return SkyPhase.morning;
    if (_now.isBefore(bounds[2])) return SkyPhase.midday;
    // Evening runs from asr to isha, which is several hours. Maghrib is the
    // sunset itself, so the golden treatment belongs to the stretch around it
    // rather than to the whole afternoon.
    if (_now.isBefore(bounds[3])) return SkyPhase.evening;
    return SkyPhase.night;
  }

  String _clockLabel(DateTime target) {
    final int display = target.hour % 12 == 0 ? 12 : target.hour % 12;
    return '$display:${target.minute.toString().padLeft(2, '0')}';
  }

  String _countdownLabel(DateTime target) {
    final diff = target.difference(_now);
    if (diff.isNegative) return 'now';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h == 0 && m == 0) return 'in under a minute';
    if (h == 0) return 'in $m ${m == 1 ? "minute" : "minutes"}';
    return 'in ${h}h ${m}m';
  }

  Widget _prayerTimesList(Masjid masjid, String? nextLabel) {
    final t = masjid.prayerTimes;
    // label, azan, arabic, jamat
    final rows = <(String, String, String, String)>[
      (S.fajr, t.fajr, _arabicPrayerNames['fajr']!, t.fajrJamat),
      (S.dhuhr, t.dhuhr, _arabicPrayerNames['dhuhr']!, t.dhuhrJamat),
      (S.asr, t.asr, _arabicPrayerNames['asr']!, t.asrJamat),
      (S.maghrib, t.maghrib, _arabicPrayerNames['maghrib']!, t.maghribJamat),
      (S.isha, t.isha, _arabicPrayerNames['isha']!, t.ishaJamat),
      (S.juma, t.juma, _arabicPrayerNames['juma']!, t.jumaJamat),
    ];

    // Column headings only when this masjid actually publishes jamat times.
    // Without them the right-hand column is unlabelled; with them on a masjid
    // that has none, they would head an empty column.
    final bool showJamat = t.hasAnyJamat;

    return Column(
      children: [
        if (showJamat)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Spacer(),
                // Headings sized with the same flex as the columns below, so
                // they cannot drift out of alignment on a narrow screen.
                Expanded(
                  flex: 3,
                  child: Text(S.azanLabel.toUpperCase(),
                      textAlign: TextAlign.right,
                      style: AppText.eyebrow.copyWith(
                          fontSize: 9, letterSpacing: 1, color: AppColors.textFaint)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(S.jamatLabel.toUpperCase(),
                      textAlign: TextAlign.right,
                      style: AppText.eyebrow.copyWith(
                          fontSize: 9, letterSpacing: 1, color: AppColors.champagneGold)),
                ),
              ],
            ),
          ),
        for (int i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
            decoration: BoxDecoration(
              // The next prayer gets a tinted row and a green edge, so it is
              // findable at a glance without reading any of the times.
              color: rows[i].$1 == nextLabel
                  ? AppColors.emerald.withOpacity(0.06)
                  : null,
              borderRadius: BorderRadius.circular(6),
              border: rows[i].$1 == nextLabel
                  ? const Border(
                      left: BorderSide(color: AppColors.emerald, width: 3))
                  : (i == 0
                      ? null
                      : const Border(
                          top: BorderSide(color: AppColors.goldRuleFaint))),
            ),
            // EVERYTHING IS FLEX NOW, no fixed pixel widths.
            //
            // The previous version used two 66px boxes plus a Spacer plus an
            // Expanded label plus the Arabic. On a 360dp screen that left the
            // name and the Arabic fighting over what was left, and the whole
            // row looked cramped and misaligned.
            //
            // Now the row is 4 : 2 : 3 : 3 — name, Arabic, azan, jamat — so it
            // scales with the screen instead of assuming one.
            child: Row(
              children: [
                // A circular icon per prayer, tinted emerald for the next one.
                // It gives the eye something to land on and makes the row read
                // as a list of moments in a day rather than a table of numbers.
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rows[i].$1 == nextLabel
                        ? AppColors.emerald
                        : AppColors.gold.withOpacity(0.10),
                  ),
                  child: Icon(
                    _prayerIcons[i],
                    size: 18,
                    color: rows[i].$1 == nextLabel
                        ? Colors.white
                        : AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // 3, not 4. The longest label is "JUMA (FRIDAY)" and it can
                  // ellipsize; a truncated TIME cannot be guessed from what is
                  // left of it.
                  flex: showJamat ? 3 : 4,
                  child: Text(
                    rows[i].$1.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.eyebrow.copyWith(
                      // Slightly tighter tracking when two time columns have to
                      // fit alongside.
                      letterSpacing: showJamat ? 0.8 : 1.3,
                      color: rows[i].$1 == nextLabel
                          ? AppColors.emerald
                          : AppColors.textMid,
                    ),
                  ),
                ),
                // THE ARABIC NAME IS DROPPED WHEN JAMAT IS SHOWN.
                //
                // Four columns — name, Arabic, azan, jamat — do not fit on a
                // 360dp screen, and the result was "12:30 …" with the time
                // itself truncated. A cut-off prayer time is worse than no
                // Arabic name.
                //
                // The Arabic stays whenever there is only one time column, so
                // masjids without jamat times lose nothing.
                if (!showJamat) ...[
                  Expanded(
                    flex: 2,
                    child: Text(
                      rows[i].$3,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: AppText.arabic.copyWith(
                          fontSize: 16, height: 1.2, color: AppColors.gold),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      style: AppText.listTime.copyWith(
                        fontSize: 17,
                        color: rows[i].$1 == nextLabel
                            ? AppColors.emerald
                            : AppColors.text,
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    flex: 4,
                    child: Text(
                      // "5:40 PM" becomes "5:40 pm" at a smaller size — the
                      // meridiem is needed but does not need to compete with
                      // the digits.
                      _splitTime(rows[i].$2).$1,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      // SAME SIZE, SAME FAMILY, SAME WEIGHT AS JAMAT.
                      //
                      // Weight used to be the thing that told azan and jamat
                      // apart (regular vs semibold) - but two different
                      // weights of the same colour read as "one of these got
                      // heavier", not as two equally-important facts. Now
                      // both are w600, and colour alone carries the
                      // distinction: emerald for azan, champagne gold for
                      // jamat.
                      style: AppText.listTime.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 4,
                    child: Text(
                      rows[i].$4.trim().isEmpty
                          ? '\u2014'
                          : _splitTime(rows[i].$4).$1,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      // Champagne gold, same size and weight as azan above -
                      // see the note on that Text for why only colour now
                      // carries the distinction. Stays gold even on the
                      // active row - the colour system is meant to be
                      // stable (azan is always emerald, jamat is always
                      // gold); the active row is already marked by its own
                      // tinted background, left edge, and emerald icon
                      // circle, so the time colours don't need to do that
                      // job too.
                      style: AppText.listTime.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: rows[i].$4.trim().isEmpty
                            ? AppColors.textFaint
                            : AppColors.champagneGold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }


  /// The full text, and any older announcements still running.
  ///
  /// A bottom sheet rather than a page: an announcement is a short read, and
  /// pushing a whole screen for two sentences makes it feel heavier than it is.
  void _showAnnouncements(List<Announcement> list, String masjidName) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.campaign_outlined,
                      size: 19, color: AppColors.gold),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      S.isUrdu ? 'اہم اعلان' : 'Important Announcement',
                      style: AppText.rowTitle
                          .copyWith(fontSize: 17, color: AppColors.text),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.textMuted,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              Text(masjidName,
                  style: AppText.caption.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 14),
              for (final Announcement a in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(a.message,
                          style: AppText.body
                              .copyWith(color: AppColors.text, height: 1.5)),
                      const SizedBox(height: 6),
                      Container(
                          width: 34, height: 1, color: AppColors.goldRule),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Notifies once per announcement, the first time this device sees it.
  ///
  /// Seen ids live on the device. Storing them server-side would mean a
  /// per-user read record, which is what this app has avoided everywhere else.
  Future<void> _notifyNewAnnouncements(
      List<Announcement> list, String masjidName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getStringList('seen_announcements') ?? <String>[];
      final fresh = list.where((a) => !seen.contains(a.id)).toList();
      if (fresh.isEmpty) return;
      for (final Announcement a in fresh) {
        await NotificationService.showAnnouncement(masjidName, a.message);
        seen.add(a.id);
      }
      if (seen.length > 200) seen.removeRange(0, seen.length - 200);
      await prefs.setStringList('seen_announcements', seen);
    } catch (_) {}
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) =>
      _PressCard(icon: icon, label: label, onTap: onTap);

}

/// A card that sinks when pressed.
///
/// Depth you can feel rather than only see: on touch it drops to 96% and its
/// shadow tightens, as though pushed toward the page. It is the one place a
/// transform genuinely helps — it is feedback, it lasts 90ms, and no text has to
/// stay readable through it.
class _PressCard extends StatefulWidget {
  const _PressCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_PressCard> createState() => _PressCardState();
}

class _PressCardState extends State<_PressCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: 62,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.goldRule),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0x1A000000),
                blurRadius: _down ? 3 : 9,
                offset: Offset(0, _down ? 1 : 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Icon and label side by side rather than stacked. Stacked, each
              // button needed 86px of height for two words; in a row they need
              // 62 and read the same.
              Icon(widget.icon, color: AppColors.gold, size: 19),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                widget.label,
                textAlign: TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.rowTitle
                    .copyWith(fontSize: 14, color: AppColors.text),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the two equally-weighted facts at the bottom of the Next Prayer
/// card - countdown and jamat. Same box, same text style for both; only the
/// icon and colour passed in differ, so neither can end up visually heavier
/// than the other by accident.
class _NextPrayerStat extends StatelessWidget {
  const _NextPrayerStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
