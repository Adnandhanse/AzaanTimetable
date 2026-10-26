import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Keeps the admin's phone/email session untouched. Recent chat is request-only;
/// no new chat-history records are written by the Flutter client.
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
  static Future<Map<String, dynamic>> ask(String question, String kind, {
    List<Map<String, String>> history = const [], String replyLanguage = 'auto',
  }) async {
    FirebaseApp app;
    try {
      app = await (_session ??= _initialize()).timeout(const Duration(seconds: 12));
    } catch (_) { _session = null; rethrow; }
    try {
      final response = await FirebaseFunctions.instanceFor(app: app, region: 'us-central1')
        .httpsCallable('askIslamConnect', options: HttpsCallableOptions(
          timeout: const Duration(seconds: 70)))
        .call<dynamic>({'protocol': 2, 'question': question, 'kind': kind,
          'history': history, 'replyLanguage': replyLanguage});
      final result = _map(response.data);
      if (result['answerMode'] != 'conversation-v1') {
        throw StateError('assistant-backend-update-needed');
      }
      return result;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') _session = null;
      rethrow;
    }
  }
  static Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from((value as Map).map((key, value) =>
        MapEntry(key.toString(), _convert(value))));
  static dynamic _convert(dynamic value) => value is Map ? _map(value)
      : value is List ? value.map(_convert).toList() : value;
}
