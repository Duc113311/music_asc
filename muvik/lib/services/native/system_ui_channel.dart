import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../utils/app_log.dart';

/// Immersive mode: hides the device navigation bar at the bottom (a swipe
/// shows it briefly). MainActivity re-applies it on resume and focus.
class SystemUiChannel {
  SystemUiChannel._();
  static const MethodChannel _ch = MethodChannel(
    'com.asctechsoft.muvik/system_ui',
  );

  /// Keeps the CPU awake for [duration] (a self-releasing wake lock) while the
  /// player opens the next track, so a locked phone cannot doze in the middle
  /// of the change. Failures are ignored: it is a precaution.
  static Future<void> holdCpu([
    Duration duration = const Duration(seconds: 30),
  ]) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _ch.invokeMethod('holdCpu', {'ms': duration.inMilliseconds});
    } on PlatformException catch (e) {
      AppLog.info('SystemUiChannel.holdCpu: $e');
    } on MissingPluginException catch (_) {}
  }

  static Future<void> hideNavigationBar() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _ch.invokeMethod('hideNavigationBar');
    } on PlatformException catch (e) {
      AppLog.info('SystemUiChannel.hideNavigationBar: $e');
    } on MissingPluginException catch (_) {}
  }
}
