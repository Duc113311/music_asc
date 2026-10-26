import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/ui_models/ringtone_range.dart';
import '../../values/app_colors.dart';

/// Waveform of a song with the chosen part highlighted. Drag the left or right
/// handle to move the start or the end, or drag inside the highlighted part
/// to slide the whole clip. [playheadMs] draws a line while previewing.
class WaveformSelector extends StatefulWidget {
  const WaveformSelector({
    super.key,
    required this.peaks,
    required this.range,
    required this.onChanged,
    this.playheadMs,
    this.height = 132,
  });

  /// 0..1 bar heights; empty while loading (flat bars are drawn).
  final List<double> peaks;
  final RingtoneRange range;
  final ValueChanged<RingtoneRange> onChanged;
  final int? playheadMs;
  final double height;

  @override
  State<WaveformSelector> createState() => _WaveformSelectorState();
}

enum _Drag { none, start, end, body }

class _WaveformSelectorState extends State<WaveformSelector> {
  _Drag _drag = _Drag.none;
  double _carryMs = 0;

  /// How close (px) a touch must be to a handle to grab it.
  static const double _grab = 30;

  double get _dur => widget.range.durationMs.toDouble().clamp(1, double.infinity);

  void _start(DragStartDetails d, double width) {
    final r = widget.range;
    final sx = r.startMs / _dur * width;
    final ex = r.endMs / _dur * width;
    final x = d.localPosition.dx;
    final ds = (x - sx).abs();
    final de = (x - ex).abs();
    if (ds <= _grab && ds <= de) {
      _drag = _Drag.start;
    } else if (de <= _grab) {
      _drag = _Drag.end;
    } else if (x > sx && x < ex) {
      _drag = _Drag.body;
    } else {
      _drag = _Drag.none;
    }
    _carryMs = 0;
  }

  void _update(DragUpdateDetails d, double width) {
    final x = d.localPosition.dx.clamp(0, width);
    switch (_drag) {
      case _Drag.start:
        widget.onChanged(widget.range.withStart((x / width * _dur).round()));
      case _Drag.end:
        widget.onChanged(widget.range.withEnd((x / width * _dur).round()));
      case _Drag.body:
        _carryMs += d.delta.dx / width * _dur;
        final whole = _carryMs.truncate();
        if (whole != 0) {
          _carryMs -= whole;
          widget.onChanged(widget.range.shifted(whole));
        }
      case _Drag.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return Semantics(
          label: 'ringtone_hint_handles'.tr,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _start(d, w),
            onHorizontalDragUpdate: (d) => _update(d, w),
            onHorizontalDragEnd: (_) => _drag = _Drag.none,
            child: SizedBox(
              height: widget.height,
              width: w,
              child: CustomPaint(
                painter: _WavePainter(
                  peaks: widget.peaks,
                  startFrac: widget.range.startMs / _dur,
                  endFrac: widget.range.endMs / _dur,
                  playFrac: widget.playheadMs == null
                      ? null
                      : widget.playheadMs! / _dur,
                  active: c.primary,
                  idle: c.textMuted.withValues(alpha: 0.35),
                  handle: c.secondary,
                  playhead: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.peaks,
    required this.startFrac,
    required this.endFrac,
    required this.playFrac,
    required this.active,
    required this.idle,
    required this.handle,
    required this.playhead,
  });

  final List<double> peaks;
  final double startFrac;
  final double endFrac;
  final double? playFrac;
  final Color active;
  final Color idle;
  final Color handle;
  final Color playhead;

  @override
  void paint(Canvas canvas, Size size) {
    final n = peaks.isEmpty ? 80 : peaks.length;
    final slot = size.width / n;
    final barW = (slot * 0.62).clamp(1.5, 6.0);
    final mid = size.height / 2;
    final paint = Paint()..strokeCap = StrokeCap.round..strokeWidth = barW;

    for (var i = 0; i < n; i++) {
      final frac = (i + 0.5) / n;
      final inside = frac >= startFrac && frac <= endFrac;
      final p = peaks.isEmpty ? 0.12 : peaks[i].clamp(0.0, 1.0);
      final h = (p * size.height * 0.88).clamp(4.0, size.height);
      paint.color = inside ? active : idle;
      final x = i * slot + slot / 2;
      canvas.drawLine(Offset(x, mid - h / 2), Offset(x, mid + h / 2), paint);
    }

    final sx = startFrac * size.width;
    final ex = endFrac * size.width;
    final hp = Paint()
      ..color = handle
      ..strokeWidth = 3;
    canvas.drawLine(Offset(sx, 0), Offset(sx, size.height), hp);
    canvas.drawLine(Offset(ex, 0), Offset(ex, size.height), hp);
    // Round grips so the handles are easy to see and to grab.
    final grip = Paint()..color = handle;
    canvas.drawCircle(Offset(sx, 9), 8, grip);
    canvas.drawCircle(Offset(ex, size.height - 9), 8, grip);

    final pf = playFrac;
    if (pf != null && pf >= 0 && pf <= 1) {
      final x = pf * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = playhead
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.peaks != peaks ||
      old.startFrac != startFrac ||
      old.endFrac != endFrac ||
      old.playFrac != playFrac ||
      old.active != active;
}
