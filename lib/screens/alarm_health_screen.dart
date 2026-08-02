import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/foreground_alarm_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';

/// Everything that decides whether a prayer alarm fires, on one screen, with a
/// way to test it.
///
/// The reason this exists: when an alarm does not fire, "nothing happened" is
/// the only symptom, and it looks identical whether the cause is a missing
/// permission, a frozen app, or a scheduling bug. Those need completely
/// different fixes. This separates them, and lets someone confirm alarms work
/// on their own handset instead of finding out at Fajr.
class AlarmHealthScreen extends StatefulWidget {
  const AlarmHealthScreen({super.key});

  @override
  State<AlarmHealthScreen> createState() => _AlarmHealthScreenState();
}

class _AlarmHealthScreenState extends State<AlarmHealthScreen> {
  Map<String, bool> _health = <String, bool>{};
  List<String> _pending = <String>[];
  bool? _serviceRunning;
  bool _loading = true;
  bool _testArmed = false;
  Map<String, dynamic>? _diag;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final health = await NotificationService.alarmHealth();
    final pending = await NotificationService.getPendingAlarms();
    final diag = await NotificationService.lastDiagnostics();
    bool? running;
    try {
      running = await ForegroundAlarmManager.isRunning();
    } catch (_) {
      running = null;
    }
    if (!mounted) return;
    setState(() {
      _health = health;
      _pending = pending;
      _serviceRunning = running;
      _diag = diag;
      _loading = false;
    });
  }

  Future<void> _fix(String key) async {
    if (key == 'Alarms & reminders') {
      await NotificationService.openExactAlarmSettings();
    } else if (key == 'Battery unrestricted') {
      await NotificationService.requestIgnoreBatteryOptimizations();
    } else {
      await NotificationService.openExactAlarmSettings();
    }
    await _refresh();
  }

  Future<void> _runTest() async {
    final tier = await NotificationService.scheduleTestAlarm();
    if (!mounted) return;
    setState(() {
      _testArmed = tier != null;
      _testResult = tier;
    });
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tier == null
            // This is the useful case. If every tier is refused, the phone is
            // blocking scheduling outright and no amount of app code fixes it.
            ? 'The system REFUSED to schedule an alarm. Check the permissions above, then the Autostart steps.'
            : 'Test alarm set for 60 seconds ($tier). Lock the phone and wait — do not swipe the app away.'),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _rearm() async {
    await NotificationService.scheduleFromCache();
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Alarms re-armed.')));
  }

  @override
  Widget build(BuildContext context) {
    final bool allGood =
        _health.values.every((bool v) => v) && _health.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Re-check',
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: allGood ? AppColors.white : AppColors.warningBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: allGood ? AppColors.goldRule : AppColors.gold),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        allGood ? Icons.check_circle_outline : Icons.warning_amber,
                        color:
                            allGood ? AppColors.emerald : AppColors.warningFg,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          allGood
                              ? 'Everything the app controls is set correctly.'
                              : 'Something below will stop alarms from firing.',
                          style: AppText.body.copyWith(
                            color: allGood
                                ? AppColors.text
                                : AppColors.warningFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionRule(label: 'Permissions'),
                for (final MapEntry<String, bool> e in _health.entries)
                  _StatusRow(
                    label: e.key,
                    ok: e.value,
                    onFix: e.value ? null : () => _fix(e.key),
                  ),
                _StatusRow(
                  label: 'Background service running',
                  ok: _serviceRunning ?? false,
                  onFix: null,
                ),

                const SizedBox(height: 22),
                const SectionRule(label: 'Test it on this phone'),
                const SizedBox(height: 10),
                Text(
                  'Sets a real alarm for 60 seconds from now, using exactly the same path a prayer alarm uses. Lock the phone and wait.',
                  style: AppText.caption.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _runTest,
                        icon: const Icon(Icons.alarm, size: 17),
                        label: const Text('Test alarm in 60 seconds'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.emerald,
                          side: const BorderSide(color: AppColors.gold),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          textStyle: AppText.body,
                        ),
                      ),
                    ),
                    if (_testArmed) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Cancel test',
                        onPressed: () async {
                          await NotificationService.cancelTestAlarm();
                          if (mounted) setState(() => _testArmed = false);
                        },
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 22),
                const SectionRule(label: 'Last scheduling run'),
                const SizedBox(height: 8),
                if (_diag == null)
                  Text('Nothing recorded yet.',
                      style:
                          AppText.caption.copyWith(color: AppColors.textMuted))
                else ...[
                  _DiagLine('Result', '${_diag!['result']}'),
                  _DiagLine('Alarms armed', '${_diag!['scheduled']}'),
                  _DiagLine('Method used', '${_diag!['mode'] ?? '-'}'),
                  if ((_diag!['failed'] as List?)?.isNotEmpty ?? false)
                    _DiagLine('FAILED', (_diag!['failed'] as List).join(', '),
                        bad: true),
                ],
                if (_testResult != null) ...[
                  const SizedBox(height: 6),
                  _DiagLine('Last test', _testResult!),
                ],
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _rearm,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Re-arm alarms now'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emerald,
                    side: const BorderSide(color: AppColors.goldRule),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    textStyle: AppText.body,
                  ),
                ),

                const SizedBox(height: 22),
                const SectionRule(label: 'Currently scheduled'),
                const SizedBox(height: 8),
                if (_pending.isEmpty)
                  Text(
                    'Nothing is scheduled. Open the Prayer Time tab once with a masjid selected.',
                    style: AppText.caption.copyWith(color: AppColors.textMuted),
                  )
                else
                  for (final String p in _pending)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(p,
                          style: AppText.caption
                              .copyWith(color: AppColors.textMuted)),
                    ),

                const SizedBox(height: 22),
                const SectionRule(label: 'If alarms still miss'),
                const SizedBox(height: 10),
                Text(
                  'Android lets phone makers kill background apps, and a killed app cannot ring. This is the one part no app can fix from code — including the alarm clock apps that come with the phone.',
                  style: AppText.body.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Text(
                  'Do not swipe this app away from recents. Then find your make below.',
                  style: AppText.body.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: 12),
                for (final _OemGuide g in _oemGuides)
                  _OemTile(guide: g),
              ],
            ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.ok, this.onFix});

  final String label;
  final bool ok;
  final VoidCallback? onFix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.goldRuleFaint)),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel_outlined,
            size: 19,
            color: ok ? AppColors.emerald : const Color(0xFFB3261E),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(label,
                style: AppText.body.copyWith(color: AppColors.text)),
          ),
          if (onFix != null)
            TextButton(
              onPressed: onFix,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.emerald,
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

class _OemGuide {
  const _OemGuide(this.make, this.steps);
  final String make;
  final List<String> steps;
}

/// Written out per manufacturer rather than detected, so no extra plugin is
/// pulled into the build just to read a device string.
const List<_OemGuide> _oemGuides = <_OemGuide>[
  _OemGuide('Xiaomi, Redmi, POCO', <String>[
    'Settings > Apps > Manage apps > Masjid Namaz Alarm',
    'Turn ON Autostart',
    'Battery saver > No restrictions',
    'In Recents, pull the app card down and tap the lock icon',
  ]),
  _OemGuide('Realme, OPPO', <String>[
    'Settings > Apps > App management > Masjid Namaz Alarm',
    'Turn ON Allow auto launch',
    'Battery usage > Allow background activity',
    'Settings > Battery > turn OFF Sleep standby optimisation',
  ]),
  _OemGuide('vivo, iQOO', <String>[
    'Settings > Battery > Background power consumption management',
    'Find the app and allow high background power use',
    'Settings > Apps > Autostart > enable for this app',
  ]),
  _OemGuide('Samsung', <String>[
    'Settings > Apps > Masjid Namaz Alarm > Battery',
    'Set to Unrestricted',
    'Settings > Battery > Background usage limits',
    'Make sure the app is NOT in "Sleeping" or "Deep sleeping" apps',
  ]),
  _OemGuide('OnePlus', <String>[
    'Settings > Battery > Battery optimisation > Don\u2019t optimise',
    'Settings > Apps > Auto-launch > enable',
  ]),
  _OemGuide('Stock Android, Motorola, Nokia, Pixel', <String>[
    'Settings > Apps > Masjid Namaz Alarm > Battery > Unrestricted',
    'Usually nothing else is needed on these phones',
  ]),
];

class _OemTile extends StatelessWidget {
  const _OemTile({required this.guide});

  final _OemGuide guide;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.goldRule),
      ),
      child: Theme(
        // ExpansionTile draws its own dividers, which fight the card border.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          title: Text(
            guide.make,
            style: AppText.rowTitle.copyWith(fontSize: 16, color: AppColors.text),
          ),
          iconColor: AppColors.emerald,
          collapsedIconColor: AppColors.chevron,
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          children: [
            for (int i = 0; i < guide.steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}.',
                        style: AppText.caption
                            .copyWith(color: AppColors.gold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(guide.steps[i],
                          style: AppText.caption
                              .copyWith(color: AppColors.textMuted)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DiagLine extends StatelessWidget {
  const _DiagLine(this.label, this.value, {this.bad = false});

  final String label;
  final String value;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: AppText.caption.copyWith(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.caption.copyWith(
                color: bad ? const Color(0xFFB3261E) : AppColors.text,
                fontWeight: bad ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
