import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../values/app_colors.dart';

/// Blocking loading overlay and an inline spinner, same API as smart_drink.
class LoadingUtils {
  LoadingUtils._();

  static void show() {
    if (Get.isDialogOpen ?? false) return;
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;
    Get.dialog(
      PopScope(canPop: false, child: widget(context)),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
    );
  }

  /// Hides the currently visible loading overlay.
  static void hide() {
    if (Get.isDialogOpen ?? false) Get.back<void>();
  }

  static Widget widget(BuildContext context) =>
      Center(child: CircularProgressIndicator(color: context.colors.primary));
}
