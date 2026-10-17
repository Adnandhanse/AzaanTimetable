import 'package:flutter/services.dart';

class AzanScreenEvents {
  static const _channel = EventChannel('islam_connect/screen_events');
  static Stream<dynamic> get changes => _channel.receiveBroadcastStream();
}
