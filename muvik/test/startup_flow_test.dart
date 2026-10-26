import 'dart:ui';

import 'package:asc_common/asc_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:muvik/configs/pref_const.dart';
import 'package:muvik/controller/language_controller.dart';
import 'package:muvik/presentation/screen_splash/splash_screen.dart';
import 'package:muvik/presentation/screens_onboarding/language_screen.dart';
import 'package:muvik/presentation/common_components/cards.dart' show DetailAppBar;
import 'package:muvik/services/storage/pref_store.dart';
import 'package:muvik/utils/app_localize.dart';
import 'package:muvik/values/app_colors.dart';
import 'package:muvik/values/app_theme.dart';
import 'package:muvik/values/route_name.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  await PrefStore.init();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen.nextRoute: language -> onboarding -> setup -> home', () {
    test('fresh install starts at the language screen', () async {
      await _prefs({});
      expect(SplashScreen.nextRoute(), RouteName.language);
    });

    test('language chosen, onboarding not done -> onboarding', () async {
      await _prefs({PrefConst.languageChosen: true});
      expect(SplashScreen.nextRoute(), RouteName.onboarding);
    });

    test('onboarding done, setup not done -> setup', () async {
      await _prefs({
        PrefConst.languageChosen: true,
        PrefConst.onboardingCompleted: true,
      });
      expect(SplashScreen.nextRoute(), RouteName.setup);
    });

    test('everything done -> home', () async {
      await _prefs({
        PrefConst.languageChosen: true,
        PrefConst.onboardingCompleted: true,
        PrefConst.setupCompleted: true,
      });
      expect(SplashScreen.nextRoute(), RouteName.home);
    });

    test('an install from before the screen existed is not asked again', () async {
      // Onboarding finished earlier, language flag never written.
      await _prefs({PrefConst.onboardingCompleted: true});
      expect(SplashScreen.nextRoute(), RouteName.setup);
      await _prefs({
        PrefConst.onboardingCompleted: true,
        PrefConst.setupCompleted: true,
      });
      expect(SplashScreen.nextRoute(), RouteName.home);
    });
  });

  group('LanguageScreen', () {
    setUp(() async {
      Get.reset();
      await _prefs({});
      await AppLocalize.ensureConfigured();
      await AppLocalize.loadTranslations();
    });
    tearDown(Get.reset);

    testWidgets('lists the translated languages and applies a tap at once', (
      tester,
    ) async {
      Get.put(LanguageController());
      await tester.pumpWidget(GetMaterialApp(theme: AppTheme.dark(AccentColor.lavender), home: const LanguageScreen()));
      await tester.pump();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('Tiếng Việt'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      expect(AscLocale.getAppLocale().languageCode, 'vi');
      expect(PrefStore.getString(PrefConst.language, ''), 'vi_VN');
      expect(PrefStore.getBool(PrefConst.followSystemLanguage, true), isFalse);
      // The screen itself switched language.
      expect('language_title'.tr, 'Chọn ngôn ngữ của bạn');
    });

    test('offers all 16 languages that have a locale folder', () {
      final c = LanguageController();
      expect(c.languages, AppLocalize.translatedLocales);
      expect(c.languages.length, 16);
      expect(c.languages.take(2).map((l) => l.languageCode), ['en', 'vi']);
    });

    testWidgets('Settings variant has no Continue button', (tester) async {
      Get.put(LanguageController(fromSettings: true));
      await tester.pumpWidget(GetMaterialApp(theme: AppTheme.dark(AccentColor.lavender), home: const LanguageScreen()));
      await tester.pump();
      expect(find.text('action_continue'), findsNothing);
      expect(find.text('Continue'), findsNothing);
      expect(find.byType(DetailAppBar), findsOneWidget);
    });
  });

  test('language pref keys are stable', () {
    expect(PrefConst.language, 'language');
    expect(PrefConst.languageChosen, 'language_chosen');
    expect(const Locale('en', 'US').languageCode, 'en');
  });
}
