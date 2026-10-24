import 'dart:async';
import 'dart:math' as math;

import 'package:asc_common/asc_common.dart';
import 'package:dsp_base/dsp_base.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'configs/app_config.dart';
import 'configs/app_figs.dart';
import 'controller/settings_controller.dart';
import 'services/application/app_lifecycle_service.dart';
import 'services/native/system_ui_channel.dart';
import 'services/storage/pref_store.dart';
import 'utils/app_localize.dart';
import 'utils/app_log.dart';
import 'utils/route_analytics.dart';
import 'presentation/screen_splash/startup_gate.dart';
import 'values/app_pages.dart';
import 'values/app_theme.dart';
import 'values/route_name.dart';

/// The first frame is drawn right away by [StartupGate]; the start-up work runs
/// as bounded steps behind a boot screen (see [StartupGate] for why: a hung
/// step used to leave a blank white window on the first launch).
///
/// Order (P06-01), same skeleton as smart_drink on the shared base:
/// system UI -> prefs -> Firebase/Remote Config (dsp_base) -> date formats ->
/// locale + strings -> permanent controllers/services -> app.
/// DB, library and audio are initialized by the splash via BootstrapService.
Future<void> main() async {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(StartupGate(steps: _steps, builder: (_) => const MuvikApp()));
    },
    (error, stack) {
      if (DspFirebaseService.isCoreReady) {
        DspCrashlytics.recordError(error, stack, fatal: true);
      } else {
        AppLog.info('Uncaught error before Firebase: $error\n$stack');
      }
    },
  );
}

final List<StartupStep> _steps = [
  StartupStep(
    'orientation',
    () => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    timeout: const Duration(seconds: 2),
  ),
  StartupStep(
    'system ui',
    () => SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
    timeout: const Duration(seconds: 2),
  ),
  // Immersive: no device navigation bar at the bottom.
  StartupStep(
    'navigation bar',
    SystemUiChannel.hideNavigationBar,
    timeout: const Duration(seconds: 2),
  ),
  StartupStep('preferences', PrefStore.init, critical: true),
  StartupStep('firebase', _startDspBase, timeout: _dspBaseTimeout),
  StartupStep(
    'date formats',
    initializeDateFormatting,
    timeout: const Duration(seconds: 3),
  ),
  StartupStep('language', () async {
    await AppLocalize.ensureConfigured();
    await AppLocalize.loadTranslations();
  }, critical: true),
  // Permanent: survive route changes. The lifecycle hub goes first so screens
  // created later can subscribe to it. Idempotent: a retry re-runs this.
  StartupStep('services', () {
    if (!Get.isRegistered<AppLifecycleService>()) {
      Get.put(AppLifecycleService(), permanent: true);
    }
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController(), permanent: true);
    }
  }, critical: true),
];

/// Firebase (core + Crashlytics) and Remote Config, plus consent and AdMob
/// only when [AppConfig.adsEnabled]. Firebase only feeds Crashlytics and
/// Analytics: listening must work offline and without it, so a slow start is
/// cut off after [_dspBaseTimeout]. `DspBase.start` never throws.
const Duration _dspBaseTimeout = Duration(seconds: 6);

Future<void> _startDspBase() async {
  final started = AppConfig.adsEnabled
      ? DspBase.start(
          // App Check (Play Integrity is registered for com.asctechsoft.muvik in
          // the Firebase console) runs on the store flavor only: dev/alpha APKs
          // are sideloaded and would fail attestation.
          enableAppCheck: AppFigs.isProduct,
          hideAds: AppFigs.isAlpha,
          useTestAdIds: kDebugMode || AppFigs.isAlpha || AppFigs.isDev,
          registerTestAdDevice: AppFigs.isShowTestOption,
          debugEeaConsent: AppFigs.isShowTestOption,
        )
      : _startFirebaseOnly();
  await started;
}

Future<void> _startFirebaseOnly() async {
  DspBase.register();
  final firebaseUp = await DspFirebaseService.to.start(
    enableAppCheck: AppFigs.isProduct,
  );
  if (firebaseUp) await DspRemoteConfigRepository.to.start(defaults: const {});
}

class MuvikApp extends StatelessWidget {
  const MuvikApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsController.to;
    return Obx(() {
      final accent = settings.accent.value;
      return GetMaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        locale: AscLocale.getAppLocale(),
        fallbackLocale: AppLocalize.fallbackLocale,
        supportedLocales: AppLocalize.translatedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(accent),
        darkTheme: AppTheme.dark(accent),
        themeMode: settings.themeMode.value,
        initialRoute: RouteName.splash,
        getPages: AppPages.pages,
        routingCallback: RouteAnalytics.onRouting,
        defaultTransition: Transition.native,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // System font scale clamped 0.85-1.3 (the policy the previous base
            // applied), then 2 px smaller.
            textScaler: SmallerTextScaler(
              MediaQuery.textScalerOf(
                context,
              ).clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3),
            ),
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
