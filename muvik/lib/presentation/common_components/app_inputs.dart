import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';

InputDecoration _decoration(
  BuildContext context, {
  String? hint,
  String? error,
  Widget? prefix,
  Widget? suffix,
}) {
  final c = context.colors;
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.input),
    borderSide: BorderSide(color: color, width: width),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTypography.bodyL.copyWith(color: c.textMuted),
    errorText: error,
    errorStyle: AppTypography.caption.copyWith(color: c.error),
    errorMaxLines: 3,
    filled: true,
    fillColor: c.surfaceInput,
    prefixIcon: prefix,
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    // Same 2 dp border in every state so focus never changes the outer size.
    enabledBorder: border(c.border, 2),
    focusedBorder: border(c.primary, 2),
    errorBorder: border(c.error, 2),
    focusedErrorBorder: border(c.error, 2),
    disabledBorder: border(c.divider, 2),
    counterStyle: AppTypography.caption.copyWith(color: c.textMuted),
  );
}

/// Single-line input (min height 52, radius 16, 16 sp — P03-11).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.error,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? error;
  final int? maxLength;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.label.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.inputHeight),
          child: TextField(
            controller: controller,
            enabled: enabled,
            autofocus: autofocus,
            maxLength: maxLength,
            onChanged: onChanged,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            scrollPadding: const EdgeInsets.only(bottom: 120),
            style: AppTypography.bodyL.copyWith(color: c.textPrimary),
            decoration: _decoration(
              context,
              hint: hint,
              error: error,
              suffix: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, v, _) => v.text.isEmpty || !enabled
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'action_clear'.tr,
                        icon: Icon(Icons.close_rounded, color: c.iconDefault),
                        onPressed: () {
                          controller.clear();
                          onChanged?.call('');
                        },
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Multi-line feedback/description input (min height 144).
class AppTextArea extends StatelessWidget {
  const AppTextArea({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.error,
    this.maxLength,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? error;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.label.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: controller,
          minLines: 5,
          maxLines: 8,
          maxLength: maxLength,
          onChanged: onChanged,
          scrollPadding: const EdgeInsets.only(bottom: 160),
          style: AppTypography.bodyL.copyWith(color: c.textPrimary),
          decoration: _decoration(context, hint: hint, error: error),
        ),
      ],
    );
  }
}

/// Search box with clear button.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    required this.hint,
    this.onChanged,
    this.onTap,
    this.autofocus = false,
    this.readOnly = false,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autofocus;
  final bool readOnly;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ctrl = controller;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.inputHeight),
      child: TextField(
        controller: ctrl,
        focusNode: focusNode,
        autofocus: autofocus,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyL.copyWith(color: c.textPrimary),
        decoration: _decoration(
          context,
          hint: hint,
          prefix: Icon(Icons.search_rounded, color: c.iconDefault),
          suffix: ctrl == null || readOnly
              ? null
              : ValueListenableBuilder<TextEditingValue>(
                  valueListenable: ctrl,
                  builder: (context, v, _) => v.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: 'action_clear'.tr,
                          icon: Icon(Icons.close_rounded, color: c.iconDefault),
                          onPressed: () {
                            ctrl.clear();
                            onChanged?.call('');
                          },
                        ),
                ),
        ),
      ),
    );
  }
}
