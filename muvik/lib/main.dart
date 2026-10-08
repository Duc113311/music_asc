import 'package:dsp_base/app_localize.dart';
import 'package:dsp_base/comm_app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'controller/settings_controller.dart';
import 'utils/app_localize.dart';
import 'utils/app_log.dart';
import 'values/app_pages.dart';
import 'values/app_theme.dart';
import 'values/route_name.dart';

/// dsp_base `commRunApp` initializes PrefAssist, its own strings and device
/// class, runs [_onBindingInitialized], then wires Crashlytics when Firebase
/// is up. Order (P06-01): Firebase → locale → strings → settings → app.
/// DB, library and audio are initialized by the splash via BootstrapService.
Future<void> main() => commRunApp(
  () => const MuvikApp(),
  onBindingInitialized: _onBindingInitialized,
);

Future<void> _onBindingInitialized(WidgetsBinding binding) async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Firebase only feeds Crashlytics/Analytics: listening must work without it.
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 5));
  } catch (e) {
    AppLog.info('Firebase.initializeApp skipped: $e');
  }
  await initializeDateFormatting();
  await AppLocalize.ensureConfigured();
  await AppLocalize.loadTranslations();
  Get.put(SettingsController(), permanent: true);
}

class MuvikApp extends StatelessWidget {
  const MuvikApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsController.to;
    return Obx(() {
      final accent = settings.accent.value;
      return CommApp(
        title: 'Muvik',
        debugShowCheckedModeBanner: false,
        locale: CommLocalize.getAppLocale(),
        fallbackLocale: AppLocalize.fallbackLocale,
        theme: AppTheme.light(accent),
        darkTheme: AppTheme.dark(accent),
        themeMode: settings.themeMode.value,
        initialRoute: RouteName.splash,
        getPages: AppPages.pages,
        defaultTransition: Transition.native,
      );
    });
  }
}
