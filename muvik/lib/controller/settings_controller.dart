import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../configs/pref_const.dart';
import '../configs/pref_defaults.dart';
import '../services/storage/pref_store.dart';
import '../values/app_colors.dart';

/// Appearance and headphone preferences (the language lives in dsp_base
/// CommLocalize, see AppLocalize). Theme changes rebuild the
/// app theme only — the player and queue are untouched (P14-12).
class SettingsController extends GetxController {
  static SettingsController get to => Get.find();

  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final Rx<AccentColor> accent = AccentColor.lavender.obs;

  final RxBool pauseOnDisconnect = PrefDefaults.headphonePauseOnDisconnect.obs;
  final RxBool resumeOnConnect = PrefDefaults.headphoneResumeOnConnect.obs;
  final RxBool headphoneButtons = PrefDefaults.headphoneButtonsEnabled.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = _parseTheme(
      PrefStore.getString(PrefConst.themeMode, PrefDefaults.themeMode),
    );
    accent.value = AccentColor.fromKey(
      PrefStore.getString(PrefConst.accentColor, PrefDefaults.accentColor),
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
