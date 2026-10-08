import '../../utils/date_utils.dart';

enum PeriodType { week, month, year }

/// A statistics period as local dates: [start, end) where end is exclusive.
class StatsPeriod {
  const StatsPeriod._(this.type, this.start, this.end);

  final PeriodType type;
  final DateTime start;
  final DateTime end;

  /// Builds the period of [type] containing [anchor] (local date).
  /// Weeks run Monday..Sunday.
  factory StatsPeriod.containing(PeriodType type, DateTime anchor) {
    final d = AppDateUtils.dateOnly(anchor);
    switch (type) {
      case PeriodType.week:
        final start = AppDateUtils.addDays(d, -(d.weekday - DateTime.monday));
        return StatsPeriod._(type, start, AppDateUtils.addDays(start, 7));
      case PeriodType.month:
        return StatsPeriod._(
          type,
          DateTime(d.year, d.month, 1),
          DateTime(d.year, d.month + 1, 1),
        );
      case PeriodType.year:
        return StatsPeriod._(
          type,
          DateTime(d.year, 1, 1),
          DateTime(d.year + 1, 1, 1),
        );
    }
  }

  String get startKey => AppDateUtils.formatDateKey(start);
  String get endKey => AppDateUtils.formatDateKey(end);

  /// Number of chart buckets: 7 days, N days of month, 12 months.
  int get bucketCount {
    switch (type) {
      case PeriodType.week:
        return 7;
      case PeriodType.month:
        return AppDateUtils.daysInMonth(start.year, start.month);
      case PeriodType.year:
        return 12;
    }
  }

  /// Date key (day) or month key (year view) of bucket [i].
  String bucketKey(int i) {
    if (type == PeriodType.year) {
      return AppDateUtils.formatMonthKey(DateTime(start.year, i + 1, 1));
    }
    return AppDateUtils.formatDateKey(AppDateUtils.addDays(start, i));
  }

  StatsPeriod previous() {
    switch (type) {
      case PeriodType.week:
        return StatsPeriod.containing(type, AppDateUtils.addDays(start, -7));
      case PeriodType.month:
        return StatsPeriod.containing(
          type,
          DateTime(start.year, start.month - 1, 1),
        );
      case PeriodType.year:
        return StatsPeriod.containing(type, DateTime(start.year - 1, 1, 1));
    }
  }

  StatsPeriod next() => StatsPeriod.containing(type, end);

  bool contains(DateTime t) {
    final d = AppDateUtils.dateOnly(t);
    return !d.isBefore(start) && d.isBefore(end);
  }

  /// Entirely in the future: starts after today.
  bool isFuture(DateTime now) => start.isAfter(AppDateUtils.dateOnly(now));
  bool isCurrent(DateTime now) => contains(now);

  /// Switching Week/Month/Year keeps an anchor date (today if inside the
  /// current period, otherwise the period start) — P16-18.
  StatsPeriod switchType(PeriodType newType, DateTime now) {
    final anchor = contains(now) ? now : start;
    return StatsPeriod.containing(newType, anchor);
  }

  @override
  bool operator ==(Object other) =>
      other is StatsPeriod && other.type == type && other.start == start;

  @override
  int get hashCode => Object.hash(type, start);

  @override
  String toString() => 'StatsPeriod(${type.name} $startKey..$endKey)';
}
