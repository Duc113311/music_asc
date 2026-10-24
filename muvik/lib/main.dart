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
import 'values/app_pages.dart';
import 'values/app_theme.dart';
import 'values/route_name.dart';

/// Startup order (P06-01), same skeleton as smart_drink on the shared base:
/// guarded zone -> system UI -> prefs -> Firebase/Remote Config (dsp_base) ->
/// locale -> strings -> permanent controllers/services -> app.
/// DB, library and audio are initialized by the splash via BootstrapService.
Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await _bootstrap();
      runApp(const MuvikApp());
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

Future<void> _bootstrap() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Immersive: no device navigation bar at the bottom.
  await SystemUiChannel.hideNavigationBar();

  await PrefStore.init();
  await _startDspBase();

  await initializeDateFormatting();
  await AppLocalize.ensureConfigured();
  await AppLocalize.loadTranslations();

  // Permanent: survive route changes. The lifecycle hub goes first so screens
  // created later can subscribe to it.
  Get.put(AppLifecycleService(), permanent: true);
  Get.put(SettingsController(), permanent: true);
}

/// Firebase (core + Crashlytics) and Remote Config, plus consent and AdMob
/// only when [AppConfig.adsEnabled]. Firebase only feeds Crashlytics and
/// Analytics: listening must work offline and without it, so a slow start is
/// cut off after [_dspBaseTimeout]. `DspBase.start` never throws.
const Duration _dspBaseTimeout = Duration(seconds: 6);

Future<void> _startDspBase() async {
  final started = AppConfig.adsEnabled
      ? DspBase.start(
          // App Check stays off, as before the base switch.
          enableAppCheck: false,
          hideAds: AppFigs.isAlpha,
          useTestAdIds: kDebugMode || AppFigs.isAlpha || AppFigs.isDev,
          registerTestAdDevice: AppFigs.isShowTestOption,
          debugEeaConsent: AppFigs.isShowTestOption,
        )
      : _startFirebaseOnly();
  await started.timeout(
    _dspBaseTimeout,
    onTimeout: () => AppLog.info('dsp_base start timed out, continuing'),
  );
}

Future<void> _startFirebaseOnly() async {
  DspBase.register();
  final firebaseUp = await DspFirebaseService.to.start(enableAppCheck: false);
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
