import 'package:asc_common/asc_common.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// "Share the app" through the system share sheet, same helper as smart_drink.
class ShareUtils {
  ShareUtils._();

  /// App Store numeric id for the iOS link. Empty until the app is published:
  /// [AscShare.shareApp] then falls back to the Play Store link.
  static const String iosAppId = '';

  /// Opens the share sheet with an invite to install the app.
  static Future<void> shareApp(BuildContext context) => AscShare.shareApp(
    context,
    message: 'settings_share_message'.tr,
    iosAppId: iosAppId,
  );
}
