import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/ringtone_editor_controller.dart';
import '../../models/ui_models/ringtone_range.dart';
import '../../services/native/ringtone_channel.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/app_controls.dart';
import '../common_components/app_touchable.dart';
import '../common_components/cards.dart';
import '../common_components/primary_button.dart';
import '../common_components/song_artwork.dart';
import 'waveform_selector.dart';

/// "Cắt nhạc chuông", step 2: pick the part on the waveform, listen to exactly
/// that part, choose what it is for and save it or set it as the phone sound.
class RingtoneEditorScreen extends GetView<RingtoneEditorController> {
  const RingtoneEditorScreen({super.key});

  String _setLabel(RingtoneType t) => switch (t) {
    RingtoneType.ringtone => 'ringtone_set_ringtone'.tr,
    RingtoneType.notification => 'ringtone_set_notification'.tr,
    RingtoneType.alarm => 'ringtone_set_alarm'.tr,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final song = controller.song;
    return Scaffold(
      appBar: DetailAppBar(title: 'ringtone_title'.tr),
      body: GradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH,
                        AppSpacing.xs,
                        AppSpacing.screenH,
                        AppSpacing.md,
                      ),
                      children: [
                        Row(
                          children: [
                            SongArtwork(song: song, size: 56),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.displayTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.songTitle.copyWith(
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    song.artistOrNull ?? 'unknown_artist'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyM.copyWith(
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ringtone_hint_handles'.tr,
                                style: AppTypography.caption.copyWith(
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Obx(
                                () => Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    WaveformSelector(
                                      peaks: controller.peaks.toList(),
                                      range: controller.range.value,
                                      playheadMs: controller.playheadMs.value,
                                      onChanged: controller.setRange,
                                    ),
                                    if (controller.loadingWave.value)
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'ringtone_loading'.tr,
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: c.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              Obx(() {
                                if (!controller.waveFailed.value) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.xs,
                                  ),
                                  child: Text(
                                    'ringtone_wave_failed'.tr,
                                    style: AppTypography.caption.copyWith(
                                      color: c.warning,
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: AppSpacing.sm),
                              Obx(() {
                                final r = controller.range.value;
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _Readout(
                                      label: 'ringtone_start'.tr,
                                      value: RingtoneRange.format(r.startMs),
                                    ),
                                    _Readout(
                                      label: 'ringtone_length'.tr,
                                      value: RingtoneRange.format(r.lengthMs),
                                      highlight: true,
                                    ),
                                    _Readout(
                                      label: 'ringtone_end'.tr,
                                      value: RingtoneRange.format(r.endMs),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Obx(() {
                          final r = controller.range.value;
                          return Column(
                            children: [
                              _Stepper(
                                label: 'ringtone_start'.tr,
                                value: RingtoneRange.format(r.startMs),
                                onMinus: () => controller.setStart(r.startMs - 100),
                                onPlus: () => controller.setStart(r.startMs + 100),
                              ),
                              _Stepper(
                                label: 'ringtone_end'.tr,
                                value: RingtoneRange.format(r.endMs),
                                onMinus: () => controller.setEnd(r.endMs - 100),
                                onPlus: () => controller.setEnd(r.endMs + 100),
                              ),
                            ],
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 6),
                          child: Text(
                            'ringtone_limit'.tr,
                            style: AppTypography.caption.copyWith(
                              color: c.textMuted,
                            ),
                          ),
                        ),
                        Obx(
                          () => PrimaryButton(
                            label: controller.previewing.value
                                ? 'ringtone_stop'.tr
                                : 'ringtone_preview'.tr,
                            icon: controller.previewing.value
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            variant: ButtonVariant.secondary,
                            onPressed: controller.togglePreview,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'ringtone_type'.tr,
                          style: AppTypography.headingS.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Obx(
                          () => Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              for (final t in RingtoneType.values)
                                AppChip(
                                  label: 'ringtone_type_${t.key}'.tr,
                                  selected: controller.type.value == t,
                                  onTap: () => controller.setType(t),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      AppSpacing.xs,
                      AppSpacing.screenH,
                      AppSpacing.md,
                    ),
                    child: Obx(
                      () => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PrimaryButton(
                            label: _setLabel(controller.type.value),
                            icon: Icons.notifications_active_rounded,
                            onPressed: () => controller.save(makeDefault: true),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          PrimaryButton(
                            label: 'ringtone_save'.tr,
                            icon: Icons.save_alt_rounded,
                            variant: ButtonVariant.secondary,
                            onPressed: () => controller.save(makeDefault: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // While cutting: block the screen so nothing changes under it.
              Obx(() {
                if (!controller.busy.value) return const SizedBox.shrink();
                return Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'ringtone_saving'.tr,
                            style: AppTypography.bodyL.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: c.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.headingS.copyWith(
            color: highlight ? c.secondary : c.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Start / end with − and + for 0.1 s steps (a finger cannot be that exact).
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });
  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyL.copyWith(color: c.textPrimary),
          ),
        ),
        AppIconButton(
          icon: Icons.remove_rounded,
          tooltip: '- 0.1 s',
          filled: true,
          onPressed: onMinus,
        ),
        SizedBox(
          width: 72,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: AppTypography.headingS.copyWith(color: c.textPrimary),
          ),
        ),
        AppIconButton(
          icon: Icons.add_rounded,
          tooltip: '+ 0.1 s',
          filled: true,
          onPressed: onPlus,
        ),
      ],
    );
  }
}
