import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../models/ui_models/scan_state.dart';
import '../../services/application/library_scan_service.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../common_components/app_controls.dart';
import '../common_components/source_widgets.dart';
import '../common_components/state_views.dart';
import 'settings_detail_widgets.dart';

/// sc_quet_thu_vien. While scanning: progress ring, counts, current folder,
/// the three scan steps, "Chạy nền" (leave, scan keeps running) and
/// "Dừng quét". Otherwise: the result, source choice and "Quét lại"
/// (P14-02/03).
class ScanLibraryScreen extends StatelessWidget {
  const ScanLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = LibraryController.to;
    final scan = lib.scanService;
    return Obx(() {
      final s = lib.scan.value;
      final running = s.isRunning;
      final sources = lib.sources.toList();
      final accessible = sources.where((x) => x.accessible).toList();
      final hasEnabled = sources.any((x) => x.enabled && x.accessible);
      return DetailScaffold(
        title: 'scan_library_title'.tr,
        titleSize: 20,
        titleWeight: FontWeight.w600,
        bottom: SafeArea(
          minimum: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13.5, 8, 12.6, 0),
            child: running
                ? Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.open_in_new_rounded,
                          title: 'scan_run_bg'.tr,
                          subtitle: 'scan_run_bg_desc'.tr,
                          filled: false,
                          onTap: () => Get.back<void>(),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.stop_rounded,
                          title: 'scan_stop'.tr,
                          subtitle: 'scan_stop_desc'.tr,
                          filled: true,
                          onTap: scan.cancel,
                        ),
                      ),
                    ],
                  )
                : _ActionButton(
                    icon: Icons.refresh_rounded,
                    title: 'action_rescan'.tr,
                    filled: true,
                    onTap: hasEnabled ? () => lib.startScan() : null,
                  ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(11.8, 0, 11.4, 12),
          children: [
            _Hero(state: s),
            const SizedBox(height: 13),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Counts(
                    songs: lib.availableCount,
                    albums: lib.albums.length,
                    artists: lib.artists.length,
                  ),
                  if (running) ...[
                    const SizedBox(height: 12.6),
                    _CurrentFolder(name: s.currentSource),
                    const SizedBox(height: 12.7),
                    _Steps(state: s, albums: lib.albums.length),
                  ] else ...[
                    if (lib.permission.value !=
                        AudioPermissionStatus.granted) ...[
                      const SizedBox(height: 12.6),
                      InfoBanner(
                        message: 'no_audio_permission'.tr,
                        actionLabel: 'action_grant'.tr,
                        onAction: () => Get.toNamed(RouteName.permissions),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _SourcesHeader(
                      showToggle: accessible.length > 1,
                      allOn:
                          accessible.isNotEmpty &&
                          accessible.every((x) => x.enabled),
                      onToggle: (allOn) => scan.setSourcesEnabled(
                        allOn ? <int>{} : accessible.map((x) => x.id!).toSet(),
                      ),
                    ),
                    for (final src in sources)
                      SourceTile(
                        source: src,
                        selected: src.enabled,
                        onTap: () => scan.setSourceEnabled(src, !src.enabled),
                        trailing: AppCheckbox(
                          value: src.enabled && src.accessible,
                          enabled: src.accessible,
                        ),
                      ),
                    PickFolderTile(onTap: scan.addFolderSource),
                  ],
                  const SizedBox(height: 12.2),
                  const _InfoCard(),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Sunset art with the progress ring, sound wave and status lines.
class _Hero extends StatelessWidget {
  const _Hero({required this.state});
  final ScanState state;

  @override
  Widget build(BuildContext context) {
    final p = DetailPalette.of(context);
    final s = state;
    final (title, subtitle) = switch (s.status) {
      ScanStatus.scanning => ('scan_finding'.tr, 'scan_subtitle'.tr),
      ScanStatus.idle => ('scan_ready'.tr, 'scan_subtitle'.tr),
      ScanStatus.success => (
        s.hasChanges ? 'scan_done'.tr : 'scan_no_changes'.tr,
        _summary(s),
      ),
      ScanStatus.partial => ('scan_partial'.tr, _summary(s)),
      ScanStatus.error => ('scan_error'.tr, ''),
      ScanStatus.cancelled => ('scan_cancelled'.tr, _summary(s)),
    };
    return Semantics(
      liveRegion: true,
      child: SizedBox(
        height: 256,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 219,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF000000), Color(0x00000000)],
                    stops: [0.62, 1],
                  ).createShader(r),
                  child: Image.asset(AppAssets.scanHero, fit: BoxFit.cover),
                ),
              ),
            ),
            Positioned(
              top: 94 - 70,
              left: 0,
              right: 0,
              child: Center(child: _ProgressRing(state: s)),
            ),
            Positioned(
              top: 182,
              left: 0,
              right: 0,
              child: Center(child: _SoundWave(active: s.isRunning)),
            ),
            Positioned(
              top: 209,
              left: 8,
              right: 8,
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headingS.copyWith(
                      fontSize: 17.5,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyM.copyWith(
                      fontSize: 13,
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _summary(ScanState s) => [
    '${'scan_new'.tr}: ${s.added}',
    '${'scan_updated'.tr}: ${s.updated}',
    '${'scan_skipped'.tr}: ${s.skipped}',
    if (s.markedMissing > 0) '${'scan_missing'.tr}: ${s.markedMissing}',
  ].join(' · ');
}

/// 140pt ring: determinate arc + "78%", a spinning arc + processed count
/// when the total is unknown, or a check / note icon when not scanning.
class _ProgressRing extends StatefulWidget {
  const _ProgressRing({required this.state});
  final ScanState state;

  @override
  State<_ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<_ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool get _indeterminate =>
      widget.state.isRunning && widget.state.fraction == null;

  @override
  void initState() {
    super.initState();
    if (_indeterminate) _spin.repeat();
  }

  @override
  void didUpdateWidget(_ProgressRing old) {
    super.didUpdateWidget(old);
    if (_indeterminate && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!_indeterminate && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = widget.state;
    final fraction = s.isRunning ? s.fraction : (s.isFinished ? 1.0 : 0.0);
    final Widget center;
    if (s.isRunning && fraction != null) {
      center = Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${(fraction * 100).floor()}',
              style: AppTypography.display.copyWith(
                fontSize: 44,
                height: 1,
                color: Colors.white,
              ),
            ),
            TextSpan(
              text: '%',
              style: AppTypography.display.copyWith(
                fontSize: 22,
                height: 1,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else if (s.isRunning) {
      center = Text(
        '${s.processed}',
        style: AppTypography.display.copyWith(
          fontSize: 34,
          height: 1,
          color: Colors.white,
        ),
      );
    } else {
      center = Icon(
        s.isFinished ? Icons.check_rounded : Icons.music_note_rounded,
        size: 46,
        color: Colors.white,
      );
    }
    return SizedBox.square(
      dimension: 140,
      child: AnimatedBuilder(
        animation: _spin,
        builder: (context, child) => CustomPaint(
          painter: _RingPainter(
            color: c.primary,
            fraction: _indeterminate ? 0.28 : (fraction ?? 0),
            startTurn: _indeterminate ? _spin.value : 0,
          ),
          child: child,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.color,
    required this.fraction,
    required this.startTurn,
  });

  final Color color;
  final double fraction;
  final double startTurn;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - stroke / 2 - 1,
    );
    canvas.drawCircle(
      rect.center,
      rect.width / 2 + stroke / 2,
      Paint()..color = const Color(0x8C0E0E1C),
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = const Color(0xB3262035)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (fraction <= 0) return;
    final start = -math.pi / 2 + startTurn * math.pi * 2;
    final sweep = math.pi * 2 * fraction.clamp(0, 1);
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawArc(rect, start, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.startTurn != startTurn ||
      old.color != color;
}

/// Dotted ends + symmetric bars, as under the ring in the mockup.
class _SoundWave extends StatelessWidget {
  const _SoundWave({required this.active});
  final bool active;

  static const _bars = <double>[
    5.0,
    9,
    14,
    7,
    22,
    12,
    5,
    9,
    16,
    26,
    11,
    8,
    19,
    30,
    19,
    8,
    11,
    26,
    16,
    9,
    5,
    12,
    22,
    7,
    14,
    9,
    5,
  ];

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(context.colors.primary, Colors.white, 0.1)!;
    return ExcludeSemantics(
      child: Opacity(
        opacity: active ? 1 : 0.55,
        child: SizedBox(
          height: 30,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 7; i++) _dot(color),
              for (final h in _bars)
                Container(
                  width: 1.6,
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 1.2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              for (var i = 0; i < 7; i++) _dot(color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 1.8,
    height: 1.8,
    margin: const EdgeInsets.symmetric(horizontal: 1.6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.8),
      shape: BoxShape.circle,
    ),
  );
}

class _Counts extends StatelessWidget {
  const _Counts({
    required this.songs,
    required this.albums,
    required this.artists,
  });

  final int songs;
  final int albums;
  final int artists;

  @override
  Widget build(BuildContext context) {
    final p = DetailPalette.of(context);
    Widget sep() => Container(width: 1, height: 52, color: p.border);
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          _Count(Icons.music_note_outlined, songs, 'count_songs'.tr),
          sep(),
          _Count(Icons.album_outlined, albums, 'count_albums'.tr),
          sep(),
          _Count(Icons.person_outline_rounded, artists, 'count_artists'.tr),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.icon, this.value, this.label);
  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = DetailPalette.of(context);
    return Expanded(
      child: Semantics(
        label: '$value $label',
        excludeSemantics: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: c.primary),
            Text(
              '$value',
              style: AppTypography.headingS.copyWith(
                fontSize: 19,
                height: 1.25,
                color: p.text,
              ),
            ),
            Text(
              label,
              style: AppTypography.bodyM.copyWith(
                fontSize: 12.5,
                height: 1.25,
                color: p.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentFolder extends StatelessWidget {
  const _CurrentFolder({required this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = DetailPalette.of(context);
    return DetailCard(
      children: [
        SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 13),
              Icon(Icons.folder_outlined, size: 26, color: c.primary),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'scan_current_folder'.tr,
                      style: AppTypography.caption.copyWith(
                        fontSize: 11.5,
                        color: p.muted,
                      ),
                    ),
                    Text(
                      name ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyL.copyWith(
                        fontSize: 14,
                        color: p.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }
}

enum _StepStatus { done, running, waiting }

/// The three scan steps; each row expands to show its numbers.
class _Steps extends StatefulWidget {
  const _Steps({required this.state, required this.albums});
  final ScanState state;
  final int albums;

  @override
  State<_Steps> createState() => _StepsState();
}

class _StepsState extends State<_Steps> {
  final Set<ScanPhase> _open = {};

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    _StepStatus status(ScanPhase p) => p.index < s.phase.index
        ? _StepStatus.done
        : (p == s.phase ? _StepStatus.running : _StepStatus.waiting);
    String detail(ScanPhase p) => switch (p) {
      ScanPhase.reading =>
        s.total != null
            ? 'scan_processed_of'.trParams({
                'args1': '${s.processed}',
                'args2': '${s.total}',
              })
            : 'scan_processed'.trParams({'args1': '${s.processed}'}),
      ScanPhase.albums => '${widget.albums} ${'count_albums'.tr}',
      ScanPhase.updating => _Hero._summary(s),
    };
    const titles = {
      ScanPhase.reading: 'scan_step_read',
      ScanPhase.albums: 'scan_step_albums',
      ScanPhase.updating: 'scan_step_update',
    };
    return DetailCard(
      dividerIndent: 12.5,
      children: [
        for (final p in ScanPhase.values)
          _StepRow(
            title: titles[p]!.tr,
            status: status(p),
            detail: detail(p),
            open: _open.contains(p),
            onTap: () => setState(
              () => _open.contains(p) ? _open.remove(p) : _open.add(p),
            ),
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.title,
    required this.status,
    required this.detail,
    required this.open,
    required this.onTap,
  });

  final String title;
  final _StepStatus status;
  final String detail;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = DetailPalette.of(context);
    final sub = switch (status) {
      _StepStatus.done => 'scan_step_done'.tr,
      _StepStatus.running => 'scan_step_running'.tr,
      _StepStatus.waiting => 'scan_step_waiting'.tr,
    };
    final Widget icon = switch (status) {
      _StepStatus.done => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
        child: Icon(Icons.check_rounded, size: 17, color: c.onPrimary),
      ),
      _StepStatus.running => SizedBox.square(
        dimension: 26,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          strokeCap: StrokeCap.round,
          color: c.primary,
          backgroundColor: p.border,
        ),
      ),
      _StepStatus.waiting => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: p.muted, width: 2.5),
        ),
      ),
    };
    return Semantics(
      button: true,
      expanded: open,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    icon,
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.bodyL.copyWith(
                              fontSize: 14,
                              height: 1.3,
                              color: p.text,
                            ),
                          ),
                          Text(
                            sub,
                            style: AppTypography.bodyM.copyWith(
                              fontSize: 12,
                              height: 1.3,
                              color: p.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 24,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (open)
                Padding(
                  padding: const EdgeInsets.only(left: 41, top: 6),
                  child: Text(
                    detail,
                    style: AppTypography.caption.copyWith(color: p.muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourcesHeader extends StatelessWidget {
  const _SourcesHeader({
    required this.showToggle,
    required this.allOn,
    required this.onToggle,
  });

  final bool showToggle;
  final bool allOn;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(child: DetailSectionLabel('scan_sources'.tr)),
        if (showToggle)
          TextButton(
            onPressed: () => onToggle(allOn),
            child: Text(
              allOn ? 'action_deselect_all'.tr : 'action_select_all'.tr,
              style: AppTypography.label.copyWith(color: c.primary),
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    final p = DetailPalette.of(context);
    return DetailCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 11, 12, 11),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 26, color: p.muted),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  '${'scan_bg_note_1'.tr}\n${'scan_bg_note_2'.tr}',
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
      ],
    );
  }
}

/// Two-line button of the bottom bar (outlined "Chạy nền", filled
/// "Dừng quét" / "Quét lại").
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.title,
    required this.filled,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = DetailPalette.of(context);
    final enabled = onTap != null;
    final fg = filled ? c.onPrimary : c.primary;
    final radius = BorderRadius.circular(12);
    return Semantics(
      button: true,
      enabled: enabled,
      label: title,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: filled ? c.primary : p.card,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: filled
                ? BorderSide.none
                : BorderSide(color: c.primary.withValues(alpha: 0.75)),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: SizedBox(
              height: 55,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 22, color: fg),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label.copyWith(
                            fontSize: 14.5,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10.5,
                        color: fg.withValues(alpha: 0.85),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
