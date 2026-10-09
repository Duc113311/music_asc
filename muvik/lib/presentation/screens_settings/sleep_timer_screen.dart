import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../configs/app_config.dart';
import '../../configs/pref_const.dart';
import '../../configs/pref_defaults.dart';
import '../../controller/playback_controller.dart';
import '../../services/storage/pref_store.dart';
import '../../utils/toast_utils.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_typography.dart';
import '../common_components/app_controls.dart';
import 'settings_detail_widgets.dart';

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

  Future<void> _start() async {
    await PlaybackController.to.sleepTimer.start(
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
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = DetailPalette.of(context);
    final pc = PlaybackController.to;
    return DetailScaffold(
      title: 'settings_sleep_timer'.tr,
      titleSize: 21,
      titleWeight: FontWeight.w600,
      body: Obx(() {
        final st = pc.sleep.value;
        final active = st.active;
        final now = DateTime.now();
        final stopAt = st.deadline ?? now.add(Duration(minutes: _minutes));
        final left = active && st.deadline != null
            ? st.remaining(now)
            : Duration(minutes: _minutes);
        final showTime = _valid || active;
        return ListView(
          padding: const EdgeInsets.fromLTRB(14.6, 4, 14.6, 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Text(
                'sleep_desc'.tr,
                style: AppTypography.bodyL.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  color: p.dark ? const Color(0xFF898AB2) : c.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 19),
            if (!active) ...[
              DetailCard(
                dividerIndent: 11.5,
                children: [
                  for (final m in AppConfig.sleepPresets)
                    _RadioRow(
                      label: 'fmt_minutes'.trParams({'args1': '$m'}),
                      selected: _preset == m,
                      onTap: () => setState(() => _preset = m),
                    ),
                ],
              ),
              const SizedBox(height: 14.5),
              DetailCard(
                padding: const EdgeInsets.only(bottom: 13),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RadioRow(
                        label: 'sleep_custom_time'.tr,
                        selected: _preset == null,
                        highlight: false,
                        height: 58,
                        onTap: () => setState(() => _preset = null),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 62),
                        child: Wrap(
                          spacing: 14,
                          runSpacing: 8,
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
                      ),
                      if (_preset == null && !_valid)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(62, 8, 16, 0),
                          child: Text(
                            'sleep_invalid'.tr,
                            style: AppTypography.caption.copyWith(
                              color: c.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14.5),
              DetailCard(
                children: [
                  InkWell(
                    onTap: () => setState(() => _wait = !_wait),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(17, 12, 8, 13),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'sleep_wait_end'.tr,
                                  style: AppTypography.bodyL.copyWith(
                                    fontSize: 15,
                                    color: p.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 250,
                                  ),
                                  child: Text(
                                    'sleep_wait_end_desc'.tr,
                                    style: AppTypography.bodyM.copyWith(
                                      fontSize: 12.5,
                                      height: 1.5,
                                      color: p.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Aligned with the title line, as in the mockup.
                          Transform.translate(
                            offset: const Offset(0, -12),
                            child: AppSwitch(
                              value: _wait,
                              semanticLabel: 'sleep_wait_end'.tr,
                              onChanged: (v) => setState(() => _wait = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
            ],
            _StopCard(
              label: st.waitingForTrackEnd
                  ? 'sleep_waiting_track'.tr
                  : 'sleep_stops_label'.tr,
              time: st.waitingForTrackEnd
                  ? null
                  : (showTime ? DateFormat.Hm().format(stopAt) : '--:--'),
              remaining: st.waitingForTrackEnd || !showTime
                  ? null
                  : 'sleep_remaining_about'.trParams({
                      'args1': '${(left.inSeconds / 60).ceil()}',
                    }),
            ),
            const SizedBox(height: 21),
            if (active)
              _PillButton(
                label: 'sleep_cancel'.tr,
                color: c.error,
                textColor: AppColors.onDestructive,
                onTap: () async {
                  await pc.sleepTimer.cancel();
                  ToastUtils.success('toast_timer_cancelled'.tr);
                },
              )
            else
              _PillButton(
                label: 'sleep_start'.tr,
                color: c.primary,
                textColor: c.onPrimary,
                onTap: _valid ? _start : null,
              ),
          ],
        );
      }),
    );
  }
}

/// Radio + label row of the preset list / custom card.
class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 54.5,
    this.highlight = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  /// Tints the selected row (preset list only).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = DetailPalette.of(context);
    final tint = p.dark
        ? const Color(0xFF1E2033)
        : context.colors.surfaceSelected;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected && highlight ? tint : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                const SizedBox(width: 17),
                AppRadio(selected: selected, size: 21),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyL.copyWith(
                      fontSize: 15.5,
                      color: p.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Nhạc sẽ dừng lúc" card: clock icon, time, and sunset art on the right.
class _StopCard extends StatelessWidget {
  const _StopCard({required this.label, this.time, this.remaining});
  final String label;
  final String? time;
  final String? remaining;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = DetailPalette.of(context);
    final sub = p.dark ? const Color(0xFF9194B7) : c.textSecondary;
    return Container(
      constraints: const BoxConstraints(minHeight: 107.5),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 148,
            // Fade the art into the card on its left edge.
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(
                colors: [Color(0x00000000), Color(0xFF000000)],
                stops: [0, 0.35],
              ).createShader(r),
              child: Image.asset(
                AppAssets.sleepSunset,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 13, 16, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 31,
                    color: c.primary,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.bodyM.copyWith(
                          fontSize: 12.5,
                          color: sub,
                        ),
                      ),
                      if (time != null)
                        Text(
                          time!,
                          style: AppTypography.display.copyWith(
                            fontSize: 27,
                            height: 1.25,
                            color: c.primary,
                          ),
                        ),
                      if (remaining != null)
                        Text(
                          remaining!,
                          style: AppTypography.bodyM.copyWith(
                            fontSize: 12.5,
                            color: sub,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width rounded CTA (accent start / red cancel).
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.color,
    required this.textColor,
    this.onTap,
  });
  final String label;
  final Color color;
  final Color textColor;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: enabled ? color : color.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: enabled ? () => onTap!() : null,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 51,
            child: Center(
              child: Text(
                label,
                style: AppTypography.label.copyWith(
                  fontSize: 16.5,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
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
    final p = DetailPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 90,
          height: 47.5,
          padding: const EdgeInsets.only(left: 18, right: 10),
          decoration: BoxDecoration(
            color: p.dark ? const Color(0xFF131823) : c.surfaceInput,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: p.dark ? const Color(0xFF252A3A) : c.border,
            ),
          ),
          child: DropdownButton<int>(
            value: value.clamp(0, count - 1),
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: c.surfaceElevated,
            menuMaxHeight: 320,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: p.textSecondary,
            ),
            // DropdownButton.style replaces the theme style entirely.
            style: AppTypography.headingS.copyWith(
              fontFamily: AppTypography.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: p.text,
            ),
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
        const SizedBox(width: 14),
        Text(
          label,
          style: AppTypography.bodyL.copyWith(
            fontSize: 15.5,
            color: Color.lerp(p.textSecondary, c.primary, 0.3),
          ),
        ),
      ],
    );
  }
}
