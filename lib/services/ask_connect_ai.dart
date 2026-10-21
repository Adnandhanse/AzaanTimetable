import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// A separate persistent anonymous session keeps the masjid admin's default
/// phone login untouched. Only the question, not audio/phone/location, is sent.
class AskConnectAi {
  static Future<FirebaseApp>? _session;
  static Future<FirebaseApp> _initialize() async {
    const name = 'ask-islam-connect';
    final existing = Firebase.apps.where((app) => app.name == name);
    final app = existing.isNotEmpty ? existing.first : await Firebase.initializeApp(
      name: name, options: Firebase.app().options);
    final auth = FirebaseAuth.instanceFor(app: app);
    if (auth.currentUser == null) await auth.signInAnonymously();
    return app;
  }
  static Future<Map<String, dynamic>> ask(String question, String kind) async {
    try {
      final app = await (_session ??= _initialize());
      final response = await FirebaseFunctions.instanceFor(app: app, region: 'us-central1')
        .httpsCallable('askIslamConnect', options: HttpsCallableOptions(
          timeout: const Duration(seconds: 115)))
        .call<dynamic>({'question': question, 'kind': kind, 'acceptGuides': true});
      return _map(response.data);
    } catch (_) { _session = null; rethrow; }
  }
  static Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from((value as Map).map((key, value) =>
        MapEntry(key.toString(), _convert(value))));
  static dynamic _convert(dynamic value) => value is Map ? _map(value)
      : value is List ? value.map(_convert).toList() : value;
}
