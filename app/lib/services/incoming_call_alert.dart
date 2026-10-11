import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android notifications provide ringing without retaining a media connection.
class IncomingCallAlert {
  static const channel = MethodChannel('uma/calls');
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<T?> invoke<T>(String method, [Object? arguments]) async {
    if (!supported) return null;
    try {
      return await channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<void> stop(String id) async => invoke<void>('stop', id);
  static Future<void> busy(bool value) async => invoke<void>('busy', value);
}
