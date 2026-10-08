import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';

/// Ripple wrapper with opaque hit-testing (no dead zones).
class AppTouchable extends StatelessWidget {
  const AppTouchable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final w = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: borderRadius,
        child: child,
      ),
    );
    return semanticLabel == null
        ? w
        : Semantics(button: true, label: semanticLabel, child: w);
  }
}

/// Icon button with a 48×48 touch target regardless of icon size (P03-10).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.active = false,
    this.size = AppSizes.icon,
    this.color,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;
  final double size;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = onPressed == null
        ? c.textDisabled
        : (color ?? (active ? c.primary : c.iconDefault));
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        selected: active,
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: AppSizes.touch,
          child: Material(
            type: MaterialType.transparency,
            child: InkResponse(
              onTap: onPressed,
              radius: AppSizes.touch / 2,
              child: Center(
                child: filled
                    ? Container(
                        width: AppSizes.touch - 4,
                        height: AppSizes.touch - 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.surface,
                          border: Border.all(color: c.border),
                        ),
                        child: Icon(icon, size: size, color: fg),
                      )
                    : Icon(icon, size: size, color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round play/pause button: large (80) on Now Playing, mini (48) elsewhere.
class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    super.key,
    required this.playing,
    required this.onPressed,
    this.loading = false,
    this.large = false,
  });

  final bool playing;
  final bool loading;
  final bool large;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dim = large ? AppSizes.playLarge : AppSizes.playMini;
    final iconSize = large ? AppSizes.iconLg + 8 : AppSizes.icon;
    final label = playing ? 'action_pause'.tr : 'action_play'.tr;
    return Semantics(
      button: true,
      label: label,
      child: SizedBox.square(
        dimension: dim < AppSizes.touch ? AppSizes.touch : dim,
        child: Material(
          color: onPressed == null ? c.surfaceInput : c.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Center(
              child: loading
                  ? SizedBox.square(
                      dimension: large ? 28 : 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: c.onPrimary,
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: AppMotion.state,
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(playing),
                        size: iconSize,
                        color: onPressed == null ? c.textDisabled : c.onPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
