import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../configs/app_config.dart';
import '../../configs/pref_const.dart';
import '../../configs/pref_defaults.dart';
import '../../controller/playback_controller.dart';
import '../../services/storage/pref_store.dart';
import '../../utils/duration_formatter.dart';
import '../../utils/toast_utils.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/app_controls.dart';
import '../common_components/cards.dart';
import '../common_components/primary_button.dart';

/// sc_hen_gio_tat: 15/30/45/60 or custom 1 min–12 h, wait-for-track-end,
/// predicted stop time; countdown derived from the stored deadline (P13).
class SleepTimerScreen extends StatefulWidget {
  const SleepTimerScreen({super.key});

  @override
  State<SleepTimerScreen> createState() => _SleepTimerScreenState();
}

class _SleepTimerScreenState extends State<SleepTimerScreen> {
  late int? _preset;
  int _customH = 1;
  int _customM = 0;
  bool _wait = PrefStore.getBool(
    PrefConst.sleepWaitTrackEnd,
    PrefDefaults.sleepWaitTrackEnd,
  );
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    final last = PrefStore.getInt(
      PrefConst.sleepLastMinutes,
      PrefDefaults.sleepLastMinutes,
    );
    if (AppConfig.sleepPresets.contains(last)) {
      _preset = last;
    } else {
      _preset = null;
      _customH = last ~/ 60;
      _customM = last % 60;
    }
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && PlaybackController.to.sleep.value.active) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  int get _minutes => _preset ?? (_customH * 60 + _customM);

  bool get _valid =>
      _minutes >= AppConfig.sleepMinMinutes &&
      _minutes <= AppConfig.sleepMaxMinutes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pc = PlaybackController.to;
    return Scaffold(
      appBar: DetailAppBar(title: 'settings_sleep_timer'.tr),
      body: SafeArea(
        child: Obx(() {
          final st = pc.sleep.value;
          final active = st.active;
          final now = DateTime.now();
          final stopAt = st.deadline ?? now.add(Duration(minutes: _minutes));
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            children: [
              Text(
                'sleep_desc'.tr,
                style: AppTypography.bodyL.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              if (!active) ...[
                Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: c.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final m in AppConfig.sleepPresets)
                        SelectableOptionTile(
                          title: 'fmt_minutes'.trParams({'args1': '$m'}),
                          selected: _preset == m,
                          onTap: () => setState(() => _preset = m),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  selected: _preset == null,
                  onTap: () => setState(() => _preset = null),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppRadio(selected: _preset == null),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'sleep_custom_time'.tr,
                            style: AppTypography.bodyL.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _Dropdown(
                            value: _customH,
                            count: 13,
                            label: 'unit_hours_short'.tr,
                            onChanged: (v) => setState(() {
                              _preset = null;
                              _customH = v;
                              if (_customH == 12) _customM = 0;
                            }),
                          ),
                          _Dropdown(
                            value: _customM,
                            count: _customH == 12 ? 1 : 60,
                            label: 'unit_minutes_short'.tr,
                            onChanged: (v) => setState(() {
                              _preset = null;
                              _customM = v;
                            }),
                          ),
                        ],
                      ),
                      if (_preset == null && !_valid)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            'sleep_invalid'.tr,
                            style: AppTypography.caption.copyWith(
                              color: c.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  onTap: () => setState(() => _wait = !_wait),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'sleep_wait_end'.tr,
                              style: AppTypography.bodyL.copyWith(
                                color: c.textPrimary,
                              ),
                            ),
                            Text(
                              'sleep_wait_end_desc'.tr,
                              style: AppTypography.bodyM.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSwitch(
                        value: _wait,
                        onChanged: (v) => setState(() => _wait = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppCard(
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: c.primary, size: 36),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            st.waitingForTrackEnd
                                ? 'sleep_waiting_track'.tr
                                : 'sleep_stops_label'.tr,
                            style: AppTypography.bodyM.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          if (!st.waitingForTrackEnd)
                            Text(
                              _valid || active
                                  ? DateFormat.Hm().format(stopAt)
                                  : '--:--',
                              style: AppTypography.display.copyWith(
                                color: c.primary,
                              ),
                            ),
                          if (active && st.deadline != null)
                            Text(
                              'sleep_remaining'.trParams({
                                'args1': DurationFormatter.clock(
                                  st.remaining(now),
                                ),
                              }),
                              style: AppTypography.bodyM.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (active)
                PrimaryButton(
                  label: 'sleep_cancel'.tr,
                  variant: ButtonVariant.destructive,
                  onPressed: () async {
                    await pc.sleepTimer.cancel();
                    ToastUtils.success('toast_timer_cancelled'.tr);
                  },
                )
              else
                PrimaryButton(
                  label: 'sleep_start'.tr,
                  onPressed: !_valid
                      ? null
                      : () async {
                          await pc.sleepTimer.start(
                            Duration(minutes: _minutes),
                            waitTrackEnd: _wait,
                          );
                          ToastUtils.success(
                            'toast_timer_started'.trParams({
                              'args1': DateFormat.Hm().format(
                                DateTime.now().add(Duration(minutes: _minutes)),
                              ),
                            }),
                          );
                        },
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.count,
    required this.label,
    required this.onChanged,
  });
  final int value;
  final int count;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: c.surfaceInput,
            borderRadius: BorderRadius.circular(AppRadius.imageSm + 4),
            border: Border.all(color: c.border),
          ),
          child: DropdownButton<int>(
            value: value.clamp(0, count - 1),
            underline: const SizedBox.shrink(),
            dropdownColor: c.surfaceElevated,
            menuMaxHeight: 320,
            style: AppTypography.headingS.copyWith(color: c.textPrimary),
            items: [
              for (var i = 0; i < count; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(i.toString().padLeft(2, '0')),
                ),
            ],
            onChanged: (v) => v == null ? null : onChanged(v),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.bodyL.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}
