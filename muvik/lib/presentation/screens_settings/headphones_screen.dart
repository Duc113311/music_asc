import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/settings_controller.dart';
import '../../services/application/audio_handler.dart';
import '../../utils/app_log.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_typography.dart';
import '../common_components/app_controls.dart';
import 'settings_detail_widgets.dart';

/// sc_phat_qua_tai_nghe: disconnect pauses by default; reconnect resumes only
/// if enabled; headset buttons can be turned off (P14-11, P17-09).
class HeadphonesScreen extends StatelessWidget {
  const HeadphonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SettingsController.to;
    return DetailScaffold(
      title: 'settings_headphones'.tr,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13.5, 0, 13.5, 24),
        children: [
          const _Hero(),
          DetailSectionLabel('hp_when_connected'.tr),
          Obx(
            () => DetailCard(
              dividerIndent: 18,
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
          const SizedBox(height: 27),
          DetailSectionLabel('hp_output'.tr),
          const _OutputDevices(),
        ],
      ),
    );
  }
}

/// img_tai_nghe placed so the headphones match the mockup (≈130pt wide);
/// the glow is allowed to bleed past the screen edges.
class _Hero extends StatelessWidget {
  const _Hero();

  // Asset 1881×836; the headphones span y 146..704 px.
  static const _scale = 129 / 558;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 164,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 12.5 - 146 * _scale,
            child: Image.asset(
              AppAssets.headphones,
              width: 1881 * _scale,
              height: 836 * _scale,
              fit: BoxFit.fill,
            ),
          ),
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
    final p = DetailPalette.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 13, 8, 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyL.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 255),
                    child: Text(
                      desc,
                      style: AppTypography.bodyM.copyWith(
                        fontSize: 12,
                        height: 1.45,
                        color: p.muted,
                      ),
                    ),
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
    } catch (e) {
      AppLog.info('HeadphonesScreen.load: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final headsets = _devices
        .where((d) => MuvikAudioHandler.isHeadsetDevice(d.type))
        .toList();
    final usingHeadset = headsets.isNotEmpty;
    final p = DetailPalette.of(context);
    // Read-only: Android picks the output; the radio shows the active one.
    Widget row(IconData icon, String title, String sub, bool active) =>
        Semantics(
          selected: active,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 15, 18, 15),
            child: Row(
              children: [
                Icon(icon, size: 27, color: active ? c.primary : p.muted),
                const SizedBox(width: 26),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyL.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: active ? p.text : p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: AppTypography.bodyM.copyWith(
                          fontSize: 12,
                          color: p.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                AppRadio(selected: active, size: 22),
              ],
            ),
          ),
        );
    return DetailCard(
      dividerIndent: 18,
      children: [
        row(
          Icons.volume_up_outlined,
          'hp_speaker'.tr,
          'hp_speaker_desc'.tr,
          !usingHeadset,
        ),
        if (headsets.isEmpty)
          row(
            Icons.headphones_outlined,
            'hp_headset'.tr,
            'hp_not_connected'.tr,
            false,
          )
        else
          for (final d in headsets)
            row(
              Icons.headphones_outlined,
              d.name.isEmpty ? 'hp_headset'.tr : d.name,
              'hp_connected'.tr,
              true,
            ),
      ],
    );
  }
}
