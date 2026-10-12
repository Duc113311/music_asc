import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controller/settings_controller.dart';

/// Optional daily "come back and listen" notification (native alarm, see
/// NudgeScheduler.kt). Re-armed whenever the app is used, so it only reaches
/// someone who has not listened that day; it stops after a few ignored
/// nudges and can be switched off in Settings.
class NudgeService {
  NudgeService._();
  static const _channel = MethodChannel('com.asctechsoft.muvik/nudge');
  static const _hour = 19;

  /// Pushes the next nudge to tomorrow evening (or cancels it when off).
  static Future<void> refresh() async {
    try {
      if (!SettingsController.to.nudgeEnabled.value) {
        await _channel.invokeMethod<void>('cancel');
        return;
      }
      final day = DateTime.now().weekday % 3 + 1;
      await _channel.invokeMethod<void>('schedule', {
        'hour': _hour,
        'title': 'nudge_title_$day'.tr,
        'body': 'nudge_body_$day'.tr,
      });
    } on MissingPluginException {
      // Not on Android (tests, desktop): nothing to schedule.
    } on PlatformException {
      // Scheduling is best-effort.
    }
  }
}
