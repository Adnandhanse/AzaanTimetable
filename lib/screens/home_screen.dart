import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hijri/hijri_calendar.dart';
import '../models/masjid.dart';
import '../services/masjid_repository.dart';
import '../services/user_repository.dart';
import '../services/notification_service.dart';
import '../services/foreground_alarm_manager.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';
import '../widgets/artwork_header.dart';
import '../widgets/sky_artwork.dart';
import 'masjid_search_screen.dart';
import 'prayer_times_screen.dart';
import 'settings_screen.dart';
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
    _repairAlarmsIfNeeded();
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
  (String, DateTime)? _nextPrayer(Masjid masjid) {
    final entries = [
      (S.fajr, masjid.prayerTimes.fajr),
      (S.dhuhr, masjid.prayerTimes.dhuhr),
      (S.asr, masjid.prayerTimes.asr),
      (S.maghrib, masjid.prayerTimes.maghrib),
      (S.isha, masjid.prayerTimes.isha),
    ];
    for (final entry in entries) {
      final dt = _parseTimeToday(entry.$2);
      if (dt != null && dt.isAfter(_now)) return (entry.$1, dt);
    }
    final fajrToday = _parseTimeToday(masjid.prayerTimes.fajr);
    if (fajrToday != null) {
      return (S.fajr, fajrToday.add(const Duration(days: 1)));
    }
    return null;
  }

  void _showHijriInfo() {
    final hijri = HijriCalendar.now();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text('Islamic Date',
            style: AppText.rowTitle.copyWith(color: AppColors.emerald)),
        content: Text(
          '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH\n\nFull calendar view is coming soon.',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
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
                            const SizedBox(height: 3),
                            if (_hasExactAlarmPermission == false)
                              _FixRow(
                                label:
                                    '"Alarms & reminders" is off for this app.',
                                onFix: () async {
                                  await NotificationService
                                      .openExactAlarmSettings();
                                  final g = await NotificationService
                                      .hasExactAlarmPermission();
                                  if (mounted) {
                                    setState(
                                        () => _hasExactAlarmPermission = g);
                                  }
                                },
                              ),
                            if (_hasBatteryExemption == false)
                              _FixRow(
                                label:
                                    'Battery saver can freeze the app and stop alarms.',
                                onFix: () async {
                                  await NotificationService
                                      .requestIgnoreBatteryOptimizations();
                                  final e = await NotificationService
                                      .hasBatteryExemption();
                                  if (mounted) {
                                    setState(() => _hasBatteryExemption = e);
                                  }
                                },
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.emerald,
        icon: const Icon(Icons.search, color: Colors.white),
        label: Text(
          S.changeMasjid,
          style: const TextStyle(color: Colors.white, fontFamily: AppFonts.sans),
        ),
        onPressed: () async {
          final result = await Navigator.of(context).push<Masjid>(
            MaterialPageRoute(builder: (_) => const MasjidSearchScreen()),
          );
          if (result != null) {
            await UserRepository.setSelectedMasjid(result.id);
            setState(() => _selectedMasjidId = result.id);
          }
        },
      ),
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
            } else if (index == 4) {
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
              style:
                  AppText.body.copyWith(fontSize: 14, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIlluminatedHome(Masjid masjid, HijriCalendar hijri) {
    final next = _nextPrayer(masjid);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedBuilder(
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
              onSettingsTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              onMetaTap: _showHijriInfo,
            ),
          ),
          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              children: [
                const DiamondRule(),
                const SizedBox(height: 14),
                if (next == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'Prayer times for this masjid haven\u2019t been set yet.',
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: AppColors.textMuted),
                    ),
                  )
                else ...[
                  Text(
                    S.nextPrayer.toUpperCase(),
                    style: AppText.eyebrow.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  // Cross-fades when the minute rolls over, so the number
                  // changes softly instead of snapping.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: Text(
                      _clockLabel(next.$2),
                      key: ValueKey<String>(_clockLabel(next.$2)),
                      style: AppText.hero.copyWith(color: AppColors.emerald),
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: next.$1,
                          style: const TextStyle(
                            fontFamily: AppFonts.serif,
                            fontSize: 19,
                            color: AppColors.text,
                          ),
                        ),
                        TextSpan(
                          text: '  ·  ${_countdownLabel(next.$2)}',
                          style: const TextStyle(
                            fontFamily: AppFonts.serif,
                            fontSize: 15,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const DiamondRule(),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionRule(label: 'This masjid'),
                const SizedBox(height: 12),
                _masjidCard(masjid),
                const SizedBox(height: 14),
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

    if (_now.isBefore(fajr)) return SkyPhase.night;
    if (_now.isBefore(dhuhr)) return SkyPhase.morning;
    if (_now.isBefore(asr)) return SkyPhase.midday;
    if (_now.isBefore(isha)) return SkyPhase.evening;
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
    final rows = <(String, String, String)>[
      (S.fajr, masjid.prayerTimes.fajr, _arabicPrayerNames['fajr']!),
      (S.dhuhr, masjid.prayerTimes.dhuhr, _arabicPrayerNames['dhuhr']!),
      (S.asr, masjid.prayerTimes.asr, _arabicPrayerNames['asr']!),
      (S.maghrib, masjid.prayerTimes.maghrib, _arabicPrayerNames['maghrib']!),
      (S.isha, masjid.prayerTimes.isha, _arabicPrayerNames['isha']!),
      (S.juma, masjid.prayerTimes.juma, _arabicPrayerNames['juma']!),
    ];

    return Column(
      children: [
        for (int i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
            decoration: BoxDecoration(
              border: i == 0
                  ? null
                  : const Border(
                      top: BorderSide(color: AppColors.goldRuleFaint)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rows[i].$1.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.eyebrow.copyWith(
                      letterSpacing: 1.3,
                      color: rows[i].$1 == nextLabel
                          ? AppColors.emerald
                          : AppColors.textMid,
                    ),
                  ),
                ),
                Text(
                  rows[i].$3,
                  style: AppText.arabic.copyWith(
                    fontSize: 16,
                    height: 1.2,
                    color: AppColors.gold,
                  ),
                ),
                Expanded(
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
              ],
            ),
          ),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.goldRule),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: AppColors.gold, size: 22),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style:
                    AppText.rowTitle.copyWith(fontSize: 15, color: AppColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _masjidCard(Masjid masjid) {
    final bool verified = masjid.verificationStatus == 'Verified';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.goldRule),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Medallion(icon: Icons.mosque_outlined, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(masjid.name,
                        style: AppText.rowTitle.copyWith(color: AppColors.text)),
                    const SizedBox(height: 2),
                    Text(
                      masjid.address.isEmpty
                          ? masjid.city
                          : '${masjid.address}, ${masjid.city}',
                      style:
                          AppText.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.goldRuleFaint),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                verified ? Icons.verified_outlined : Icons.hourglass_empty,
                size: 15,
                color: verified ? AppColors.emerald : AppColors.gold,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  verified ? S.verified : S.pendingVerification,
                  style: AppText.caption.copyWith(
                    color: verified ? AppColors.emerald : AppColors.textMuted,
                  ),
                ),
              ),
              if (masjid.latitude != 0.0 || masjid.longitude != 0.0)
                InkWell(
                  onTap: () => _openDirections(masjid),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_outlined,
                          size: 15, color: AppColors.emerald),
                      const SizedBox(width: 5),
                      Text(
                        S.getDirections,
                        style: AppText.caption.copyWith(
                          color: AppColors.emerald,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FixRow extends StatelessWidget {
  const _FixRow({required this.label, required this.onFix});

  final String label;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.caption
                  .copyWith(fontSize: 12.5, color: AppColors.warningFg),
            ),
          ),
          TextButton(
            onPressed: onFix,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warningFg,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Fix'),
          ),
        ],
      ),
    );
  }
}
