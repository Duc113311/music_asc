import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../models/data_models/music_source.dart';
import '../../services/application/library_scan_service.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../common_components/app_controls.dart';
import '../common_components/cards.dart';
import '../common_components/primary_button.dart';
import '../common_components/source_widgets.dart';
import '../common_components/state_views.dart';

/// sc_quet_thu_vien: choose sources, select all (granted sources only),
/// rescan via the shared service; leaving keeps the scan running (P14-02/03).
class ScanLibraryScreen extends StatelessWidget {
  const ScanLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lib = LibraryController.to;
    final scan = lib.scanService;
    return Scaffold(
      appBar: DetailAppBar(title: 'settings_scan'.tr),
      body: SafeArea(
        child: Obx(() {
          final s = lib.scan.value;
          final running = s.isRunning;
          final List<MusicSource> sources = lib.sources;
          final enabled = sources
              .where((x) => x.enabled && x.accessible)
              .map((x) => x.id!)
              .toSet();
          final accessible = sources.where((x) => x.accessible).toList();
          final allOn =
              accessible.isNotEmpty && accessible.every((x) => x.enabled);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenH),
                  children: [
                    Row(
                      children: [
                        _Count(
                          icon: Icons.music_note_rounded,
                          value: lib.availableCount,
                          label: 'count_songs'.tr,
                        ),
                        _Count(
                          icon: Icons.album_rounded,
                          value: lib.albums.length,
                          label: 'count_albums'.tr,
                        ),
                        _Count(
                          icon: Icons.person_rounded,
                          value: lib.artists.length,
                          label: 'count_artists'.tr,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (lib.permission.value !=
                        AudioPermissionStatus.granted) ...[
                      InfoBanner(
                        message: 'no_audio_permission'.tr,
                        actionLabel: 'action_grant'.tr,
                        onAction: () => Get.toNamed(RouteName.permissions),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'scan_sources'.tr,
                            style: AppTypography.headingS.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        if (accessible.length > 1)
                          TextButton(
                            onPressed: running
                                ? null
                                : () => scan.setSourcesEnabled(
                                    allOn
                                        ? <int>{}
                                        : accessible.map((x) => x.id!).toSet(),
                                  ),
                            child: Text(
                              allOn
                                  ? 'action_deselect_all'.tr
                                  : 'action_select_all'.tr,
                              style: AppTypography.label.copyWith(
                                color: c.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    for (final src in sources)
                      SourceTile(
                        source: src,
                        selected: src.enabled,
                        onTap: running
                            ? () {}
                            : () => scan.setSourceEnabled(src, !src.enabled),
                        trailing: AppCheckbox(
                          value: src.enabled && src.accessible,
                          enabled: src.accessible,
                        ),
                      ),
                    PickFolderTile(
                      onTap: running ? () {} : scan.addFolderSource,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ScanProgressCard(state: s, onCancel: scan.cancel),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: c.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'scan_note'.tr,
                            style: AppTypography.caption.copyWith(
                              color: c.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  0,
                  AppSpacing.screenH,
                  AppSpacing.md,
                ),
                child: PrimaryButton(
                  label: running ? 'scan_running'.tr : 'action_rescan'.tr,
                  icon: Icons.refresh_rounded,
                  loading: running,
                  onPressed: enabled.isEmpty
                      ? null
                      : () async => lib.startScan(),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.icon, required this.value, required this.label});
  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Semantics(
        label: '$value $label',
        excludeSemantics: true,
        child: Column(
          children: [
            Icon(icon, color: c.primary),
            Text(
              '$value',
              style: AppTypography.headingM.copyWith(color: c.textPrimary),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
