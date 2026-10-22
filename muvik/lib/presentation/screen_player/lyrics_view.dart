import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/playback_controller.dart';
import '../../models/data_models/lyrics.dart';
import '../../services/application/lyrics_service.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';

/// Lyrics page of the player: LRC lyrics follow the playback position (tap a
/// line to jump there), plain lyrics just scroll.
class LyricsView extends StatefulWidget {
  const LyricsView({super.key, required this.uri});

  final String uri;

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  late Future<Lyrics?> _future = LyricsService.load(widget.uri);

  @override
  void didUpdateWidget(LyricsView old) {
    super.didUpdateWidget(old);
    if (old.uri != widget.uri) _future = LyricsService.load(widget.uri);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FutureBuilder<Lyrics?>(
      key: ValueKey(widget.uri),
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: c.primary,
              ),
            ),
          );
        }
        final lyrics = snap.data;
        if (lyrics == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lyrics_outlined,
                    size: 40,
                    color: c.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'lyrics_empty'.tr,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyL.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return _LyricsList(lyrics: lyrics);
      },
    );
  }
}

class _LyricsList extends StatefulWidget {
  const _LyricsList({required this.lyrics});
  final Lyrics lyrics;

  @override
  State<_LyricsList> createState() => _LyricsListState();
}

class _LyricsListState extends State<_LyricsList> {
  late final List<GlobalKey> _keys = List.generate(
    widget.lyrics.lines.length,
    (_) => GlobalKey(),
  );
  int _current = -1;

  void _follow(int index) {
    if (index == _current) return;
    _current = index;
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[index].currentContext;
      if (!mounted || ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pc = PlaybackController.to;
    final lyrics = widget.lyrics;
    return LayoutBuilder(
      builder: (context, box) {
        return ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0, 0.12, 0.88, 1],
          ).createShader(r),
          blendMode: BlendMode.dstIn,
          child: Obx(() {
            final index = lyrics.indexAt(pc.position.value);
            if (lyrics.synced) _follow(index);
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: box.maxHeight / 2 - 20,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < lyrics.lines.length; i++)
                    _line(c, lyrics, i, i == index, pc),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _line(
    AppColors c,
    Lyrics lyrics,
    int i,
    bool active,
    PlaybackController pc,
  ) {
    final line = lyrics.lines[i];
    final text = AnimatedDefaultTextStyle(
      key: _keys[i],
      duration: const Duration(milliseconds: 250),
      textAlign: TextAlign.center,
      style: (active ? AppTypography.headingS : AppTypography.bodyL).copyWith(
        color: active
            ? c.textPrimary
            : c.textSecondary.withValues(alpha: lyrics.synced ? 0.6 : 1),
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        height: 1.4,
      ),
      child: Text(line.text.isEmpty ? '♪' : line.text),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: line.time == null
          ? text
          : InkWell(
              borderRadius: BorderRadius.circular(AppRadius.input),
              onTap: () => pc.seek(line.time!),
              child: SizedBox(width: double.infinity, child: text),
            ),
    );
  }
}
