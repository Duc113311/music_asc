import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../values/app_colors.dart';
import '../values/app_dimensions.dart';
import '../values/app_typography.dart';

enum ToastType { info, success, warning, error }

/// Single toast overlay placed above the mini player / nav bar (P03-14).
/// Identical messages within [_dedupeWindow] are dropped and a new toast
/// replaces the old one, so a failing queue cannot stack toasts (P18-05).
class ToastUtils {
  ToastUtils._();

  /// Space reserved at the bottom by the shell (nav bar + mini player).
  static final ValueNotifier<double> bottomInset = ValueNotifier(0);

  static OverlayEntry? _entry;
  static Timer? _timer;
  static String? _lastMessage;
  static DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _dedupeWindow = Duration(seconds: 3);

  static void show(
    String message, {
    ToastType type = ToastType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final now = DateTime.now();
    if (message == _lastMessage && now.difference(_lastAt) < _dedupeWindow) {
      return;
    }
    _lastMessage = message;
    _lastAt = now;
    final overlay = Get.key.currentState?.overlay;
    if (overlay == null) return;
    hide();
    _entry = OverlayEntry(
      builder: (context) => _ToastView(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: () {
          hide();
          onAction?.call();
        },
      ),
    );
    overlay.insert(_entry!);
    _timer = Timer(duration, hide);
  }

  static void success(String m) => show(m, type: ToastType.success);
  static void error(String m) => show(m, type: ToastType.error);

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({
    required this.message,
    required this.type,
    this.actionLabel,
    required this.onAction,
  });

  final String message;
  final ToastType type;
  final String? actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (icon, color) = switch (type) {
      ToastType.success => (Icons.check_circle_rounded, c.success),
      ToastType.warning => (Icons.warning_amber_rounded, c.warning),
      ToastType.error => (Icons.error_rounded, c.error),
      ToastType.info => (Icons.info_rounded, c.info),
    };
    return ValueListenableBuilder<double>(
      valueListenable: ToastUtils.bottomInset,
      builder: (context, inset, _) => Positioned(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + inset + AppSpacing.md,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppMotion.state,
          curve: AppMotion.curve,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 12),
              child: child,
            ),
          ),
          child: Semantics(
            liveRegion: true,
            child: Material(
              color: c.surfaceElevated,
              elevation: 0,
              borderRadius: BorderRadius.circular(AppRadius.toast),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.toast),
                  border: Border.all(color: c.border),
                  boxShadow: [c.sheetShadow],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: AppSizes.iconSm),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        message,
                        style: AppTypography.bodyM.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    if (actionLabel != null)
                      TextButton(
                        onPressed: onAction,
                        child: Text(
                          actionLabel!,
                          style: AppTypography.label.copyWith(color: c.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
