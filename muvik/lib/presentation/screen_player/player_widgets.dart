import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

const String _assetDisc = 'assets/images/webp/ic_dia.png';
const String _assetNote = 'assets/images/webp/ic_not.png';
const String _assetTonearm = 'assets/images/webp/ic_tonearm.png';

/// Vinyl record with the cover art in its label, a tonearm and floating notes.
/// While [playing] the record spins, the tonearm rests on it and the notes
/// drift upwards; when paused everything stops and the arm lifts away.
class VinylPlayer extends StatefulWidget {
  const VinylPlayer({
    super.key,
    required this.playing,
    required this.size,
  });

  final bool playing;

  /// Diameter of the record.
  final double size;

  @override
  State<VinylPlayer> createState() => _VinylPlayerState();
}

class _VinylPlayerState extends State<VinylPlayer>
    with TickerProviderStateMixin {
  // One turn every 10 s, like a slow record.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );
  late final AnimationController _notes = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );
  late final AnimationController _arm = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: widget.playing ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(VinylPlayer old) {
    super.didUpdateWidget(old);
    if (old.playing != widget.playing) _apply();
  }

  void _apply() {
    if (widget.playing) {
      _spin.repeat();
      _notes.repeat();
      _arm.forward();
    } else {
      _spin.stop();
      _arm.reverse();
      // Let the notes finish their rise instead of freezing mid-air.
      _notes.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _notes.dispose();
    _arm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.size;
    final armH = d * 0.74;
    final armW = armH * 970 / 1622;
    // Pivot (the round base of the arm) in the arm image: (0.80, 0.145).
    final pivot = Offset(d * 0.96, d * 0.10);
    final noteD = d * 0.15;
    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Floating notes, behind the record's edge and tonearm.
          Positioned.fill(
            child: _FloatingNotes(controller: _notes, area: d),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: RotationTransition(
                turns: _spin,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(_assetDisc, width: d, height: d),
                  ],
                ),
              ),
            ),
          ),
          // Neon note on the record label: smaller, and it stays still while
          // the record spins underneath it.
          Center(child: Image.asset(_assetNote, width: noteD, height: noteD)),
          Positioned(
            left: pivot.dx - armW * 0.80,
            top: pivot.dy - armH * 0.145,
            width: armW,
            height: armH,
            child: AnimatedBuilder(
              animation: _arm,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_arm.value);
                return Transform.rotate(
                  // Paused: swung out to the right, off the record.
                  angle: -0.5 * (1 - t),
                  alignment: const Alignment(0.60, -0.71),
                  child: child,
                );
              },
              child: Image.asset(_assetTonearm, fit: BoxFit.fill),
            ),
          ),
        ],
      ),
    );
  }
}

/// A handful of neon notes rising around the record, fading in and out.
class _FloatingNotes extends StatelessWidget {
  const _FloatingNotes({required this.controller, required this.area});

  final Animation<double> controller;
  final double area;

  // (x as a fraction of the width, phase, size as a fraction of the area, sway)
  static const _notes = <(double, double, double, double)>[
    (0.02, 0.00, 0.11, 1.0),
    (0.90, 0.18, 0.09, -1.0),
    (0.12, 0.38, 0.08, -1.0),
    (0.80, 0.55, 0.12, 1.0),
    (0.00, 0.72, 0.07, 1.0),
    (0.94, 0.88, 0.07, -1.0),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < _notes.length; i++) _note(i),
            ],
          );
        },
      ),
    );
  }

  Widget _note(int i) {
    final (x, phase, sizeF, sway) = _notes[i];
    final t = (controller.value + phase) % 1.0;
    final size = area * sizeF;
    final dx = math.sin(t * math.pi * 2 + i) * area * 0.035 * sway;
    final dy = area * 0.85 - t * area * 0.95;
    final opacity = math.sin(t * math.pi).clamp(0.0, 1.0);
    return Positioned(
      left: area * x + dx - size / 2,
      top: dy,
      child: Opacity(
        opacity: opacity * 0.9,
        child: Transform.rotate(
          angle: math.sin(t * math.pi * 2 + i) * 0.35,
          child: Image.asset(_assetNote, width: size, height: size),
        ),
      ),
    );
  }
}

/// Play / pause button: a violet orb inside a soft, slowly morphing blob.
class GlowPlayButton extends StatefulWidget {
  const GlowPlayButton({
    super.key,
    required this.playing,
    required this.loading,
    required this.onPressed,
    this.size = 92,
  });

  final bool playing;
  final bool loading;
  final VoidCallback onPressed;
  final double size;

  @override
  State<GlowPlayButton> createState() => _GlowPlayButtonState();
}

class _GlowPlayButtonState extends State<GlowPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  bool _down = false;

  @override
  void initState() {
    super.initState();
    if (widget.playing) _c.repeat();
  }

  @override
  void didUpdateWidget(GlowPlayButton old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.playing && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final orb = s * 0.66;
    return Semantics(
      button: true,
      label: widget.playing ? 'action_pause'.tr : 'action_play'.tr,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          child: SizedBox.square(
            dimension: s,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) => CustomPaint(
                      size: Size.square(s),
                      painter: _BlobPainter(_c.value),
                    ),
                  ),
                ),
                Container(
                  width: orb,
                  height: orb,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.3, -0.4),
                      colors: [Color(0xFFA48BFF), Color(0xFF6A49E8)],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B6CF7).withValues(alpha: 0.6),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: Center(
                    child: widget.loading
                        ? SizedBox.square(
                            dimension: orb * 0.36,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              widget.playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              key: ValueKey(widget.playing),
                              size: orb * 0.58,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.t);
  final double t;

  static const _layers = <(int, double, double, Color, Color)>[
    // lobes, rotation speed, wobble, from, to
    (5, 1, 0.07, Color(0xFF7C5CF4), Color(0xFF46D9E5)),
    (6, -1, 0.06, Color(0xFFB36CFF), Color(0xFF5B8CFF)),
    (4, 2, 0.05, Color(0xFF6A49E8), Color(0xFFE56CFF)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final base = size.width / 2 * 0.92;
    for (var i = 0; i < _layers.length; i++) {
      final (lobes, speed, wobble, from, to) = _layers[i];
      final angle = t * math.pi * 2 * speed;
      final path = Path();
      const steps = 120;
      for (var k = 0; k <= steps; k++) {
        final a = k / steps * math.pi * 2;
        final r = base *
            (1 -
                wobble +
                wobble * math.sin(lobes * a + angle + i) +
                wobble * 0.5 * math.sin((lobes + 2) * a - angle * 1.5));
        final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
        k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      final rect = Rect.fromCircle(center: c, radius: base);
      canvas.drawPath(
        path,
        Paint()
          ..shader = SweepGradient(
            colors: [
              from.withValues(alpha: 0.6),
              to.withValues(alpha: 0.6),
              from.withValues(alpha: 0.6),
            ],
            transform: GradientRotation(angle),
          ).createShader(rect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
