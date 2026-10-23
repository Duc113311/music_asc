import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../controller/statistics_controller.dart';
import '../../models/ui_models/period_type.dart';
import '../../services/application/statistics_service.dart';
import '../../utils/date_utils.dart';
import '../../utils/duration_formatter.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../bottom_sheets/song_actions_sheet.dart';
import '../common_components/app_controls.dart';
import '../common_components/app_nav.dart';
import '../common_components/app_touchable.dart';
import '../common_components/cards.dart';
import '../common_components/mini_player.dart';
import '../common_components/song_artwork.dart';
import '../common_components/state_views.dart';
import '../dialogs/period_picker_dialogs.dart';
import 'statistics_artist_screen.dart';
import 'statistics_songs_screen.dart';

String periodLabel(StatsPeriod p) {
  final locale = Get.locale?.toLanguageTag();
  switch (p.type) {
    case PeriodType.week:
      final last = AppDateUtils.addDays(p.end, -1);
      final f = DateFormat.MMMd(locale);
      return '${f.format(p.start)} – ${f.format(last)}';
    case PeriodType.month:
      return toBeginningOfSentenceCase(
        DateFormat.yMMMM(locale).format(p.start),
      );
    case PeriodType.year:
      return '${p.start.year}';
  }
}

String bucketLabel(StatsPeriod p, int i) {
  switch (p.type) {
    case PeriodType.week:
      return 'weekday_short_${i + 1}'.tr;
    case PeriodType.month:
      return '${i + 1}';
    case PeriodType.year:
      return 'month_short_${i + 1}'.tr;
  }
}

String bucketLongLabel(StatsPeriod p, int i) {
  final locale = Get.locale?.toLanguageTag();
  if (p.type == PeriodType.year) {
    return toBeginningOfSentenceCase(
      DateFormat.yMMMM(locale).format(DateTime(p.start.year, i + 1)),
    );
  }
  return DateFormat.yMMMEd(locale).format(AppDateUtils.addDays(p.start, i));
}

/// Short name of a bucket for the "most listening" line: weekday for a week
/// ("Chủ nhật"), day/month for a month ("18/9"), month for a year ("Tháng 8").
String bucketPeakLabel(StatsPeriod p, int i) {
  final locale = Get.locale?.toLanguageTag();
  switch (p.type) {
    case PeriodType.week:
      return toBeginningOfSentenceCase(
        DateFormat.EEEE(locale).format(AppDateUtils.addDays(p.start, i)),
      );
    case PeriodType.month:
      final d = AppDateUtils.addDays(p.start, i);
      return '${d.day}/${d.month}';
    case PeriodType.year:
      return toBeginningOfSentenceCase(
        DateFormat.MMMM(locale).format(DateTime(p.start.year, i + 1)),
      );
  }
}

/// Tab "Thống kê" (week / month / year), the third tab of the home shell.
class StatisticsTab extends StatelessWidget {
  const StatisticsTab({super.key, required this.scrollController});
  final ScrollController scrollController;

  /// Lives as long as the tab: created on first open, kept by the shell.
  static StatisticsController _controller() =>
      Get.isRegistered<StatisticsController>()
          ? Get.find<StatisticsController>()
          : Get.put(StatisticsController(), permanent: true);

  Future<void> _pickPeriod(StatisticsController controller) async {
    final p = controller.period.value;
    final picked = switch (p.type) {
      PeriodType.week => await showWeekPicker(p),
      PeriodType.month => await showMonthPicker(p),
      PeriodType.year => await showYearPicker(p),
    };
    if (picked != null) controller.applyPeriod(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final controller = _controller();
    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: Obx(() {
          final p = controller.period.value;
          final s = controller.stats.value;
          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.md,
                    AppSpacing.xs,
                    0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'stats_title'.tr,
                              style: AppTypography.headingL.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'stats_subtitle'.tr,
                              style: AppTypography.bodyL.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppIconButton(
                        icon: Icons.calendar_month_rounded,
                        tooltip: 'stats_pick_period'.tr,
                        filled: true,
                        onPressed: () => _pickPeriod(controller),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.md,
                    AppSpacing.screenH,
                    0,
                  ),
                  child: SegmentedTabs(
                    labels: [
                      'period_week'.tr,
                      'period_month'.tr,
                      'period_year'.tr,
                    ],
                    index: p.type.index,
                    onChanged: (i) => controller.setType(PeriodType.values[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      AppIconButton(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'stats_prev_period'.tr,
                        color: c.textPrimary,
                        onPressed: controller.previous,
                      ),
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: 'stats_pick_period'.tr,
                          child: InkWell(
                            onTap: () => _pickPeriod(controller),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              child: Text(
                                periodLabel(p),
                                textAlign: TextAlign.center,
                                style: AppTypography.headingS.copyWith(
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      AppIconButton(
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'stats_next_period'.tr,
                        color: c.textPrimary,
                        onPressed: controller.canGoNext ? controller.next : null,
                      ),
                    ],
                  ),
                ),
                if (controller.loading.value)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: LoadingState(),
                  )
                else if (controller.failed.value)
                  ErrorState(
                    message: 'stats_load_failed'.tr,
                    onRetry: controller.load,
                  )
                else if (s != null) ...[
                  _Summary(stats: s),
                  _ChartCard(stats: s),
                  if (s.isEmpty)
                    EmptyState(
                      compact: true,
                      icon: Icons.insights_rounded,
                      title: 'stats_no_data'.tr,
                      message: 'stats_no_data_desc'.tr,
                    )
                  else ...[
                    _TopSongs(stats: s),
                    _TopArtist(stats: s),
                  ],
                ],
                const MiniPlayerSpacer(),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Icon in a tinted circle, as on the two summary cards.
class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.stats});
  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final vsKey = switch (stats.period.type) {
      PeriodType.week => 'stats_vs_prev_week',
      PeriodType.month => 'stats_vs_prev_month',
      PeriodType.year => 'stats_vs_prev_year',
    };

    Widget change(double? pct) {
      if (pct == null) {
        return Text(
          'stats_no_comparison'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(color: c.textMuted),
        );
      }
      final up = pct >= 0;
      final color = up ? c.success : c.error;
      return Row(
        children: [
          Icon(
            up ? Icons.star_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              vsKey.trParams({'args1': '${up ? '+' : ''}${pct.round()}%'}),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: color),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.xs,
        AppSpacing.screenH,
        0,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.headphones_rounded,
                color: c.primary,
                label: 'stats_listen_time'.tr,
                value: DurationFormatter.listening(stats.totalMs),
                footer: change(stats.totalChangePct),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                icon: Icons.music_note_rounded,
                color: c.info,
                label: 'stats_songs_listened'.tr,
                value: 'count_songs_n'.trParams({
                  'args1': '${stats.distinctSongs}',
                }),
                footer: Text(
                  'stats_from_library'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: c.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.footer,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          _IconCircle(icon: icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: AppTypography.headingS.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                footer,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounds [rawMax] up so [divisions] equal steps land on round numbers.
double _niceMax(double rawMax, int divisions) {
  final rough = rawMax / divisions;
  final exp = (math.log(rough) / math.ln10).floor();
  final mag = math.pow(10, exp).toDouble();
  for (final m in const [1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10]) {
    if (mag * m >= rough) return mag * m * divisions;
  }
  return mag * 10 * divisions;
}

class _ChartCard extends GetView<StatisticsController> {
  const _ChartCard({required this.stats});
  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = stats.period;
    final buckets = stats.buckets;
    final hours = buckets.map((b) => b.listenedMs / 3600000).toList();
    final maxH = hours.fold<double>(0, (a, b) => b > a ? b : a);
    // Minutes when the period is small, hours otherwise.
    final useMinutes = maxH < 1;
    final values = useMinutes
        ? buckets.map((b) => b.listenedMs / 60000).toList()
        : hours;
    final maxV = values.fold<double>(0, (a, b) => b > a ? b : a);
    final maxY = _niceMax(maxV <= 0 ? 1 : maxV * 1.05, 5);
    final interval = maxY / 5;
    final peak = stats.peakBucket;
    final title = switch (p.type) {
      PeriodType.week => 'stats_rhythm_week'.tr,
      PeriodType.month => 'stats_rhythm_month'.tr,
      PeriodType.year => 'stats_rhythm_year'.tr,
    };
    return Obx(() {
      final sel = controller.selectedBucket.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.sm,
          AppSpacing.screenH,
          0,
        ),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.headingS.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    useMinutes ? 'unit_minutes'.tr : 'unit_hours'.tr,
                    style: AppTypography.caption.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 190,
                child: stats.totalMs == 0
                    ? Center(
                        child: Text(
                          'stats_no_data'.tr,
                          style: AppTypography.bodyM.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      )
                    : Semantics(
                        label: title,
                        child: BarChart(
                          BarChartData(
                            maxY: maxY,
                            minY: 0,
                            alignment: BarChartAlignment.spaceAround,
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                bottom: BorderSide(
                                  color: c.textPrimary.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              drawVerticalLine: false,
                              horizontalInterval: interval,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: c.textPrimary.withValues(alpha: 0.12),
                                strokeWidth: 0.6,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(),
                              rightTitles: const AxisTitles(),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 34,
                                  interval: interval,
                                  getTitlesWidget: (v, meta) => SizedBox(
                                    width: 34,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        v <= 0
                                            ? '0'
                                            : v.toStringAsFixed(
                                                v < 10 && v != v.roundToDouble()
                                                    ? 1
                                                    : 0,
                                              ),
                                        textAlign: TextAlign.right,
                                        maxLines: 1,
                                        softWrap: false,
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 11,
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: 1,
                                  getTitlesWidget: (v, meta) {
                                    final i = v.toInt();
                                    final show =
                                        p.type != PeriodType.month ||
                                        i == 0 ||
                                        ((i + 1) % 5 == 0 &&
                                            (values.length - i - 1 >= 2 ||
                                                i == values.length - 1)) ||
                                        i == values.length - 1;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Text(
                                        show ? bucketLabel(p, i) : '',
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 11,
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barTouchData: BarTouchData(
                              touchCallback: (event, resp) {
                                if (event is FlTapUpEvent) {
                                  controller.selectBucket(
                                    resp?.spot?.touchedBarGroupIndex,
                                  );
                                }
                              },
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBorderRadius: BorderRadius.circular(6),
                                getTooltipColor: (_) =>
                                    Colors.black.withValues(alpha: 0.75),
                                getTooltipItem: (group, gi, rod, ri) =>
                                    BarTooltipItem(
                                      '${bucketLongLabel(p, gi)}\n${DurationFormatter.listening(buckets[gi].listenedMs)} • ${'stats_plays_n'.trParams({'args1': '${buckets[gi].plays}'})}',
                                      AppTypography.caption.copyWith(
                                        color: c.textPrimary,
                                      ),
                                    ),
                              ),
                            ),
                            barGroups: [
                              for (var i = 0; i < values.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: values[i],
                                      width: switch (p.type) {
                                        PeriodType.week => 26,
                                        PeriodType.month => 8,
                                        PeriodType.year => 18,
                                      },
                                      // Rounded top like the design.
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(
                                          p.type == PeriodType.month ? 3 : 6,
                                        ),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: i == (sel ?? peak)
                                            ? [c.secondary, c.primary]
                                            : [c.primaryLight, c.primary],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
              if (peak != null || sel != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _PeakPill(
                  stats: stats,
                  bucket: sel ?? peak!,
                  selected: sel != null,
                  onTap: () => _openBucket(sel ?? peak!),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Future<void> _openBucket(int i) async {
    final p = stats.period;
    final String start;
    final String end;
    if (p.type == PeriodType.year) {
      start = AppDateUtils.formatDateKey(DateTime(p.start.year, i + 1, 1));
      end = AppDateUtils.formatDateKey(DateTime(p.start.year, i + 2, 1));
    } else {
      final d = AppDateUtils.addDays(p.start, i);
      start = AppDateUtils.formatDateKey(d);
      end = AppDateUtils.formatDateKey(AppDateUtils.addDays(d, 1));
    }
    final ranked = await Get.find<StatisticsService>().songsInRange(start, end);
    final songs = ranked.map((r) => r.song).toList();
    await AppNav.openSongs(
      SongListArgs(
        title: bucketLongLabel(p, i),
        subtitle: 'stats_songs_in_period'.tr,
        songs: () => songs,
        emptyMessage: 'stats_no_data'.tr,
      ),
    );
  }
}

/// "Nghe nhiều nhất vào **Chủ nhật**": crown, text with the value in the
/// accent color. Tapping opens the songs listened in that bucket.
class _PeakPill extends StatelessWidget {
  const _PeakPill({
    required this.stats,
    required this.bucket,
    required this.selected,
    required this.onTap,
  });

  final PeriodStats stats;
  final int bucket;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = stats.period;
    final value = bucketPeakLabel(p, bucket);
    final full = selected
        ? '$value • ${DurationFormatter.listening(stats.buckets[bucket].listenedMs)}'
        : 'stats_peak'.trParams({'args1': value});
    final base = AppTypography.bodyM.copyWith(color: c.textPrimary);
    final at = full.indexOf(value);
    final text = at < 0
        ? Text(full, style: base)
        : Text.rich(
            TextSpan(
              style: base,
              children: [
                TextSpan(text: full.substring(0, at)),
                TextSpan(
                  text: value,
                  style: base.copyWith(
                    color: c.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: full.substring(at + value.length)),
              ],
            ),
          );
    return Semantics(
      button: true,
      label: '${'stats_view_songs'.tr}: $value',
      child: Material(
        color: c.surfaceSelected,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.input),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: c.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: text),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopSongs extends StatelessWidget {
  const _TopSongs({required this.stats});
  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final pc = PlaybackController.to;
    final top = stats.topSongs.take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sm,
        AppSpacing.screenH,
        0,
      ),
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            SectionHeader(
              title: 'stats_top_songs'.tr,
              titleStyle: AppTypography.headingS,
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, 0, 0),
              onMore: () => Get.toNamed(
                RouteName.statisticsSongs,
                arguments: StatisticsSongsArgs(
                  period: stats.period,
                  songs: stats.topSongs,
                ),
              ),
            ),
            for (var i = 0; i < top.length; i++)
              RankedSongRow(
                rank: i + 1,
                item: top[i],
                onTap: () =>
                    pc.playFrom(top.map((e) => e.song).toList(), top[i].song),
                onMore: () => showSongActions(top[i].song),
              ),
          ],
        ),
      ),
    );
  }
}

class RankedSongRow extends StatelessWidget {
  const RankedSongRow({
    super.key,
    required this.rank,
    required this.item,
    required this.onTap,
    required this.onMore,
    this.showTime = false,
  });

  final int rank;
  final RankedSong item;
  final VoidCallback onTap;
  final VoidCallback onMore;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = item.song;
    return Opacity(
      opacity: s.available ? 1 : 0.5,
      child: InkWell(
        onTap: s.available ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 32),
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xxs),
                    child: Text(
                      rank.toString().padLeft(2, '0'),
                      maxLines: 1,
                      softWrap: false,
                      style: AppTypography.headingS.copyWith(color: c.primary),
                    ),
                  ),
                ),
                SongArtwork(song: s, size: 52),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.songTitle.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        s.available
                            ? (s.artistOrNull ?? 'unknown_artist'.tr)
                            : 'song_unavailable'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyM.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  showTime
                      ? DurationFormatter.listening(item.listenedMs)
                      : 'stats_plays_n'.trParams({'args1': '${item.plays}'}),
                  maxLines: 1,
                  softWrap: false,
                  style: AppTypography.bodyM.copyWith(color: c.textPrimary),
                ),
                const SizedBox(width: AppSpacing.xxs),
                AppIconButton(
                  icon: Icons.more_vert_rounded,
                  tooltip: 'song_menu'.tr,
                  onPressed: onMore,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Nghệ sĩ bạn nghe nhiều nhất": the single top artist of the period with a
/// round cover (taken from one of their songs), name, time and a bars icon.
class _TopArtist extends StatelessWidget {
  const _TopArtist({required this.stats});
  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (stats.topArtists.isEmpty) return const SizedBox.shrink();
    final a = stats.topArtists.first;
    final cover = LibraryController.to.songs.firstWhereOrNull(
      (s) => s.available && s.artistOrNull == a.artist,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sm,
        AppSpacing.screenH,
        0,
      ),
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            SectionHeader(
              title: 'stats_top_artists'.tr,
              titleStyle: AppTypography.headingS,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                0,
                AppSpacing.xs,
              ),
            ),
            InkWell(
              onTap: () => Get.toNamed(
                RouteName.statisticsArtist,
                arguments: StatisticsArtistArgs(
                  artist: a.artist,
                  period: stats.period,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [c.secondary, c.primary],
                        ),
                      ),
                      child: ClipOval(
                        child: cover == null
                            ? Container(
                                width: 60,
                                height: 60,
                                color: c.surfaceSelected,
                                child: Icon(
                                  Icons.person_rounded,
                                  color: c.primary,
                                  size: 32,
                                ),
                              )
                            : SongArtwork(song: cover, size: 60),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.artist ?? 'unknown_artist'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headingS.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DurationFormatter.listening(a.listenedMs),
                            style: AppTypography.bodyM.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.bar_chart_rounded, color: c.primary, size: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
