import 'dart:math' as math;

import 'package:dsp_base/app_localize.dart';
import 'package:dsp_base/comm_app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'controller/settings_controller.dart';
import 'services/native/system_ui_channel.dart';
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
  // Immersive: no device navigation bar at the bottom.
  await SystemUiChannel.hideNavigationBar();
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: SmallerTextScaler(MediaQuery.textScalerOf(context)),
          ),
          child: child!,
        ),
      );
    });
  }
}

/// Every font in the app 2 px smaller than its design size (bug fix notes,
/// "Giảm font chữ toàn app xuống 2px"), on top of the user's system scale.
/// Tiny labels never go below [minFontSize].
class SmallerTextScaler extends TextScaler {
  const SmallerTextScaler(this.base);

  final TextScaler base;

  static const double delta = 2;
  static const double minFontSize = 8;

  @override
  double scale(double fontSize) => base.scale(
    fontSize <= minFontSize
        ? fontSize
        : math.max(minFontSize, fontSize - delta),
  );

  @override
  // Required override; kept in sync with [base].
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor;

  @override
  bool operator ==(Object other) =>
      other is SmallerTextScaler && other.base == base;

  @override
  int get hashCode => Object.hash(SmallerTextScaler, base);
}
