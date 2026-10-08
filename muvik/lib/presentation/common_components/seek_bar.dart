import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/duration_formatter.dart';
import '../../values/app_colors.dart';
import '../../values/app_typography.dart';

/// Drag previews the position; releasing applies the seek. Unknown duration
/// locks seeking (P07-06).
class SeekBar extends StatefulWidget {
  const SeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.showLabels = true,
  });

  final Duration position;
  final Duration? duration;
  final ValueChanged<Duration> onSeek;
  final bool showLabels;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = widget.duration?.inMilliseconds ?? 0;
    final enabled = total > 0;
    final pos = widget.position.inMilliseconds
        .clamp(0, total > 0 ? total : 0)
        .toDouble();
    final value = _drag ?? pos;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'seek_bar'.tr,
          value: DurationFormatter.clockMs(value.round()),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              disabledActiveTrackColor: c.border,
              disabledInactiveTrackColor: c.border,
              disabledThumbColor: c.textDisabled,
            ),
            child: Slider(
              value: enabled ? value.clamp(0, total.toDouble()) : 0,
              max: enabled ? total.toDouble() : 1,
              onChanged: enabled ? (v) => setState(() => _drag = v) : null,
              onChangeEnd: enabled
                  ? (v) {
                      widget.onSeek(Duration(milliseconds: v.round()));
                      setState(() => _drag = null);
                    }
                  : null,
            ),
          ),
        ),
        if (widget.showLabels)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  DurationFormatter.clockMs(value.round()),
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
                const Spacer(),
                Text(
                  enabled ? DurationFormatter.clockMs(total) : '--:--',
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
