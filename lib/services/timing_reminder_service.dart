import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'masjid_repository.dart';
import 'admin_contact.dart';

/// Admin-only FCM registration. Tokens stay behind callable functions; no
/// Firestore client rules are broadened and worshippers are not registered.
class TimingReminderService {
  static final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  static String? _token;
  static String? _mobile;
  static bool _initialized = false;
  static bool _navigationReady = false;
  static String? _pendingId;

  static void requestOpen(String id) {
    if (!_navigationReady || _open == null) { _pendingId = id; return; }
    _pendingId = null;
    _open?.call(id);
  }

  static void markNavigationReady() {
    _navigationReady = true;
    final id = _pendingId;
    if (id != null) requestOpen(id);
  }
  static void Function(String)? _open;
  static StreamSubscription<String>? _refresh;
  static StreamSubscription<User?>? _auth;

  static final Set<String> _registered = {};

  static Future<void> initialize(void Function(String) onOpen) async {
    _open = onOpen;
    if (_navigationReady && _pendingId != null) requestOpen(_pendingId!);
    if (_initialized) return;
    _initialized = true;
    FirebaseMessaging.onMessageOpenedApp.listen(_tap);
    FirebaseMessaging.onMessage.listen((m) {
      if (_mobile != null && m.data['type'] == 'prayer_timing_reminder') {
        final id = m.data['masjidId'];
        if (id != null) unawaited(NotificationService.showTimingReminder(id));
      }
    });
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _tap(initial);
    _refresh = FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final old = _token;
      _token = token;
      _registered.clear();
      if (old != null && old != token) await _remove(old);
      if (_mobile != null) await enable(_mobile!);
    });
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      _registered.clear();
      if (_mobile != null && user != null && !user.isAnonymous) {
        unawaited(enable(_mobile!, requestPermission: false).then<void>((_) {}));
      } else {
        // A different account is not registered until its admin dashboard opens.
      }
    });
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('admin_mobile');
    if (saved != null) await enable(saved, requestPermission: false);
  }

  static void _tap(RemoteMessage m) {
    if (m.data['type'] == 'prayer_timing_reminder') {
      final id = m.data['masjidId'];
      if (id != null) requestOpen(id);
    }
  }

  static Future<String> enable(String mobile, {bool requestPermission = true}) async {
    try {
      _mobile = mobile;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) return 'Sign in as the verified masjid admin.';
      final settings = requestPermission
          ? await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true)
          : await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return 'Phone settings mein Islam Connect notifications allow karein.';
      }
      _token = await FirebaseMessaging.instance.getToken();
      if (_token == null) return 'Reminder registration nahi hui. Dobara try karein.';
      final managed = await MasjidRepository.streamByAdminMobile(mobile).first;
      var registered = 0;
      for (final m in managed) {
        if (!AdminContact.owns(m, user)) continue;
        registered++;
        final key = '${user.uid}:${m.id}:$_token';
        if (_registered.contains(key)) continue;
        await _functions.httpsCallable('registerTimingReminderDevice')
            .call({'masjidId': m.id, 'token': _token}).timeout(const Duration(seconds: 15));
        _registered.add(key);
      }
      return registered == 0 ? 'Reminders will be available after Platform Admin approval.' : 'Timings reminders enabled';
    } catch (_) {
      return 'Reminders enable nahi hue. Enable reminders par dobara tap karein.';
    }
  }

  static Future<void> _remove(String token) async {
    try {
      await _functions.httpsCallable('removeTimingReminderDevice')
          .call({'token': token}).timeout(const Duration(seconds: 8));
    } catch (_) { /* Scheduler also checks current ownership on every send. */ }
  }

  static Future<void> disable() async {
    _mobile = null;

    _registered.clear();
    final token = _token;
    if (token != null) await _remove(token);
    // Stop delivery to this installation even if backend unregister was offline.
    try { await FirebaseMessaging.instance.deleteToken(); } catch (_) {}
    _token = null;
  }
}
