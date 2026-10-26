import 'dart:ui';

import 'package:asc_common/asc_common.dart';
import 'package:get/get.dart';

import '../configs/pref_const.dart';
import '../services/storage/pref_store.dart';
import '../utils/app_localize.dart';
import '../values/route_name.dart';

/// Language picker, used twice: on first run between Splash and Onboarding
/// (a "Continue" button finishes it) and from Settings (every tap applies at
/// once, Back returns). Every language of [AppLocalize.translatedLocales] is
/// offered (all 16 locale folders); untranslated ones show English text.
class LanguageController extends GetxController {
  /// True when opened from Settings.
  final bool fromSettings;

  LanguageController({this.fromSettings = false});

  List<Locale> get languages => AppLocalize.translatedLocales;

  late final Rx<Locale> selected = _current().obs;

  /// The locale in use, matched to one of [languages] by language code.
  Locale _current() => AppLocalize.resolve(AscLocale.getAppLocale());

  /// Applies [locale] right away: the whole UI switches without rebuilding the
  /// route stack, and the choice is saved as an explicit pin (no longer
  /// "follow the system").
  Future<void> select(Locale locale) async {
    if (locale == selected.value) return;
    selected.value = locale;
    await PrefStore.setBool(PrefConst.followSystemLanguage, false);
    await AscLocale.setAppLocale(locale);
  }

  /// First-run "Continue": remember the language was chosen, go to Onboarding.
  Future<void> confirm() async {
    await PrefStore.setBool(PrefConst.languageChosen, true);
    if (fromSettings) {
      Get.back<void>();
    } else {
      Get.offNamed<void>(RouteName.onboarding);
    }
  }
}
