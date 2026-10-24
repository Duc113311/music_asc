import 'package:flutter/material.dart';

import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';

/// 24×24 radio, 2 dp ring, 12 dp dot (Design System §7).
class AppRadio extends StatelessWidget {
  const AppRadio({
    super.key,
    required this.selected,
    this.enabled = true,
    this.size = 24,
  });
  final bool selected;
  final bool enabled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.primary : c.textMuted;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: AnimatedContainer(
        duration: AppMotion.state,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: AppMotion.state,
          width: selected ? size / 2 : 0,
          height: selected ? size / 2 : 0,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.primary),
        ),
      ),
    );
  }
}

/// 24×24 checkbox; `null` value renders the indeterminate dash.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({super.key, required this.value, this.enabled = true});
  final bool? value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final on = value != false;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: AnimatedContainer(
        duration: AppMotion.state,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: on ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: on ? c.primary : c.textMuted, width: 2),
        ),
        child: on
            ? Icon(
                value == null ? Icons.remove_rounded : Icons.check_rounded,
                size: 18,
                color: c.onPrimary,
              )
            : null,
      ),
    );
  }
}

/// Track 48×28, thumb 24.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.semanticLabel,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: enabled ? () => onChanged!(!value) : null,
          customBorder: const StadiumBorder(),
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          child: SizedBox(
            width: AppSizes.touch + 8,
            height: AppSizes.touch,
            child: Center(
              child: Opacity(
                opacity: enabled ? 1 : 0.4,
                child: AnimatedContainer(
                  duration: AppMotion.state,
                  curve: AppMotion.curve,
                  width: 44,
                  height: 25,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: value ? c.primary : c.border,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  // White thumb in both states, as in every settings mockup.
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF7F6FB),
                      boxShadow: [
                        BoxShadow(color: Color(0x33000000), blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter chip: height 36, padding 14, touch target ≥ 48.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.accent,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.primary : (accent ?? c.textSecondary);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.touch),
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: AppMotion.state,
              decoration: BoxDecoration(
                color: selected ? c.surfaceSelected : c.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: selected
                      ? c.primary
                      : (accent?.withValues(alpha: 0.6) ?? c.border),
                ),
              ),
              // Ripple above the chip fill (InkWell on a transparent Material).
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  customBorder: const StadiumBorder(),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: AppSizes.chipHeight,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: AppSizes.iconSm, color: fg),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label,
                          style: AppTypography.label.copyWith(color: fg),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Week/Month/Year style segmented tabs (height 48, radius 14, padding 4).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.tabs),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                child: AnimatedContainer(
                  duration: AppMotion.state,
                  decoration: BoxDecoration(
                    color: i == index ? c.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.tabs - 4),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () => onChanged(i),
                      borderRadius: BorderRadius.circular(AppRadius.tabs - 4),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 40),
                        alignment: Alignment.center,
                        child: Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          style: AppTypography.label.copyWith(
                            color: i == index ? c.onPrimary : c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Selectable row with radio/checkbox, used by sheets and settings screens.
class SelectableOptionTile extends StatelessWidget {
  const SelectableOptionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.multi = false,
    this.leading,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool multi;
  final Widget? leading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          color: selected ? c.surfaceSelected.withValues(alpha: 0.5) : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyL.copyWith(
                        color: enabled ? c.textPrimary : c.textDisabled,
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
              const SizedBox(width: AppSpacing.sm),
              multi
                  ? AppCheckbox(value: selected, enabled: enabled)
                  : AppRadio(selected: selected, enabled: enabled),
            ],
          ),
        ),
      ),
    );
  }
}
