import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/settings_controller.dart';
import '../../services/application/audio_handler.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/app_controls.dart';
import '../common_components/cards.dart';

/// sc_phat_qua_tai_nghe: disconnect pauses by default; reconnect resumes only
/// if enabled; headset buttons can be turned off (P14-11, P17-09).
class HeadphonesScreen extends StatelessWidget {
  const HeadphonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = SettingsController.to;
    return Scaffold(
      appBar: DetailAppBar(title: 'settings_headphones'.tr),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            Image.asset(AppAssets.headphones, height: 150, fit: BoxFit.contain),
            const SizedBox(height: AppSpacing.md),
            Text(
              'hp_when_connected'.tr,
              style: AppTypography.headingS.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Obx(
              () => SettingsGroupCard(
                children: [
                  _Toggle(
                    title: 'hp_resume'.tr,
                    desc: 'hp_resume_desc'.tr,
                    value: s.resumeOnConnect.value,
                    onChanged: s.setResumeOnConnect,
                  ),
                  _Toggle(
                    title: 'hp_pause'.tr,
                    desc: 'hp_pause_desc'.tr,
                    value: s.pauseOnDisconnect.value,
                    onChanged: s.setPauseOnDisconnect,
                  ),
                  _Toggle(
                    title: 'hp_buttons'.tr,
                    desc: 'hp_buttons_desc'.tr,
                    value: s.headphoneButtons.value,
                    onChanged: s.setHeadphoneButtons,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'hp_output'.tr,
              style: AppTypography.headingS.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            const _OutputDevices(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'hp_output_note'.tr,
              style: AppTypography.caption.copyWith(color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                color: c.divider,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.desc,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyL.copyWith(color: c.textPrimary),
                  ),
                  Text(
                    desc,
                    style: AppTypography.bodyM.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            AppSwitch(value: value, onChanged: onChanged, semanticLabel: title),
          ],
        ),
      ),
    );
  }
}

/// Current outputs as reported by the system (read-only).
class _OutputDevices extends StatefulWidget {
  const _OutputDevices();
  @override
  State<_OutputDevices> createState() => _OutputDevicesState();
}

class _OutputDevicesState extends State<_OutputDevices> {
  Set<AudioDevice> _devices = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final session = await AudioSession.instance;
      final d = await session.getDevices(includeInputs: false);
      if (mounted) setState(() => _devices = d);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final headsets = _devices
        .where((d) => MuvikAudioHandler.isHeadsetDevice(d.type))
        .toList();
    final usingHeadset = headsets.isNotEmpty;
    Widget row(IconData icon, String title, String sub, bool active) =>
        ListTile(
          minTileHeight: 64,
          leading: Icon(icon, color: active ? c.primary : c.iconDefault),
          title: Text(
            title,
            style: AppTypography.bodyL.copyWith(color: c.textPrimary),
          ),
          subtitle: Text(
            sub,
            style: AppTypography.bodyM.copyWith(color: c.textSecondary),
          ),
          trailing: AppRadio(selected: active),
        );
    return SettingsGroupCard(
      children: [
        row(
          Icons.volume_up_rounded,
          'hp_speaker'.tr,
          'hp_speaker_desc'.tr,
          !usingHeadset,
        ),
        if (headsets.isEmpty)
          row(
            Icons.headphones_rounded,
            'hp_headset'.tr,
            'hp_not_connected'.tr,
            false,
          )
        else
          for (final d in headsets)
            row(
              Icons.headphones_rounded,
              d.name.isEmpty ? 'hp_headset'.tr : d.name,
              'hp_connected'.tr,
              true,
            ),
      ],
    );
  }
}
