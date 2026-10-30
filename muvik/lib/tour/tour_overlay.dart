import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../values/app_colors.dart';
import 'tour_controller.dart';
import 'tour_steps.dart';

/// Mounted once, above the navigator (`MuvikApp.builder`), so it can
/// spotlight a widget on any route. Renders nothing while the tour is not
/// active.
class TourOverlay extends StatelessWidget {
  const TourOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TourController>()) return child;
    final controller = Get.find<TourController>();
    return Stack(
      children: [
        child,
        Obx(() {
          // Depend on both so a late anchor re-measures and Next/Back swap
          // the step.
          controller.anchorGeneration.value;
          controller.index.value;
          if (!controller.active.value) return const SizedBox.shrink();
          return _TourStepView(controller: controller);
        }),
      ],
    );
  }
}

class _TourStepView extends StatefulWidget {
  const _TourStepView({required this.controller});

  final TourController controller;

  @override
  State<_TourStepView> createState() => _TourStepViewState();
}

class _TourStepViewState extends State<_TourStepView>
    with SingleTickerProviderStateMixin {
  static const double _gap = 22; // between target and bubble (arrow lives here)
  static const double _arrowW = 26;
  static const double _arrowH = 14;
  static const double _margin = 20;

  // Drives the pulsing ring and the bobbing arrow.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final step = controller.step;
    final target = controller.anchorRect(step.anchorId);
    final size = MediaQuery.of(context).size;

    if (target == null) {
      // Not laid out yet (registered this frame): retry next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return const SizedBox.shrink();
    }

    // The tabs sit at the bottom, so the bubble goes above them.
    final below = target.center.dy < size.height / 2;
    final accent = context.colors.primary;

    // First step: the scrim fades in while the hole shrinks onto the target.
    // Later steps: the hole glides from the previous target to the new one.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, intro, _) => TweenAnimationBuilder<Rect?>(
        tween: RectTween(end: target.inflate(4)),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        builder: (context, rect, _) => Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.next,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) => CustomPaint(
                      painter: _HolePainter(
                        rect: rect!,
                        radius: step.radius,
                        intro: intro,
                        pulse: _pulse.value,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
              _arrow(size, target, below, accent),
              _bubble(size, target, below, step, controller, accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _arrow(Size size, Rect target, bool below, Color color) {
    final x = (target.center.dx - _arrowW / 2).clamp(
      _margin + 8,
      size.width - _margin - 8 - _arrowW,
    );
    final top = below
        ? target.bottom + (_gap - _arrowH) / 2
        : target.top - _gap + (_gap - _arrowH) / 2;
    return Positioned(
      left: x,
      top: top,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            // Nudges toward the target and back.
            final bob = math.sin(_pulse.value * 2 * math.pi) * 2;
            return Transform.translate(
              offset: Offset(0, below ? -bob : bob),
              child: child,
            );
          },
          child: CustomPaint(
            size: const Size(_arrowW, _arrowH),
            painter: _ArrowPainter(pointUp: below, color: color),
          ),
        ),
      ),
    );
  }

  Widget _bubble(
    Size size,
    Rect target,
    bool below,
    TourStep step,
    TourController controller,
    Color accent,
  ) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  step.titleKey.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!controller.isLast)
                GestureDetector(
                  onTap: controller.finish,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'tour_skip'.tr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            step.textKey.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${controller.index.value + 1}/${controller.count}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: controller.isFirst
                ? MainAxisAlignment.end
                : MainAxisAlignment.spaceBetween,
            children: [
              if (!controller.isFirst)
                GestureDetector(
                  onTap: controller.previous,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'tour_back'.tr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: controller.next,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    controller.isLast ? 'tour_done'.tr : 'tour_next'.tr,
                    style: TextStyle(
                      color: accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Positioned(
      left: _margin,
      right: _margin,
      top: below ? target.bottom + _gap : null,
      bottom: below ? null : size.height - target.top + _gap,
      child: Align(
        alignment: below ? Alignment.topCenter : Alignment.bottomCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, below ? 0.06 : -0.06),
                end: Offset.zero,
              ).animate(anim),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(anim),
                child: child,
              ),
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(controller.index.value),
            child: bubble,
          ),
        ),
      ),
    );
  }
}

class _HolePainter extends CustomPainter {
  _HolePainter({
    required this.rect,
    required this.radius,
    required this.intro,
    required this.pulse,
    required this.color,
  });

  final Rect rect;
  final double radius;

  /// 0 -> 1 when the tour first appears.
  final double intro;

  /// 0 -> 1, repeating: the ring around the target expands and fades.
  final double pulse;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Softly closes in on the target; every corner shares one radius, capped
    // so a short target (a button) becomes a full pill.
    final hole = rect.inflate((1 - intro) * 24);
    final r = math.min(radius, math.min(hole.width, hole.height) / 2);
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(r)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.68 * intro),
    );
    if (intro < 1) return;
    // One faint ripple that follows the same rounded shape.
    final grow = Curves.easeOut.transform(pulse) * 8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(hole.inflate(grow), Radius.circular(r + grow)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: (1 - pulse) * 0.5),
    );
  }

  @override
  bool shouldRepaint(_HolePainter old) =>
      old.rect != rect ||
      old.radius != radius ||
      old.intro != intro ||
      old.pulse != pulse ||
      old.color != color;
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.pointUp, required this.color});

  final bool pointUp;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointUp) {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.pointUp != pointUp || old.color != color;
}
