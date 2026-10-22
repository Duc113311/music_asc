import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/playback_controller.dart';
import '../../models/ui_models/audio_preset.dart';
import '../../services/application/equalizer_service.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import 'app_controls.dart';

String _hz(double hz) => hz >= 1000
    ? '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}K'
    : hz.round().toString();

/// Shared EQ UI (sheet + sc_bo_chinh_am use the same service, P12-09/P14-07).
/// Only bands/effects the device engine supports are shown; the rest are
/// disabled with an explanation (P14-08).
class EqualizerPanel extends StatelessWidget {
  const EqualizerPanel({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final service = Get.find<EqualizerService>();
    final pc = PlaybackController.to;
    return Obx(() {
      final EqualizerState s = pc.eq.value;
      final caps = s.capabilities;
      final waiting = caps.bandCentersHz.isEmpty &&
          !caps.bassSupported &&
          !caps.virtualizerSupported &&
          !caps.loudnessSupported;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Card(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'eq_loud_mode'.tr,
                        style: AppTypography.headingS.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        caps.dynamicsSupported
                            ? 'eq_loud_mode_desc'.tr
                            : 'eq_effect_unsupported'.tr,
                        style: AppTypography.bodyM.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSwitch(
                  value: s.loudMode,
                  semanticLabel: 'eq_loud_mode'.tr,
                  onChanged:
                      caps.dynamicsSupported ? service.setLoudMode : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Card(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'eq_enable'.tr,
                        style: AppTypography.headingS.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        'eq_enable_desc'.tr,
                        style: AppTypography.bodyM.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSwitch(
                  value: s.enabled,
                  semanticLabel: 'eq_enable'.tr,
                  onChanged: s.supported ? service.setEnabled : null,
                ),
              ],
            ),
          ),
          if (!s.supported)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                waiting && !pc.state.value.sourceLoaded
                    ? 'eq_needs_playback'.tr
                    : 'eq_unsupported'.tr,
                style: AppTypography.bodyM.copyWith(color: c.warning),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'eq_mode'.tr,
                  style: AppTypography.headingS.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    for (final p in AudioPreset.selectable)
                      AppChip(
                        label: p.labelKey.tr,
                        selected: s.preset == p,
                        onTap: caps.eqSupported
                            ? () => service.selectPreset(p)
                            : null,
                      ),
                    if (s.preset == AudioPreset.custom)
                      AppChip(
                        label: AudioPreset.custom.labelKey.tr,
                        selected: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (!compact && caps.eqSupported) ...[
            const SizedBox(height: AppSpacing.sm),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'eq_graphic'.tr,
                          style: AppTypography.headingS.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        'dB',
                        style: AppTypography.caption.copyWith(
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 260,
                    child: Row(
                      children: [
                        for (var i = 0; i < caps.bandCentersHz.length; i++)
                          Expanded(
                            child: _BandSlider(
                              label: _hz(caps.bandCentersHz[i]),
                              value: i < s.bandGainsDb.length
                                  ? s.bandGainsDb[i]
                                  : 0,
                              min: caps.minLevelDb,
                              max: caps.maxLevelDb,
                              enabled: s.enabled,
                              onChanged: (v) => service.setBandGain(i, v),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _LoudnessSlider(
            value: s.loudnessGainDb,
            supported: caps.loudnessSupported,
            onChanged: service.setLoudnessGain,
          ),
          if (!compact) ...[
            const SizedBox(height: AppSpacing.sm),
            _EffectSlider(
              title: 'eq_bass'.tr,
              desc: caps.bassSupported
                  ? 'eq_bass_desc'.tr
                  : 'eq_effect_unsupported'.tr,
              value: s.bassStrength,
              enabled: caps.bassSupported && s.enabled,
              onChanged: service.setBassStrength,
            ),
            const SizedBox(height: AppSpacing.sm),
            _EffectSlider(
              title: 'eq_virtualizer'.tr,
              desc: caps.virtualizerSupported
                  ? 'eq_virtualizer_desc'.tr
                  : 'eq_effect_unsupported'.tr,
              value: s.virtualizerStrength,
              enabled: caps.virtualizerSupported && s.enabled,
              onChanged: service.setVirtualizerStrength,
            ),
          ],
        ],
      );
    });
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Material (not a decorated Container) so chip/switch ripples show.
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

class _BandSlider extends StatefulWidget {
  const _BandSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  State<_BandSlider> createState() => _BandSliderState();
}

class _BandSliderState extends State<_BandSlider> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final v = (_drag ?? widget.value).clamp(widget.min, widget.max);
    return Column(
      children: [
        Expanded(
          child: Semantics(
            label: '${widget.label} Hz',
            value: '${v.round()} dB',
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                  disabledActiveTrackColor: c.border,
                  disabledThumbColor: c.textDisabled,
                ),
                child: Slider(
                  value: v,
                  min: widget.min,
                  max: widget.max,
                  onChanged:
                      widget.enabled ? (x) => setState(() => _drag = x) : null,
                  onChangeEnd: widget.enabled
                      ? (x) {
                          widget.onChanged(x.roundToDouble());
                          setState(() => _drag = null);
                        }
                      : null,
                ),
              ),
            ),
          ),
        ),
        Text(
          widget.label,
          style: AppTypography.caption.copyWith(color: c.textSecondary),
        ),
        Text(
          '${v >= 0 ? '+' : ''}${v.round()}',
          style: AppTypography.label.copyWith(color: c.primary),
        ),
      ],
    );
  }
}

class _EffectSlider extends StatelessWidget {
  const _EffectSlider({
    required this.title,
    required this.desc,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String desc;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Card(
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.headingS.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${(value / 10).round()}%',
                  style: AppTypography.label.copyWith(color: c.textPrimary),
                ),
              ],
            ),
            Text(
              desc,
              style: AppTypography.bodyM.copyWith(color: c.textSecondary),
            ),
            Slider(
              value: value.toDouble(),
              max: 1000,
              onChanged: enabled ? (v) => onChanged(v.round()) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Tăng âm lượng": LoudnessEnhancer gain 0..+10 dB, independent of the EQ
/// switch. High values can distort and hurt hearing, so a warning shows above
/// [EqualizerState.loudnessWarnDb].
class _LoudnessSlider extends StatefulWidget {
  const _LoudnessSlider({
    required this.value,
    required this.supported,
    required this.onChanged,
  });

  final double value;
  final bool supported;
  final ValueChanged<double> onChanged;

  @override
  State<_LoudnessSlider> createState() => _LoudnessSliderState();
}

class _LoudnessSliderState extends State<_LoudnessSlider> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const max = EqualizerState.maxLoudnessDb;
    final v = (_drag ?? widget.value).clamp(0, max).toDouble();
    final loud = v > EqualizerState.loudnessWarnDb;
    final tint = loud ? c.warning : c.primary;
    return _Card(
      child: Opacity(
        opacity: widget.supported ? 1 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'eq_loudness'.tr,
                    style: AppTypography.headingS.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ),
                Text(
                  v == 0 ? 'value_off'.tr : '+${v.toStringAsFixed(1)} dB',
                  style: AppTypography.label.copyWith(
                    color: v == 0 ? c.textSecondary : tint,
                  ),
                ),
              ],
            ),
            Text(
              widget.supported
                  ? 'eq_loudness_desc'.tr
                  : 'eq_effect_unsupported'.tr,
              style: AppTypography.bodyM.copyWith(color: c.textSecondary),
            ),
            Semantics(
              label: 'eq_loudness'.tr,
              value: '+${v.toStringAsFixed(1)} dB',
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: tint,
                  thumbColor: tint,
                  overlayColor: tint.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: v,
                  max: max,
                  divisions: (max * 2).round(),
                  onChanged: widget.supported
                      ? (x) => setState(() => _drag = x)
                      : null,
                  onChangeEnd: widget.supported
                      ? (x) {
                          widget.onChanged(x);
                          setState(() => _drag = null);
                        }
                      : null,
                ),
              ),
            ),
            AnimatedSize(
              duration: AppMotion.state,
              alignment: Alignment.topCenter,
              child: loud
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: AppSizes.iconSm,
                          color: c.warning,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'eq_loudness_warning'.tr,
                            style: AppTypography.caption.copyWith(
                              color: c.warning,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
