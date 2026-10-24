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
import '../../values/route_name.dart';
import '../common_components/app_controls.dart';
import '../common_components/primary_bottom_sheet.dart';
import '../common_components/primary_button.dart';

/// Sc_bthsheet_hen_gio_tat: preset, start/cancel; "Tùy chỉnh" opens
/// sc_hen_gio_tat (P12-10).
Future<void> showSleepTimerSheet() =>
    showAppSheet<void>(builder: (_) => const _SleepSheet());

class _SleepSheet extends StatefulWidget {
  const _SleepSheet();
  @override
  State<_SleepSheet> createState() => _SleepSheetState();
}

class _SleepSheetState extends State<_SleepSheet> {
  int _minutes = PrefStore.getInt(
    PrefConst.sleepLastMinutes,
    PrefDefaults.sleepLastMinutes,
  );
  bool _wait = PrefStore.getBool(
    PrefConst.sleepWaitTrackEnd,
    PrefDefaults.sleepWaitTrackEnd,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pc = PlaybackController.to;
    return Obx(() {
      final st = pc.sleep.value;
      final active = st.active;
      final stopAt = active && st.deadline != null
          ? st.deadline!
          : DateTime.now().add(Duration(minutes: _minutes));
      return SheetScaffold(
        title: 'sleep_title'.tr,
        subtitle: 'sleep_desc'.tr,
        footer: Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'sleep_custom'.tr,
                variant: ButtonVariant.secondary,
                // Same height and pill shape as "Bắt đầu" next to it.
                height: AppSizes.buttonSecondary,
                onPressed: () async {
                  Get.back<void>();
                  await Get.toNamed(RouteName.sleepTimer);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: active
                  ? PrimaryButton(
                      label: 'sleep_cancel'.tr,
                      variant: ButtonVariant.destructive,
                      height: AppSizes.buttonSecondary,
                      onPressed: () async {
                        await pc.sleepTimer.cancel();
                        Get.back<void>();
                        ToastUtils.success('toast_timer_cancelled'.tr);
                      },
                    )
                  : PrimaryButton(
                      label: 'action_start'.tr,
                      height: AppSizes.buttonSecondary,
                      onPressed: () async {
                        await pc.sleepTimer.start(
                          Duration(minutes: _minutes),
                          waitTrackEnd: _wait,
                        );
                        Get.back<void>();
                        ToastUtils.success(
                          'toast_timer_started'.trParams({
                            'args1': DateFormat.Hm().format(
                              DateTime.now().add(Duration(minutes: _minutes)),
                            ),
                          }),
                        );
                      },
                    ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!active)
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final m in AppConfig.sleepPresets)
                    AppChip(
                      label: 'fmt_minutes'.trParams({'args1': '$m'}),
                      selected: _minutes == m,
                      onTap: () => setState(() => _minutes = m),
                    ),
                ],
              ),
            if (!active)
              InkWell(
                onTap: () => setState(() => _wait = !_wait),
                // Rounded like the info card below, with room on the sides so
                // the tap highlight does not touch the checkbox or the text.
                borderRadius: BorderRadius.circular(AppRadius.input),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      AppCheckbox(value: _wait),
                      const SizedBox(width: AppSpacing.sm),
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
                              style: AppTypography.caption.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, color: c.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      st.waitingForTrackEnd
                          ? 'sleep_waiting_track'.tr
                          : 'sleep_stops_at'.trParams({
                                  'args1': DateFormat.Hm().format(stopAt),
                                }) +
                                (active
                                    ? ' • ${'sleep_remaining'.trParams({'args1': DurationFormatter.clock(st.remaining(DateTime.now()))})}'
                                    : ''),
                      style: AppTypography.bodyM.copyWith(color: c.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
