import 'package:flutter/material.dart';

import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';

enum ButtonVariant { primary, gradient, secondary, tertiary, destructive }

/// CTA with normal/pressed/disabled/loading. A tap while an async action is
/// running is ignored, preventing double submits (P03-09).
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = true,
    this.height,
  });

  final String label;
  final Future<void> Function()? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final bool expand;
  final double? height;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _busy = false;
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null;
  bool get _loading => widget.loading || _busy;

  Future<void> _tap() async {
    if (_disabled || _loading) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final v = widget.variant;
    final height =
        widget.height ??
        (v == ButtonVariant.primary || v == ButtonVariant.gradient
            ? AppSizes.buttonPrimary
            : AppSizes.buttonSecondary);

    Color bg;
    Color fg;
    Gradient? gradient;
    BoxBorder? border;
    switch (v) {
      case ButtonVariant.primary:
        bg = _pressed ? c.primaryPressed : c.primary;
        fg = c.onPrimary;
      case ButtonVariant.gradient:
        bg = c.primary;
        fg = c.onPrimary;
        gradient = LinearGradient(colors: c.ctaGradient);
      case ButtonVariant.secondary:
        bg = _pressed ? c.primary.withValues(alpha: 0.12) : Colors.transparent;
        fg = c.primary;
        border = Border.all(color: c.border);
      case ButtonVariant.tertiary:
        bg = _pressed ? c.primary.withValues(alpha: 0.12) : Colors.transparent;
        fg = c.primary;
      case ButtonVariant.destructive:
        bg = c.error;
        fg = AppColors.onDestructive;
    }
    if (_disabled) {
      bg = v == ButtonVariant.tertiary ? Colors.transparent : c.surfaceInput;
      fg = c.textDisabled;
      gradient = null;
    }

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_loading)
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else ...[
          if (widget.icon != null) ...[
            Icon(widget.icon, color: fg, size: AppSizes.icon),
            const SizedBox(width: AppSpacing.xs),
          ],
          // Single line; shrinks instead of wrapping when the slot is narrow.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.label,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(color: fg, fontSize: 16),
              ),
            ),
          ),
          if (widget.trailingIcon != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(widget.trailingIcon, color: fg, size: AppSizes.icon),
          ],
        ],
      ],
    );

    final radius = BorderRadius.circular(
      v == ButtonVariant.primary || v == ButtonVariant.gradient
          ? AppRadius.full
          : AppRadius.button,
    );
    return Semantics(
      button: true,
      enabled: !_disabled,
      label: widget.label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.press,
        curve: AppMotion.curve,
        width: widget.expand ? double.infinity : null,
        decoration: BoxDecoration(
          color: gradient == null ? bg : null,
          gradient: gradient,
          borderRadius: radius,
          border: border,
        ),
        // Ripple drawn above the fill/gradient (shared splash, AppTheme).
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTapDown: _disabled
                ? null
                : (_) => setState(() => _pressed = true),
            onTapUp: _disabled ? null : (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: _disabled ? null : _tap,
            borderRadius: radius,
            child: Container(
              constraints: BoxConstraints(minHeight: height),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Center(
                widthFactor: widget.expand ? null : 1,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
