import 'dart:ui';

import 'package:asc_common/asc_common.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../configs/locale_config.dart';
import '../configs/pref_const.dart';

/// Muvik's language policy on top of asc_common [AscLocale] (P00-09), the same
/// localization base smart_drink uses.
///
/// AscLocale loads the XML strings into GetX (`.tr`) and persists the chosen
/// locale under [PrefConst.language]. Muvik only ships real EN and VI text, so
/// any other device language resolves to English.
class AppLocalize {
  AppLocalize._();

  static const Locale fallbackLocale = AppLocaleConfig.fallbackLocale;

  /// Languages the app offers (all `values*/` folders). Only EN and VI are
  /// fully translated so far; the others show the English strings.
  static const List<Locale> translatedLocales =
      AppLocaleConfig.supportedLocales;

  /// Key the previous base (dsp_base 1.x `PrefComm`) stored the locale under;
  /// read once so an upgrade keeps the user's language.
  static const String _legacyLocaleKey = 'CONFIGURED_LOCALE_BY_USER';

  /// Saved choice if translated, else the best match for the device, else
  /// English. The result is saved so the next boot skips detection.
  static Future<Locale> ensureConfigured() async {
    AppLocaleConfig.configure();
    final prefs = await SharedPreferences.getInstance();
    final followSystem = prefs.getBool(PrefConst.followSystemLanguage) ?? false;
    final saved = followSystem
        ? null
        : _parse(
            prefs.getString(PrefConst.language) ??
                prefs.getString(_legacyLocaleKey),
          );
    final locale = saved != null && translatedLocales.contains(saved)
        ? saved
        : resolve(AscLocale.getSystemLocale());
    await AscLocale.setAppLocale(locale);
    return locale;
  }

  /// Muvik strings; call after [ensureConfigured] so the app language is known.
  static Future<void> loadTranslations() => AscLocale.loadTranslations();

  /// Best translated locale for [device], else English.
  static Locale resolve(Locale? device) {
    if (device == null) return fallbackLocale;
    // Same language and country first (zh_TW is not zh_CN), then the language.
    for (final l in translatedLocales) {
      if (l.languageCode == device.languageCode &&
          l.countryCode == device.countryCode) {
        return l;
      }
    }
    return translatedLocales.firstWhere(
      (l) => l.languageCode == device.languageCode,
      orElse: () => fallbackLocale,
    );
  }

  static Locale? _parse(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split('_');
    return parts.length == 2 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
  }
}
