import 'dart:ui';

import 'package:asc_common/asc_common.dart';

import 'pref_const.dart';

/// Muvik's language setup for [AscLocale]. Only EN and VI have real text; the
/// other `lib/xml_strings/values-*` folders hold the English fallback
/// (tool/gen_strings.py), so a device in any other language resolves to English.
class AppLocaleConfig {
  AppLocaleConfig._();

  static const Locale fallbackLocale = Locale('en', 'US');

  /// Languages with a real Muvik translation, one per translated `values*/`.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en', 'US'),
    Locale('vi', 'VN'),
  ];

  /// Call once at startup, before any [AscLocale] use.
  static void configure() => AscLocale.configure(
    supportedLocales: supportedLocales,
    languagePrefKey: PrefConst.language,
    followSystemPrefKey: PrefConst.followSystemLanguage,
  );
}
