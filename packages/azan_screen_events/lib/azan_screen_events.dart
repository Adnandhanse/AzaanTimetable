import 'package:flutter/services.dart';

class AzanScreenEvents {
  static const _channel = EventChannel('islam_connect/screen_events');
  static const _control = MethodChannel('islam_connect/azan_control');
  static Stream<dynamic> get changes => _channel.receiveBroadcastStream();
  static Future<void> requestStop() => _control.invokeMethod<void>('stop');
  static Future<int> stopSequence() async =>
      await _control.invokeMethod<int>('stopSequence') ?? 0;
}
