/// Notification channel identifiers, in one place.
///
/// These live in their own file so both NotificationService and the background
/// isolate in foreground_alarm_service can reference them without importing
/// each other. Those two used to disagree about the channel id — the
/// foreground service posted to a channel NotificationService had deleted, and
/// Android drops such notifications silently. Constants with a single home
/// make that class of mistake impossible.
///
/// A channel's SOUND IS FIXED when Android first creates it and can never be
/// changed. To change the sound, bump the id. Editing the audio file alone
/// does nothing for anyone who already has the app installed.
class NotificationChannels {
  NotificationChannels._();

  /// Alarms carrying the bundled azan.
  static const String azan = 'prayer_alarm_azan_v2';

  /// Alarms using the phone's default alert sound. A separate channel, because
  /// the sound cannot be swapped on an existing one.
  static const String plain = 'prayer_alarm_plain_v2';

  static const String name = 'Prayer Time Alarms';

  /// Every id this app has ever used, deleted at startup so a channel created
  /// with a broken sound URI cannot linger and swallow notifications.
  static const List<String> retired = <String>[
    'prayer_times_channel',
    'prayer_alarm_azan_v1',
    'prayer_alarm_plain_v1',
  ];
}
