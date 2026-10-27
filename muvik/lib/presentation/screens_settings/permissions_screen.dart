import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../models/data_models/music_source.dart';
import '../../services/application/library_scan_service.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../common_components/cards.dart';
import '../common_components/primary_button.dart';

/// "Quyền truy cập": real permission state + granted sources, request again
/// or open system settings; re-checked on return (P14-14).
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  final LibraryScanService _scan = Get.find();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scan.refreshOnResume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scan.refreshOnResume();
  }

  Future<void> _request() async {
    if (_scan.permission.value == AudioPermissionStatus.permanentlyDenied) {
      await _scan.openSystemSettings();
      return;
    }
    final s = await _scan.requestPermission();
    if (s == AudioPermissionStatus.granted) await _scan.refreshSources();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lib = LibraryController.to;
    return Scaffold(
      appBar: DetailAppBar(title: 'settings_permissions'.tr),
      body: SafeArea(
        child: Obx(() {
          final p = lib.permission.value;
          final granted = p == AudioPermissionStatus.granted;
          final List<MusicSource> sources = lib.sources;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          granted
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          color: granted ? c.success : c.warning,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'perm_audio'.tr,
                            style: AppTypography.headingS.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      switch (p) {
                        AudioPermissionStatus.granted => 'perm_granted'.tr,
                        AudioPermissionStatus.denied => 'perm_denied'.tr,
                        AudioPermissionStatus.permanentlyDenied =>
                          'perm_permanently_denied'.tr,
                      },
                      style: AppTypography.bodyM.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    if (!granted) ...[
                      const SizedBox(height: AppSpacing.md),
                      PrimaryButton(
                        label: p == AudioPermissionStatus.permanentlyDenied
                            ? 'action_open_settings'.tr
                            : 'action_grant'.tr,
                        onPressed: _request,
                      ),
                    ] else ...[
                      const SizedBox(height: AppSpacing.sm),
                      PrimaryButton(
                        label: 'action_open_settings'.tr,
                        variant: ButtonVariant.secondary,
                        onPressed: () async => _scan.openSystemSettings(),
                      ),
                    ],
                  ],
                ),
              ),
              SectionHeader(
                title: 'perm_sources'.tr,
                padding: const EdgeInsets.fromLTRB(
                  0,
                  AppSpacing.groupGap,
                  0,
                  AppSpacing.xs,
                ),
              ),
              if (sources.isEmpty)
                Text(
                  'perm_no_sources'.tr,
                  style: AppTypography.bodyM.copyWith(color: c.textSecondary),
                ),
              for (final s in sources)
                ListTile(
                  minTileHeight: 64,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    s.type == SourceType.tree
                        ? Icons.folder_rounded
                        : (s.removable
                            ? Icons.sd_card_rounded
                            : Icons.smartphone_rounded),
                    color: s.accessible ? c.primary : c.textDisabled,
                  ),
                  title: Text(
                    s.type == SourceType.volume
                        ? (s.removable
                            ? 'source_sd_card'.tr
                            : 'source_device'.tr)
                        : s.displayName,
                    style: AppTypography.bodyL.copyWith(color: c.textPrimary),
                  ),
                  subtitle: Text(
                    s.accessible
                        ? 'perm_source_ok'.tr
                        : 'source_unavailable'.tr,
                    style: AppTypography.bodyM.copyWith(
                      color: s.accessible ? c.textSecondary : c.warning,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'perm_choose_sources'.tr,
                variant: ButtonVariant.secondary,
                onPressed: () async => Get.toNamed(RouteName.scanLibrary),
              ),
            ],
          );
        }),
      ),
    );
  }
}
