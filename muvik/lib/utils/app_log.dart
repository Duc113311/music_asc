import 'package:dsp_base/dsp_base.dart';
import 'package:flutter/foundation.dart';

import '../configs/app_figs.dart';

/// Logging on top of dsp_base: [info] prints only on alpha/dev/claude builds,
/// [error] also records a non-fatal in Crashlytics once Firebase is up.
///
/// Most failures logged here are expected (missing file, cancelled sign-in),
/// so nothing is toasted to the user.
class AppLog {
  AppLog._();

  /// Expected or recoverable condition: dev log only.
  static void info(String message) {
    if (kDebugMode || AppFigs.isShowTestOption) debugPrint(message);
  }

  /// Unexpected failure that the app recovered from: dev log + Crashlytics
  /// non-fatal. Never pass tokens or personal data in [hint] or [error].
  static void error(String hint, Object error, [StackTrace? stack]) {
    info('$hint: $error${stack == null ? '' : '\n$stack'}');
    if (!DspFirebaseService.isCoreReady) return;
    DspCrashlytics.recordError(
      error,
      stack ?? StackTrace.current,
      reason: hint,
    ).catchError((Object _) {});
  }
}
