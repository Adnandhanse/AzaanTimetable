import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';

/// First-run setup for the alarm system.
///
/// WHAT THIS CAN AND CANNOT DO
///
/// It cannot silently configure the phone. Android deliberately forbids an app
/// from granting itself background permissions or removing itself from a
/// manufacturer's sleeping-apps list — that restriction exists precisely to
/// stop apps doing this. Any app that claims otherwise is not telling the
/// truth.
///
/// What it can do is ask for the three real permissions directly, and deep-link
/// to the exact screen for everything else, so the user taps twice instead of
/// hunting through five levels of menu. Most people will finish that; almost
/// nobody finishes a wall of written instructions.
class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  Map<String, bool> _health = <String, bool>{};
  bool _busy = false;
  bool _samsungDone = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final h = await NotificationService.alarmHealth();
    if (!mounted) return;
    setState(() => _health = h);
  }

  Future<void> _grantNotifications() async {
    setState(() => _busy = true);
    await Permission.notification.request();
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _grantExactAlarm() async {
    setState(() => _busy = true);
    await Permission.scheduleExactAlarm.request();
    await NotificationService.openExactAlarmSettings();
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _grantBattery() async {
    setState(() => _busy = true);
    await NotificationService.requestIgnoreBatteryOptimizations();
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  /// Samsung keeps a second battery system that Android's whitelist does not
  /// cover, and there is no API to read or change it. The best available is to
  /// land the user on the right screen.
  Future<void> _openBackgroundLimits() async {
    // Samsung's own Device Care battery page, then the generic battery
    // settings, then the app's settings page. Each is tried in turn because
    // the component name differs across One UI versions and silently fails on
    // anything that is not Samsung.
    // Not const: AndroidIntent's constructor is not a const constructor.
    final List<AndroidIntent> candidates = <AndroidIntent>[
      AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.samsung.android.lool',
        componentName: 'com.samsung.android.sm.battery.ui.BatteryActivity',
      ),
      AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.samsung.android.sm_cn',
        componentName: 'com.samsung.android.sm.battery.ui.BatteryActivity',
      ),
      AndroidIntent(action: 'android.settings.BATTERY_SAVER_SETTINGS'),
    ];

    for (final AndroidIntent intent in candidates) {
      try {
        await intent.launch();
        if (mounted) setState(() => _samsungDone = true);
        return;
      } catch (_) {
        // try the next one
      }
    }
    // Nothing Samsung-specific worked; fall back to this app's settings page.
    await openAppSettings();
    if (mounted) setState(() => _samsungDone = true);
  }

  Future<void> _finish() async {
    await NotificationService.scheduleFromCache();
    if (!mounted) return;
    widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool notif = _health['Notifications allowed'] ?? false;
    final bool exact = _health['Alarms & reminders'] ?? false;
    final bool batt = _health['Battery unrestricted'] ?? false;
    final bool allCore = notif && exact && batt;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          children: <Widget>[
            Text('Set up prayer alarms',
                style: AppText.displayName
                    .copyWith(fontSize: 26, color: AppColors.emerald)),
            const SizedBox(height: 6),
            Text(
              'Four steps, about a minute. Android will not let an app switch these on by itself, so each one needs your tap.',
              style: AppText.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            const DiamondRule(),
            const SizedBox(height: 18),

            _Step(
              number: 1,
              title: 'Allow notifications',
              detail:
                  'One tap. Without this the alarm has no way to reach you.',
              done: notif,
              busy: _busy,
              onTap: _grantNotifications,
            ),
            _Step(
              number: 2,
              title: 'Allow alarms & reminders',
              detail:
                  'Lets the alarm fire at an exact minute rather than whenever Android feels like it. Android gives no dialog for this one, so it opens a settings screen — and on newer phones it is often already on.',
              done: exact,
              busy: _busy,
              onTap: _grantExactAlarm,
            ),
            _Step(
              number: 3,
              title: 'Let the app run in the background',
              detail:
                  'One tap. A battery-restricted app gets frozen, and a frozen app cannot ring.',
              done: batt,
              busy: _busy,
              onTap: _grantBattery,
            ),
            _Step(
              number: 4,
              title: 'Turn off "Put unused apps to sleep"',
              detail:
                  'Samsung has a second battery system that step 3 does not cover, and no app can read or change it. On the screen that opens: Background usage limits → turn OFF "Put unused apps to sleep", then remove this app from "Sleeping apps" and "Deep sleeping apps".',
              done: _samsungDone,
              busy: _busy,
              actionLabel: 'Open',
              onTap: _openBackgroundLimits,
            ),

            const SizedBox(height: 10),
            const DiamondRule(),
            const SizedBox(height: 16),

            if (!allCore)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.gold),
                ),
                padding: const EdgeInsets.all(13),
                child: Text(
                  'Steps 1 to 3 are still incomplete. Prayer alarms will be unreliable until they are done.',
                  style:
                      AppText.caption.copyWith(color: AppColors.warningFg),
                ),
              ),

            const SizedBox(height: 14),
            FilledButton(
              onPressed: _finish,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              child: Text(allCore ? 'Done' : 'Continue anyway',
                  style: AppText.body.copyWith(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            Text(
              'Steps 1 and 3 are one-tap system prompts. Steps 2 and 4 have no prompt Android will show on an app\u2019s behalf, so they open the right screen instead.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: AppColors.textFaint),
            ),
            const SizedBox(height: 6),
            Text(
              'You can reopen this any time from Settings \u2192 Alarm health.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: AppColors.textFaint),
            ),
            const SizedBox(height: 12),
            // The wizard now returns whenever a permission goes missing, so
            // there has to be a way out for someone who does not want it.
            TextButton(
              onPressed: () async {
                await NotificationService.setSetupDismissed(true);
                await _finish();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              child: Text('Don\u2019t show this again',
                  style: AppText.caption.copyWith(color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.detail,
    required this.done,
    required this.busy,
    required this.onTap,
    this.actionLabel = 'Allow',
  });

  final int number;
  final String title;
  final String detail;
  final bool done;
  final bool busy;
  final VoidCallback onTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: done ? AppColors.emerald : AppColors.goldRule,
          width: done ? 1.4 : 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          done
              ? const Icon(Icons.check_circle,
                  color: AppColors.emerald, size: 34)
              : Medallion(label: '$number', size: 34),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: AppText.rowTitle
                        .copyWith(fontSize: 16, color: AppColors.text)),
                const SizedBox(height: 3),
                Text(detail,
                    style: AppText.caption
                        .copyWith(color: AppColors.textMuted)),
                if (!done) ...<Widget>[
                  const SizedBox(height: 9),
                  OutlinedButton(
                    onPressed: busy ? null : onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emerald,
                      side: const BorderSide(color: AppColors.gold),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      textStyle: AppText.body,
                    ),
                    child: Text(actionLabel),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
