import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import 'primary_button.dart';

/// Empty state with an optional CTA (e.g. "Quét nhạc", "Cấp quyền").
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.illustration = false,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.compact = false,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final bool illustration;
  final String? actionLabel;
  final Future<void> Function()? onAction;
  final String? secondaryLabel;
  final Future<void> Function()? onSecondary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: compact ? AppSpacing.lg : AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (illustration)
            Image.asset(AppAssets.emptyLibrary, width: 220, fit: BoxFit.contain)
          else
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.surfaceSelected,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.library_music_rounded,
                color: c.primary,
                size: 32,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headingS.copyWith(color: c.textPrimary),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTypography.bodyM.copyWith(color: c.textSecondary),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: actionLabel!,
              onPressed: onAction,
              expand: false,
            ),
          ],
          if (secondaryLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            PrimaryButton(
              label: secondaryLabel!,
              onPressed: onSecondary,
              variant: ButtonVariant.tertiary,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Error that stays on screen with a retry for the failed action only.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.error_outline_rounded,
    title: 'error_title'.tr,
    message: message,
    actionLabel: onRetry == null ? null : 'action_retry'.tr,
    onAction: onRetry,
  );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: c.primary),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyM.copyWith(color: c.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline banner (e.g. "Chưa có quyền truy cập âm thanh · Cấp quyền").
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.error_rounded,
    this.color,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? c.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                message,
                style: AppTypography.bodyM.copyWith(color: c.textPrimary),
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                actionLabel!,
                style: AppTypography.label.copyWith(color: c.primary),
              ),
            ),
        ],
      ),
    );
  }
}
