import 'package:asc_common/asc_common.dart';

/// Build-flavor flags: thin alias over [AscBuildFlavor], same as smart_drink.
/// Flavor names match `--flavor` in `android/app/build.gradle.kts`
/// (`alpha`, `dev`, `product`, `claude`).
class AppFigs {
  AppFigs._();

  static const bool isAlpha = AscBuildFlavor.isAlpha;
  static const bool isDev = AscBuildFlavor.isDev;
  static const bool isProduct = AscBuildFlavor.isProduct;
  static const bool isClaude = AscBuildFlavor.isClaude;

  /// Gates debug-only affordances (dev logging, test ad ids, debug screens):
  /// everywhere except a shipped Product build.
  static const bool isShowTestOption = AscBuildFlavor.isShowTestOption;
}
