import 'dart:ui';

import 'package:asc_common/asc_common.dart';

import 'pref_const.dart';

/// Muvik's language setup for [AscLocale]: one locale per
/// `lib/xml_strings/values*/` folder (same 16 as smart_drink), all offered on
/// the language screen. EN and VI have real text; the other folders still hold
/// the English fallback until they are translated, so those languages show
/// English text for now.
class AppLocaleConfig {
  AppLocaleConfig._();

  static const Locale fallbackLocale = Locale('en', 'US');

  /// Languages offered to the user, one per `values*/` folder.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en', 'US'),
    Locale('vi', 'VN'),
    Locale('fr', 'FR'),
    Locale('it', 'IT'),
    Locale('de', 'DE'),
    Locale('es', 'ES'),
    Locale('ru', 'RU'),
    Locale('pt', 'PT'),
    Locale('tr', 'TR'),
    Locale('ar', 'SA'),
    Locale('id', 'ID'),
    Locale('fa', 'IR'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
    Locale('ja', 'JP'),
    Locale('ko', 'KR'),
  ];

  /// Call once at startup, before any [AscLocale] use.
  static void configure() => AscLocale.configure(
    supportedLocales: supportedLocales,
    languagePrefKey: PrefConst.language,
    followSystemPrefKey: PrefConst.followSystemLanguage,
  );
}
