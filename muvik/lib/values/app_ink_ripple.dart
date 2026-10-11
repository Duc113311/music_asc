import 'dart:math' as math;

import 'package:flutter/material.dart';

// Flutter's InkRipple timings scaled to ~0.7×, so the tap feedback of the
// scan library screen feels snappier everywhere (Bug fix notes, "điểm chạm").
const Duration _kUnconfirmedRippleDuration = Duration(milliseconds: 700);
const Duration _kFadeInDuration = Duration(milliseconds: 50);
const Duration _kRadiusDuration = Duration(milliseconds: 160);
const Duration _kFadeOutDuration = Duration(milliseconds: 260);
const Duration _kCancelDuration = Duration(milliseconds: 50);

// The fade out begins once the radius expansion is done. See confirm().
const double _kFadeOutIntervalStart = 160.0 / 260.0;

/// Shared splash of every InkWell/InkResponse (set in AppTheme). Same look
/// as [InkRipple], only faster.
class AppInkRipple extends InteractiveInkFeature {
  AppInkRipple({
    required MaterialInkController controller,
    required super.referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    super.customBorder,
    double? radius,
    super.onRemoved,
  }) : _position = position,
       _borderRadius = borderRadius ?? BorderRadius.zero,
       _textDirection = textDirection,
       _targetRadius = radius ?? _targetRadiusFor(referenceBox, rectCallback),
       _clipCallback = _clipCallbackFor(
         referenceBox,
         containedInkWell,
         rectCallback,
       ),
       super(controller: controller, color: color) {
    _fadeInController =
        AnimationController(duration: _kFadeInDuration, vsync: controller.vsync)
          ..addListener(controller.markNeedsPaint)
          ..forward();
    _fadeIn = _fadeInController.drive(
      IntTween(begin: 0, end: (color.a * 255).round()),
    );

    _radiusController =
        AnimationController(
            duration: _kUnconfirmedRippleDuration,
            vsync: controller.vsync,
          )
          ..addListener(controller.markNeedsPaint)
          ..forward();
    _radius = _radiusController.drive(
      Tween<double>(
        begin: _targetRadius * 0.30,
        end: _targetRadius + 5.0,
      ).chain(_easeCurveTween),
    );

    _fadeOutController =
        AnimationController(
            duration: _kFadeOutDuration,
            vsync: controller.vsync,
          )
          ..addListener(controller.markNeedsPaint)
          ..addStatusListener(_handleAlphaStatusChanged);
    _fadeOut = _fadeOutController.drive(
      IntTween(
        begin: (color.a * 255).round(),
        end: 0,
      ).chain(_fadeOutIntervalTween),
    );

    controller.addInkFeature(this);
  }

  static const InteractiveInkFeatureFactory splashFactory = _Factory();

  static final Animatable<double> _easeCurveTween = CurveTween(
    curve: Curves.ease,
  );
  static final Animatable<double> _fadeOutIntervalTween = CurveTween(
    curve: const Interval(_kFadeOutIntervalStart, 1.0),
  );

  final Offset _position;
  final BorderRadius _borderRadius;
  final double _targetRadius;
  final RectCallback? _clipCallback;
  final TextDirection _textDirection;

  late Animation<double> _radius;
  late AnimationController _radiusController;
  late Animation<int> _fadeIn;
  late AnimationController _fadeInController;
  late Animation<int> _fadeOut;
  late AnimationController _fadeOutController;

  static RectCallback? _clipCallbackFor(
    RenderBox box,
    bool contained,
    RectCallback? rectCallback,
  ) {
    if (rectCallback != null) return rectCallback;
    if (contained) return () => Offset.zero & box.size;
    return null;
  }

  static double _targetRadiusFor(RenderBox box, RectCallback? rectCallback) {
    final size = rectCallback != null ? rectCallback().size : box.size;
    final d1 = size.bottomRight(Offset.zero).distance;
    final d2 =
        (size.topRight(Offset.zero) - size.bottomLeft(Offset.zero)).distance;
    return math.max(d1, d2) / 2.0;
  }

  @override
  void confirm() {
    _radiusController
      ..duration = _kRadiusDuration
      ..forward();
    // This confirm may have been preceded by a cancel.
    _fadeInController.forward();
    _fadeOutController.animateTo(1.0, duration: _kFadeOutDuration);
  }

  @override
  void cancel() {
    _fadeInController.stop();
    // Setting the value to 1.0 completes the controller, which disposes us.
    final fadeOutValue = 1.0 - _fadeInController.value;
    _fadeOutController.value = fadeOutValue;
    if (fadeOutValue < 1.0) {
      _fadeOutController.animateTo(1.0, duration: _kCancelDuration);
    }
  }

  void _handleAlphaStatusChanged(AnimationStatus status) {
    if (status.isCompleted) dispose();
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _fadeInController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    final alpha = _fadeInController.isAnimating
        ? _fadeIn.value
        : _fadeOut.value;
    final paint = Paint()..color = color.withAlpha(alpha);
    final rect = _clipCallback?.call();
    // Splash moves to the center of the reference box.
    final center = Offset.lerp(
      _position,
      rect != null ? rect.center : referenceBox.size.center(Offset.zero),
      Curves.ease.transform(_radiusController.value),
    )!;
    paintInkCircle(
      canvas: canvas,
      transform: transform,
      paint: paint,
      center: center,
      textDirection: _textDirection,
      radius: _radius.value,
      customBorder: customBorder,
      borderRadius: _borderRadius,
      clipCallback: _clipCallback,
    );
  }
}

class _Factory extends InteractiveInkFeatureFactory {
  const _Factory();

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) => AppInkRipple(
    controller: controller,
    referenceBox: referenceBox,
    position: position,
    color: color,
    containedInkWell: containedInkWell,
    rectCallback: rectCallback,
    borderRadius: borderRadius,
    customBorder: customBorder,
    radius: radius,
    onRemoved: onRemoved,
    textDirection: textDirection,
  );
}
