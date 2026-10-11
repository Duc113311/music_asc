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

  static Future<void> hideNavigationBar() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _ch.invokeMethod('hideNavigationBar');
    } on PlatformException catch (e) {
      AppLog.info('SystemUiChannel.hideNavigationBar: $e');
    } on MissingPluginException catch (_) {}
  }
}
