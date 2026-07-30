import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hijri/hijri_calendar.dart';
import '../models/masjid.dart';
import '../services/masjid_repository.dart';
import '../services/user_repository.dart';
import '../services/notification_service.dart';
import '../services/foreground_alarm_manager.dart';
import '../services/app_strings.dart';
import 'masjid_search_screen.dart';
import 'prayer_times_screen.dart';
import 'settings_screen.dart';
import 'quran_home_screen.dart';
import 'hadith_home_screen.dart';
import 'prayers_home_screen.dart';
import 'qibla_screen.dart';
import 'admin_login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedMasjidId;
  bool _loading = true;
  String? _lastScheduledSignature;
  bool _exactAlarmWarningDismissed = false;
  bool? _hasExactAlarmPermission;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSelectedMasjid();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
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

  void _maybeScheduleNotifications(Masjid masjid) {
    final t = masjid.prayerTimes;
    final signature = '${masjid.id}|${t.fajr}|${t.dhuhr}|${t.asr}|${t.maghrib}|${t.isha}|${t.juma}';
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
    if (mounted) setState(() => _hasExactAlarmPermission = granted);
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
    // All passed today - next is tomorrow's Fajr, if set.
    final fajrToday = _parseTimeToday(masjid.prayerTimes.fajr);
    if (fajrToday != null) {
      return (S.fajr, fajrToday.add(const Duration(days: 1)));
    }
    return null;
  }

  /// A gradient that shifts with the time of day relative to prayer
  /// times - dawn tones near Fajr, bright daylight through Dhuhr/Asr,
  /// warm sunset near Maghrib, and a dark starry tone after Isha.
  LinearGradient _skyGradient(Masjid? masjid) {
    final hour = _now.hour;
    if (hour >= 4 && hour < 6) {
      return const LinearGradient(colors: [Color(0xFF2C3E67), Color(0xFFE8A87C), Color(0xFFF6D6AD)]);
    } else if (hour >= 6 && hour < 15) {
      return const LinearGradient(colors: [Color(0xFF4A90D9), Color(0xFF87CEEB), Color(0xFFD4E8F7)]);
    } else if (hour >= 15 && hour < 18) {
      return const LinearGradient(colors: [Color(0xFFE8935B), Color(0xFFF2B880), Color(0xFFFCE0B8)]);
    } else if (hour >= 18 && hour < 20) {
      return const LinearGradient(colors: [Color(0xFF6B3F5C), Color(0xFFD8703D), Color(0xFFF4A15C)]);
    } else {
      return const LinearGradient(colors: [Color(0xFF0B1229), Color(0xFF1A2744), Color(0xFF2C3E67)]);
    }
  }

  bool get _isNightSky => _now.hour >= 20 || _now.hour < 4;

  void _showHijriInfo() {
    final hijri = HijriCalendar.now();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Islamic Date'),
        content: Text('${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH\n\nFull calendar view is coming soon.'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hijri = HijriCalendar.now();
    return Scaffold(
      body: Column(
        children: [
          if (_hasExactAlarmPermission == false && !_exactAlarmWarningDismissed)
            Material(
              color: const Color(0xFFFFF3CD),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Prayer alarms are OFF. Enable "Alarms & Reminders" for this app in phone settings so notifications fire on time.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await NotificationService.openExactAlarmSettings();
                        final granted = await NotificationService.hasExactAlarmPermission();
                        if (mounted) setState(() => _hasExactAlarmPermission = granted);
                      },
                      child: const Text('Fix'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _exactAlarmWarningDismissed = true),
                    ),
                  ],
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
                            return const Center(child: CircularProgressIndicator());
                          }
                          final masjid = snapshot.data;
                          if (masjid == null) return _buildNoMasjidSelected();
                          _maybeScheduleNotifications(masjid);
                          return _buildPremiumHome(masjid, hijri);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1F5E4A),
        icon: const Icon(Icons.search, color: Colors.white),
        label: Text(S.changeMasjid, style: const TextStyle(color: Colors.white)),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1F5E4A),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuranHomeScreen()));
          } else if (index == 2) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HadithHomeScreen()));
          } else if (index == 3) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrayersHomeScreen()));
          } else if (index == 4) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
          }
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.mosque), label: S.prayerTime),
          BottomNavigationBarItem(icon: const Icon(Icons.menu_book), label: S.quran),
          BottomNavigationBarItem(icon: const Icon(Icons.book), label: S.hadith),
          BottomNavigationBarItem(icon: const Icon(Icons.self_improvement), label: S.prayers),
          BottomNavigationBarItem(icon: const Icon(Icons.admin_panel_settings), label: S.masjidAdmin),
        ],
      ),
    );
  }

  Widget _buildNoMasjidSelected() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          S.noMasjidSelected,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPremiumHome(Masjid masjid, HijriCalendar hijri) {
    final next = _nextPrayer(masjid);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Mosque header with real photo + time-tinted overlay ---
          Container(
            height: 280,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/mosque_header.jpg', fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 44, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ),
                      Text(masjid.name,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w300),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_now.day}/${_now.month}/${_now.year}',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: _showHijriInfo,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      if (next != null) ...[
                        const SizedBox(height: 16),
                        _buildCountdownCard(next.$1, next.$2),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Quick actions ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(child: _quickActionButton(Icons.explore, S.findQiblaDirection, () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QiblaScreen()));
                })),
                const SizedBox(width: 10),
                Expanded(child: _quickActionButton(Icons.near_me, S.nearbyMasjid, () async {
                  final result = await Navigator.of(context).push<Masjid>(
                    MaterialPageRoute(builder: (_) => const MasjidSearchScreen()),
                  );
                  if (result != null) {
                    await UserRepository.setSelectedMasjid(result.id);
                    setState(() => _selectedMasjidId = result.id);
                  }
                })),
              ],
            ),
          ),

          // --- Masjid info glass card ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: const Color(0xFFFCFAF5),
                  child: ListTile(
                    leading: const Icon(Icons.mosque, color: Color(0xFF1F5E4A), size: 32),
                    title: Text(masjid.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('${masjid.address}\n${masjid.city}'),
                    isThreeLine: true,
                    trailing: Icon(
                      masjid.verificationStatus == 'Verified' ? Icons.verified : Icons.hourglass_top,
                      color: masjid.verificationStatus == 'Verified' ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                if (masjid.latitude != 0.0 || masjid.longitude != 0.0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 6),
                    child: InkWell(
                      onTap: () => _openDirections(masjid),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions, size: 18, color: Color(0xFF1F5E4A)),
                          const SizedBox(width: 6),
                          Text(S.getDirections,
                              style: const TextStyle(
                                  color: Color(0xFF1F5E4A), fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(S.todaysPrayerTimes, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _prayerTimesGlassCard(masjid),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: Text(S.viewFullPrayerSchedule),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PrayerTimesScreen(masjid: masjid)),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard(String label, DateTime target) {
    final diff = target.difference(_now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text('${S.nextPrayer}: $label', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFFCFAF5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF1F5E4A), size: 26),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF1F5E4A), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _prayerTimesGlassCard(Masjid masjid) {
    final rows = [
      (S.fajr, masjid.prayerTimes.fajr),
      (S.dhuhr, masjid.prayerTimes.dhuhr),
      (S.asr, masjid.prayerTimes.asr),
      (S.maghrib, masjid.prayerTimes.maghrib),
      (S.isha, masjid.prayerTimes.isha),
      (S.juma, masjid.prayerTimes.juma),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: rows.map((r) {
          final isNext = _nextPrayer(masjid)?.$1 == r.$1;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.$1, style: TextStyle(fontSize: 16, fontWeight: isNext ? FontWeight.bold : FontWeight.normal, color: isNext ? const Color(0xFF1F5E4A) : Colors.black87)),
                Text(r.$2, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isNext ? const Color(0xFF1F5E4A) : Colors.black87)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildStars() {
    final rnd = Random(42);
    return List.generate(20, (i) {
      return Positioned(
        left: rnd.nextDouble() * 350,
        top: rnd.nextDouble() * 150,
        child: Icon(Icons.star, size: rnd.nextDouble() * 3 + 2, color: Colors.white.withOpacity(0.6)),
      );
    });
  }
}
