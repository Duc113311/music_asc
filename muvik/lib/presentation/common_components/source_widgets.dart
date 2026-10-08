import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/data_models/music_source.dart';
import '../../models/ui_models/scan_state.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import 'app_controls.dart';

/// Source row (device storage / SD card / picked folder) with checkbox.
class SourceTile extends StatelessWidget {
  const SourceTile({
    super.key,
    required this.source,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final MusicSource source;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (icon, tint) = switch (source.type) {
      SourceType.volume when source.removable => (
        Icons.sd_card_rounded,
        c.secondary,
      ),
      SourceType.volume => (Icons.smartphone_rounded, c.primary),
      SourceType.tree => (Icons.folder_rounded, c.error),
    };
    final title = source.type == SourceType.volume
        ? (source.removable ? 'source_sd_card'.tr : 'source_device'.tr)
        : source.displayName;
    final subtitle = !source.accessible
        ? 'source_unavailable'.tr
        : (source.type == SourceType.volume
              ? (source.removable
                    ? source.displayName
                    : 'source_device_desc'.tr)
              : 'source_folder_desc'.tr);
    return _SelectableCard(
      selected: selected && source.accessible,
      enabled: source.accessible,
      onTap: onTap,
      icon: icon,
      tint: tint,
      title: title,
      subtitle: subtitle,
      trailing:
          trailing ??
          AppCheckbox(
            value: selected && source.accessible,
            enabled: source.accessible,
          ),
    );
  }
}

/// "Chọn thư mục" row that opens the system folder picker.
class PickFolderTile extends StatelessWidget {
  const PickFolderTile({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _SelectableCard(
      selected: false,
      enabled: true,
      onTap: onTap,
      icon: Icons.create_new_folder_rounded,
      tint: c.warning,
      title: 'source_pick_folder'.tr,
      subtitle: 'source_pick_folder_desc'.tr,
      trailing: Icon(Icons.chevron_right_rounded, color: c.iconDefault),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        selected: selected,
        enabled: enabled,
        button: true,
        child: Material(
          color: selected ? c.surfaceSelected : c.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: selected ? c.primary : c.border),
              ),
              child: Opacity(
                opacity: enabled ? 1 : 0.55,
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                      child: Icon(icon, color: tint, size: 28),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headingS.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: AppTypography.bodyM.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    trailing,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Live scan progress / result. Unknown totals show the processed count, not
/// a fake percentage.
class ScanProgressCard extends StatelessWidget {
  const ScanProgressCard({super.key, required this.state, this.onCancel});
  final ScanState state;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = state;
    final (title, color, icon) = switch (s.status) {
      ScanStatus.scanning => (
        'scan_running'.tr,
        c.primary,
        Icons.manage_search_rounded,
      ),
      ScanStatus.success => (
        s.hasChanges ? 'scan_done'.tr : 'scan_no_changes'.tr,
        c.success,
        Icons.check_circle_rounded,
      ),
      ScanStatus.partial => (
        'scan_partial'.tr,
        c.warning,
        Icons.warning_amber_rounded,
      ),
      ScanStatus.error => ('scan_error'.tr, c.error, Icons.error_rounded),
      ScanStatus.cancelled => (
        'scan_cancelled'.tr,
        c.warning,
        Icons.cancel_rounded,
      ),
      ScanStatus.idle => ('', c.primary, Icons.search_rounded),
    };
    if (s.status == ScanStatus.idle) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.headingS.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ),
                if (s.isRunning && onCancel != null)
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'action_cancel'.tr,
                      style: AppTypography.label.copyWith(color: c.error),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (s.isRunning) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(value: s.fraction, minHeight: 6),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              s.total != null && s.isRunning
                  ? 'scan_processed_of'.trParams({
                      'args1': '${s.processed}',
                      'args2': '${s.total}',
                    })
                  : 'scan_processed'.trParams({'args1': '${s.processed}'}),
              style: AppTypography.bodyM.copyWith(color: c.textSecondary),
            ),
            if (s.currentSource != null && s.isRunning)
              Text(
                s.currentSource!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: c.textMuted),
              ),
            if (!s.isRunning) ...[
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xxs,
                children: [
                  _Stat(label: 'scan_new'.tr, value: s.added),
                  _Stat(label: 'scan_updated'.tr, value: s.updated),
                  _Stat(label: 'scan_skipped'.tr, value: s.skipped),
                  if (s.markedMissing > 0)
                    _Stat(label: 'scan_missing'.tr, value: s.markedMissing),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      '$label: $value',
      style: AppTypography.caption.copyWith(color: c.textSecondary),
    );
  }
}
