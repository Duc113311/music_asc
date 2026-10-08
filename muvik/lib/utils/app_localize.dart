import 'dart:ui';

import 'package:dsp_base/app_localize.dart';
import 'package:dsp_base/convenience_imports.dart';

/// Muvik's language policy on top of dsp_base [CommLocalize] (P00-09).
///
/// CommLocalize loads the XML strings into GetX and keeps the chosen locale in
/// `PrefComm.CONFIGURED_LOCALE_BY_USER`. Muvik only ships real EN and VI text;
/// the other CommLocalize folders hold the English fallback
/// (tool/gen_strings.py), so any other language shows English.
class AppLocalize {
  AppLocalize._();

  static const Locale fallbackLocale = Locale('en', 'US');

  /// Languages with a real Muvik translation.
  static const List<Locale> translatedLocales = [
    Locale('en', 'US'),
    Locale('vi', 'VN'),
  ];

  /// Saved choice if translated, else the best match for the device, else
  /// English. The result is saved so the next boot skips detection.
  static Future<Locale> ensureConfigured() async {
    final saved = CommLocalize.getConfiguredLocale();
    if (saved != null && translatedLocales.contains(saved)) return saved;
    final best = resolve(CommLocalize.getSystemLocale());
    await PrefAssist.setString(
      PrefComm.CONFIGURED_LOCALE_BY_USER,
      best.toString(),
    );
    return best;
  }

  /// Muvik strings; call after [ensureConfigured] so the app language is known.
  static Future<void> loadTranslations() =>
      CommLocalize.loadTranslations('lib/xml_strings', 'strings.xml');

  /// Best translated locale for [device], else English.
  static Locale resolve(Locale? device) {
    if (device == null) return fallbackLocale;
    return translatedLocales.firstWhere(
      (l) => l.languageCode == device.languageCode,
      orElse: () => fallbackLocale,
    );
  }
}
