import 'dart:ui' show DartPluginRegistrant;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:azan_screen_events/azan_screen_events.dart';
import 'alarm_event_log.dart';

/// Native persisted sequence + broadcast reach the service from any Flutter engine.
class AzanStopController {
  static Future<void> stop() async {
    try {
      await AzanScreenEvents.requestStop();
    } catch (error) {
      await AlarmEventLog.add('native stop signal failed', detail: '$error');
    } finally {
      // Fast secondary path when the foreground-task messenger is available.
      try { FlutterForegroundTask.sendDataToTask('stop_azan'); } catch (_) {}
    }
  }
}

@pragma('vm:entry-point')
void azanNotificationActionBackground(NotificationResponse response) async {
  if (response.actionId != 'stop_azan') return;
  DartPluginRegistrant.ensureInitialized();
  await AzanStopController.stop();
}
