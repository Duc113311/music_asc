import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';

/// Opens a modal sheet (radius 24, max 90% height, handle 36×4). Only one
/// sheet at a time: an open sheet is closed before another opens (P18-08).
Future<T?> showAppSheet<T>({
  required Widget Function(BuildContext) builder,
  bool scrollControlled = true,
}) async {
  final ctx = Get.context;
  if (ctx == null) return null;
  if (Get.isBottomSheetOpen ?? false) Get.back<void>();
  return showModalBottomSheet<T>(
    context: ctx,
    isScrollControlled: scrollControlled,
    useSafeArea: true,
    showDragHandle: false,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.9),
    builder: (c) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
      child: builder(c),
    ),
  );
}

/// Standard sheet body: handle, optional title/subtitle/trailing, content.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.footer,
    this.scrollable = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final Widget? footer;
  final bool scrollable;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              width: AppSizes.sheetHandleW,
              height: AppSizes.sheetHandleH,
              decoration: BoxDecoration(
                color: c.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: AppTypography.headingS.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: AppTypography.bodyM.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            )
          else
            const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: scrollable
                ? SingleChildScrollView(padding: padding, child: child)
                : Padding(padding: padding, child: child),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: footer,
            )
          else
            const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// Row inside an action sheet.
class SheetActionTile extends StatelessWidget {
  const SheetActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.trailing,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final Widget? trailing;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = destructive ? c.error : (selected ? c.primary : c.textPrimary);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Icon(
                icon,
                color: destructive
                    ? c.error
                    : (selected ? c.primary : c.iconDefault),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyL.copyWith(color: fg),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
