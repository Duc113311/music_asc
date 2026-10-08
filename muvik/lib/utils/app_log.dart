import 'package:dsp_base/convenience_imports.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Logging on top of dsp_base: [debugLog] prints only on alpha/dev flavors.
///
/// Not using dsp_base `commCrashOnTry` here: it needs Firebase (breaks unit
/// tests) and toasts every caught error on non-product builds, while most
/// failures below are expected (missing file, cancelled sign-in).
class AppLog {
  AppLog._();

  /// Expected or recoverable condition: dev log only.
  static void info(String message) => debugLog(message);

  /// Unexpected failure that the app recovered from: dev log + Crashlytics
  /// non-fatal. Never pass tokens or personal data in [hint] or [error].
  static void error(String hint, Object error, [StackTrace? stack]) {
    debugLog('$hint: $error${stack == null ? '' : '\n$stack'}');
    if (Firebase.apps.isEmpty) return;
    FirebaseCrashlytics.instance
        .recordError(error, stack, reason: hint)
        .catchError((Object _) {});
  }
}
