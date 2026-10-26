import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/setup_controller.dart';
import '../../models/data_models/music_source.dart';
import '../../services/application/library_scan_service.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/primary_button.dart';
import '../common_components/source_widgets.dart';
import '../common_components/state_views.dart';
import 'setup_screen.dart';

/// sc_step_02: choose sources (each or all) and scan. CTA disabled until a
/// source is selected (P06-11, P06-12).
class StepSources extends GetView<SetupController> {
  const StepSources({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Obx(() {
      final scan = controller.scanState.value;
      final running = scan.isRunning;
      final sources = controller.sources;
      final noPermission =
          controller.permission.value != AudioPermissionStatus.granted;
      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.lg,
                AppSpacing.screenH,
                AppSpacing.md,
              ),
              children: [
                const SetupHero(asset: AppAssets.step2, aspect: 539 / 900),
                const SizedBox(height: AppSpacing.md),
                SetupTitle(
                  title: 'step2_title'.tr,
                  highlight: 'step2_highlight'.tr,
                  description: 'step2_desc'.tr,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (noPermission) ...[
                  InfoBanner(
                    message: 'no_audio_permission'.tr,
                    actionLabel: 'action_grant'.tr,
                    onAction: () => controller.goTo(0),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (controller.selectableSources.length > 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: running ? null : controller.toggleAll,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(
                        controller.allSelected
                            ? 'action_deselect_all'.tr
                            : 'action_select_all'.tr,
                        style: AppTypography.label.copyWith(color: c.primary),
                      ),
                    ),
                  ),
                for (final MusicSource s in sources)
                  SourceTile(
                    source: s,
                    selected: controller.selected.contains(s.id),
                    onTap: running ? () {} : () => controller.toggle(s),
                  ),
                PickFolderTile(onTap: running ? () {} : controller.pickFolder),
                const SizedBox(height: AppSpacing.sm),
                ScanProgressCard(state: scan, onCancel: controller.cancelScan),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.xs,
              AppSpacing.screenH,
              AppSpacing.lg,
            ),
            child: PrimaryButton(
              label: running ? 'scan_running'.tr : 'step2_scan'.tr,
              icon: Icons.search_rounded,
              loading: running,
              onPressed: controller.selected.isEmpty
                  ? null
                  : controller.startScan,
            ),
          ),
        ],
      );
    });
  }
}
