import 'package:flutter/material.dart';
import '../common_components/app_touchable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../models/ui_models/period_type.dart';
import '../../utils/date_utils.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/primary_button.dart';
import '../common_components/primary_dialog.dart';
import '../screen_statistics/statistics_screen.dart';

/// Sc_dialog_tuan / sc_dialog_thang / Sc_dialoh_nam. Selection only edits a
/// draft; "Áp dụng" returns it, Cancel/X/Back return null (P16-13..P16-16).
Future<StatsPeriod?> showWeekPicker(StatsPeriod current) =>
    Get.dialog<StatsPeriod>(_PeriodDialog(initial: current));
Future<StatsPeriod?> showMonthPicker(StatsPeriod current) =>
    Get.dialog<StatsPeriod>(_PeriodDialog(initial: current));
Future<StatsPeriod?> showYearPicker(StatsPeriod current) =>
    Get.dialog<StatsPeriod>(_PeriodDialog(initial: current));

class _PeriodDialog extends StatefulWidget {
  const _PeriodDialog({required this.initial});
  final StatsPeriod initial;

  @override
  State<_PeriodDialog> createState() => _PeriodDialogState();
}

class _PeriodDialogState extends State<_PeriodDialog> {
  late StatsPeriod _draft = widget.initial;

  /// Month shown by the week calendar / year shown by the month grid /
  /// first year of the 12-year page.
  late DateTime _cursor = widget.initial.start;
  late int _yearPageStart =
      widget.initial.start.year - (widget.initial.start.year % 12) + 0;

  final DateTime _now = DateTime.now();
  PeriodType get _type => widget.initial.type;

  void _goCurrent() => setState(() {
        _draft = StatsPeriod.containing(_type, _now);
        _cursor = _draft.start;
        _yearPageStart = _now.year - (_now.year % 12);
      });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = switch (_type) {
      PeriodType.week => 'pick_week'.tr,
      PeriodType.month => 'pick_month'.tr,
      PeriodType.year => 'pick_year'.tr,
    };
    return AppDialog(
      onClose: () => Get.back<void>(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            // Leaves room for AppDialog's close button (top-right).
            padding: const EdgeInsets.only(right: 32),
            child: Text(
              title,
              style: AppTypography.headingS.copyWith(color: c.textPrimary),
            ),
          ),
          if (_type == PeriodType.week)
            Text(
              'pick_week_desc'.tr,
              style: AppTypography.bodyM.copyWith(color: c.textSecondary),
            ),
          const SizedBox(height: AppSpacing.md),
          switch (_type) {
            PeriodType.week => _weekCalendar(c),
            PeriodType.month => _monthGrid(c),
            PeriodType.year => _yearGrid(c),
          },
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${'pick_selected'.tr} ${periodLabel(_draft)}',
                  style: AppTypography.bodyM.copyWith(color: c.textPrimary),
                ),
              ),
              TextButton(
                onPressed: _goCurrent,
                child: Text(
                    switch (_type) {
                      PeriodType.week => 'pick_current_week'.tr,
                      PeriodType.month => 'pick_current_month'.tr,
                      PeriodType.year => 'pick_current_year'.tr,
                    },
                    style: AppTypography.label.copyWith(color: c.primary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'action_cancel'.tr,
                  variant: ButtonVariant.secondary,
                  onPressed: () async => Get.back<void>(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PrimaryButton(
                  label: 'action_apply'.tr,
                  height: AppSizes.buttonSecondary,
                  onPressed: () async => Get.back(result: _draft),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nav(
    AppColors c,
    String label,
    VoidCallback? prev,
    VoidCallback? next,
  ) =>
      Row(
        children: [
          AppIconButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'stats_prev_period'.tr,
            color: c.textPrimary,
            onPressed: prev,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(
                color: c.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
          AppIconButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'stats_next_period'.tr,
            color: c.textPrimary,
            onPressed: next,
          ),
        ],
      );

  Widget _weekCalendar(AppColors c) {
    final locale = Get.locale?.toLanguageTag();
    final month = DateTime(_cursor.year, _cursor.month, 1);
    final firstCell = AppDateUtils.addDays(
      month,
      -(month.weekday - DateTime.monday),
    );
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    final canNext = !nextMonth.isAfter(_now);
    final rows = <List<DateTime>>[];
    var d = firstCell;
    while (d.isBefore(nextMonth) || rows.length < 5) {
      rows.add([for (var i = 0; i < 7; i++) AppDateUtils.addDays(d, i)]);
      d = AppDateUtils.addDays(d, 7);
      if (rows.length == 6) break;
    }
    return Column(
      children: [
        _nav(
          c,
          toBeginningOfSentenceCase(DateFormat.yMMMM(locale).format(month)),
          () => setState(
            () => _cursor = DateTime(month.year, month.month - 1, 1),
          ),
          canNext ? () => setState(() => _cursor = nextMonth) : null,
        ),
        Row(
          children: [
            for (var i = 1; i <= 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    'weekday_short_$i'.tr,
                    style: AppTypography.caption.copyWith(color: c.textMuted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (final week in rows)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: _draft.contains(week.first)
                  ? c.surfaceSelected
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              children: [
                for (final day in week)
                  Expanded(
                    child: _Cell(
                      label: '${day.day}',
                      selected: _draft.contains(day) &&
                          AppDateUtils.dateOnly(day) ==
                              AppDateUtils.dateOnly(_now),
                      inRange: _draft.contains(day),
                      muted: day.month != month.month,
                      enabled: !AppDateUtils.dateOnly(
                        day,
                      ).isAfter(AppDateUtils.dateOnly(_now)),
                      onTap: () => setState(
                        () => _draft = StatsPeriod.containing(
                          PeriodType.week,
                          day,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _monthGrid(AppColors c) {
    final year = _cursor.year;
    return Column(
      children: [
        _nav(
          c,
          '$year',
          () => setState(() => _cursor = DateTime(year - 1, 1, 1)),
          year < _now.year
              ? () => setState(() => _cursor = DateTime(year + 1, 1, 1))
              : null,
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          mainAxisSpacing: AppSpacing.xs,
          crossAxisSpacing: AppSpacing.xs,
          children: [
            for (var m = 1; m <= 12; m++)
              _BoxCell(
                label: 'month_n'.trParams({'args1': '$m'}),
                selected: _draft.start.year == year && _draft.start.month == m,
                enabled: !DateTime(year, m, 1).isAfter(_now),
                onTap: () => setState(
                  () => _draft = StatsPeriod.containing(
                    PeriodType.month,
                    DateTime(year, m, 1),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _yearGrid(AppColors c) {
    final start = _yearPageStart;
    return Column(
      children: [
        _nav(
          c,
          '$start – ${start + 11}',
          () => setState(() => _yearPageStart -= 12),
          start + 12 <= _now.year
              ? () => setState(() => _yearPageStart += 12)
              : null,
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          mainAxisSpacing: AppSpacing.xs,
          crossAxisSpacing: AppSpacing.xs,
          children: [
            for (var y = start; y < start + 12; y++)
              _BoxCell(
                label: '$y',
                selected: _draft.start.year == y,
                enabled: y <= _now.year,
                onTap: () => setState(
                  () => _draft = StatsPeriod.containing(
                    PeriodType.year,
                    DateTime(y, 1, 1),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.selected,
    required this.inRange,
    required this.muted,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool inRange;
  final bool muted;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = !enabled
        ? c.textDisabled
        : (selected ? c.onPrimary : (muted ? c.textMuted : c.textPrimary));
    return Semantics(
      button: true,
      enabled: enabled,
      selected: inRange,
      child: InkResponse(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: 40,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? c.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                label,
                style: AppTypography.bodyM.copyWith(color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoxCell extends StatelessWidget {
  const _BoxCell({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: selected ? c.primary : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.imageSm + 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.imageSm + 4),
          onTap: enabled ? onTap : null,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.imageSm + 4),
              border: Border.all(color: selected ? c.primary : c.border),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppTypography.label.copyWith(
                  color: !enabled
                      ? c.textDisabled
                      : (selected ? c.onPrimary : c.textPrimary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
