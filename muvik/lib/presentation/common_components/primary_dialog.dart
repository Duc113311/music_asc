import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import 'primary_button.dart';

/// Dialog shell: max width 360, ≥24 from edges, radius 24, padding 24.
class AppDialog extends StatelessWidget {
  const AppDialog({super.key, required this.child, this.onClose});
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: c.surfaceElevated,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.dialogPadding),
              child: child,
            ),
            if (onClose != null)
              Positioned(
                right: 4,
                top: 4,
                child: IconButton(
                  tooltip: 'action_close'.tr,
                  icon: Icon(Icons.close_rounded, color: c.iconDefault),
                  onPressed: onClose,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialog. [onConfirm] runs with a pending state so the action
/// cannot be triggered twice; on failure the dialog stays open (P18-03).
/// Returns true when confirmed and the action completed.
Future<bool> showConfirmDialog({
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  IconData? icon,
  bool destructive = false,
  Future<void> Function()? onConfirm,
}) async {
  final r = await Get.dialog<bool>(
    _ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel ?? 'action_cancel'.tr,
      icon: icon,
      destructive: destructive,
      onConfirm: onConfirm,
    ),
    barrierDismissible: true,
  );
  return r ?? false;
}

class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.icon,
    required this.destructive,
    this.onConfirm,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData? icon;
  final bool destructive;
  final Future<void> Function()? onConfirm;

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  bool _pending = false;
  String? _error;

  Future<void> _confirm() async {
    if (_pending) return;
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      await widget.onConfirm?.call();
      if (mounted) Get.back(result: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _pending = false;
          _error = 'error_action_failed'.tr;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopScope(
      canPop: !_pending,
      child: AppDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (widget.destructive ? c.error : c.primary).withValues(
                    alpha: 0.14,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.destructive ? c.error : c.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTypography.headingS.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyM.copyWith(color: c.textSecondary),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(color: c.error),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: widget.cancelLabel,
                    variant: ButtonVariant.secondary,
                    onPressed: _pending
                        ? null
                        : () async => Get.back(result: false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: widget.confirmLabel,
                    variant: widget.destructive
                        ? ButtonVariant.destructive
                        : ButtonVariant.primary,
                    height: AppSizes.buttonSecondary,
                    loading: _pending,
                    onPressed: _confirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
