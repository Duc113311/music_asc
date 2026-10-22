import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controller/settings_controller.dart';
import '../application/audio_handler.dart';

/// Always-visible reminder notification (native, see OngoingNotification.kt).
/// It only exists to pull the user back into the app: tapping it (or its
/// button) opens Muvik. It shows the last song as a hook, or a generic nudge
/// when nothing has been played yet, and stays in the shade until switched off
/// in Settings. Text is localized here and pushed to the native side.
class OngoingNotificationService {
  OngoingNotificationService._();
  static const _channel = MethodChannel('com.asctechsoft.muvik/ongoing');

  static String? _lastKey;

  /// Pushes [state] to the notification, or removes it when the setting is off.
  static Future<void> sync(PlayerViewState state) async {
    if (!Get.isRegistered<SettingsController>()) return;
    try {
      if (!SettingsController.to.ongoingNotification.value) {
        if (_lastKey != 'off') {
          _lastKey = 'off';
          await _channel.invokeMethod<void>('disable');
        }
        return;
      }
      final song = state.currentSong;
      final title = song == null ? 'nudge_title_1'.tr : song.displayTitle;
      final desc = song == null
          ? 'nudge_body_1'.tr
          : (song.artistOrNull ?? 'unknown_artist'.tr);
      final key = '$title|$desc';
      if (key == _lastKey) return;
      _lastKey = key;
      await _channel.invokeMethod<void>('update', {
        'title': title,
        'desc': desc,
        'openLabel': 'ongoing_open'.tr,
        'channelName': 'ongoing_channel_name'.tr,
      });
    } on MissingPluginException {
      // Not on Android (tests, desktop): nothing to show.
    } on PlatformException {
      // Best-effort.
    }
  }

  /// Re-sync from the live player (after the setting or language changes).
  static Future<void> refresh() async {
    _lastKey = null;
    if (Get.isRegistered<MuvikAudioHandler>()) {
      await sync(Get.find<MuvikAudioHandler>().view.value);
    }
  }
}
