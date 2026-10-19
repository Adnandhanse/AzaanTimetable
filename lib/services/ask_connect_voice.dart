import 'package:flutter/services.dart';

/// Delegates capture to the phone's speech activity. No app audio is recorded,
/// uploaded or retained by Islam Connect. The selected phone provider may use
/// its servers; the UI explains this before the first microphone launch.
class AskConnectVoice {
  static const _channel = MethodChannel('islam_connect/voice_search');
  static Future<String?> listen(String locale) =>
      _channel.invokeMethod<String>('listen', {'locale': locale});
}
