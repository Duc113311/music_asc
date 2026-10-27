import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../configs/pref_const.dart';
import '../configs/pref_defaults.dart';
import '../services/native/nudge_service.dart';
import '../services/storage/pref_store.dart';
import '../values/app_colors.dart';

/// Appearance and headphone preferences (the language lives in asc_common
/// CommLocalize, see AppLocalize). Theme changes rebuild the
/// app theme only — the player and queue are untouched (P14-12).
class SettingsController extends GetxController {
  static SettingsController get to => Get.find();

  final Rx<ThemeMode> themeMode = ThemeMode.dark.obs;
  final Rx<AccentColor> accent = AccentColor.lavender.obs;

  /// Now Playing background: blurred cover art, or the fixed theme gradient.
  final RxBool playerBlurBackground =
      (PrefDefaults.playerBackground == 'blur').obs;

  /// Route animations on/off (applied by AppPages' transition middleware).
  final RxBool screenTransitions = PrefDefaults.screenTransitions.obs;

  final RxBool pauseOnDisconnect = PrefDefaults.headphonePauseOnDisconnect.obs;
  final RxBool resumeOnConnect = PrefDefaults.headphoneResumeOnConnect.obs;
  final RxBool headphoneButtons = PrefDefaults.headphoneButtonsEnabled.obs;

  /// Daily "come back and listen" reminder (NudgeService).
  final RxBool nudgeEnabled = PrefDefaults.nudgeEnabled.obs;

  /// Scan automatically when music is added or removed (off: toast + button).
  final RxBool autoScanNewMusic = PrefDefaults.autoScanNewMusic.obs;


  @override
  void onInit() {
    super.onInit();
    themeMode.value = _parseTheme(
      PrefStore.getString(PrefConst.themeMode, PrefDefaults.themeMode),
    );
    accent.value = AccentColor.fromKey(
      PrefStore.getString(PrefConst.accentColor, PrefDefaults.accentColor),
    );
    playerBlurBackground.value = PrefStore.getString(
          PrefConst.playerBackground,
          PrefDefaults.playerBackground,
        ) ==
        'blur';
    screenTransitions.value = PrefStore.getBool(
      PrefConst.screenTransitions,
      PrefDefaults.screenTransitions,
    );
    pauseOnDisconnect.value = PrefStore.getBool(
      PrefConst.headphonePauseOnDisconnect,
      PrefDefaults.headphonePauseOnDisconnect,
    );
    resumeOnConnect.value = PrefStore.getBool(
      PrefConst.headphoneResumeOnConnect,
      PrefDefaults.headphoneResumeOnConnect,
    );
    headphoneButtons.value = PrefStore.getBool(
      PrefConst.headphoneButtonsEnabled,
      PrefDefaults.headphoneButtonsEnabled,
    );
    nudgeEnabled.value = PrefStore.getBool(
      PrefConst.nudgeEnabled,
      PrefDefaults.nudgeEnabled,
    );
    autoScanNewMusic.value = PrefStore.getBool(
      PrefConst.autoScanNewMusic,
      PrefDefaults.autoScanNewMusic,
    );
  }

  static ThemeMode _parseTheme(String v) => switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String themeKey(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  String get themeLabelKey => switch (themeMode.value) {
        ThemeMode.light => 'theme_light',
        ThemeMode.dark => 'theme_dark',
        ThemeMode.system => 'theme_system',
      };

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode.value = m;
    await PrefStore.setString(PrefConst.themeMode, themeKey(m));
  }

  Future<void> setAccent(AccentColor a) async {
    accent.value = a;
    await PrefStore.setString(PrefConst.accentColor, a.key);
  }

  Future<void> setPlayerBlurBackground(bool blur) async {
    playerBlurBackground.value = blur;
    await PrefStore.setString(
      PrefConst.playerBackground,
      blur ? 'blur' : 'solid',
    );
  }

  Future<void> setScreenTransitions(bool v) async {
    screenTransitions.value = v;
    await PrefStore.setBool(PrefConst.screenTransitions, v);
  }

  Future<void> setAutoScanNewMusic(bool v) async {
    autoScanNewMusic.value = v;
    await PrefStore.setBool(PrefConst.autoScanNewMusic, v);
  }

  Future<void> setNudgeEnabled(bool v) async {
    nudgeEnabled.value = v;
    await PrefStore.setBool(PrefConst.nudgeEnabled, v);
    await NudgeService.refresh();
  }

  Future<void> setPauseOnDisconnect(bool v) async {
    pauseOnDisconnect.value = v;
    await PrefStore.setBool(PrefConst.headphonePauseOnDisconnect, v);
  }

  Future<void> setResumeOnConnect(bool v) async {
    resumeOnConnect.value = v;
    await PrefStore.setBool(PrefConst.headphoneResumeOnConnect, v);
  }

  Future<void> setHeadphoneButtons(bool v) async {
    headphoneButtons.value = v;
    await PrefStore.setBool(PrefConst.headphoneButtonsEnabled, v);
  }
}
