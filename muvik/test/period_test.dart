import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/models/ui_models/period_type.dart';
import 'package:muvik/services/application/statistics_service.dart';

void main() {
  group('StatsPeriod (P19-05)', () {
    test('week runs Monday..Sunday and crosses months/years', () {
      final p = StatsPeriod.containing(
        PeriodType.week,
        DateTime(2026, 10, 1),
      ); // Thu
      expect(p.startKey, '2026-09-28');
      expect(p.endKey, '2026-10-05');
      expect(p.bucketCount, 7);
      final y = StatsPeriod.containing(PeriodType.week, DateTime(2026, 1, 1));
      expect(y.startKey, '2025-12-29');
    });

    test('Sunday belongs to the week that started on Monday', () {
      final p = StatsPeriod.containing(
        PeriodType.week,
        DateTime(2026, 10, 11),
      ); // Sun
      expect(p.startKey, '2026-10-05');
    });

    test('month bucket count handles 28/29/30/31 days', () {
      expect(
        StatsPeriod.containing(
          PeriodType.month,
          DateTime(2026, 2, 10),
        ).bucketCount,
        28,
      );
      expect(
        StatsPeriod.containing(
          PeriodType.month,
          DateTime(2028, 2, 10),
        ).bucketCount,
        29,
      );
      expect(
        StatsPeriod.containing(
          PeriodType.month,
          DateTime(2026, 4, 1),
        ).bucketCount,
        30,
      );
      expect(
        StatsPeriod.containing(
          PeriodType.month,
          DateTime(2026, 12, 31),
        ).bucketCount,
        31,
      );
    });

    test('year has 12 month buckets with month keys', () {
      final p = StatsPeriod.containing(PeriodType.year, DateTime(2026, 6, 1));
      expect(p.bucketCount, 12);
      expect(p.bucketKey(0), '2026-01');
      expect(p.bucketKey(11), '2026-12');
      expect(p.endKey, '2027-01-01');
    });

    test('previous/next move exactly one period', () {
      final m = StatsPeriod.containing(PeriodType.month, DateTime(2026, 1, 15));
      expect(m.previous().startKey, '2025-12-01');
      expect(m.next().startKey, '2026-02-01');
      final w = StatsPeriod.containing(PeriodType.week, DateTime(2026, 10, 7));
      expect(w.previous().startKey, '2026-09-28');
    });

    test('future periods are detected; current is not future', () {
      final now = DateTime(2026, 10, 7);
      expect(
        StatsPeriod.containing(PeriodType.week, now).isFuture(now),
        isFalse,
      );
      expect(
        StatsPeriod.containing(PeriodType.week, now).next().isFuture(now),
        isTrue,
      );
    });

    test('switching type keeps the anchor date', () {
      final now = DateTime(2026, 10, 7);
      final past = StatsPeriod.containing(
        PeriodType.month,
        DateTime(2025, 3, 20),
      );
      expect(past.switchType(PeriodType.year, now).startKey, '2025-01-01');
      expect(past.switchType(PeriodType.week, now).startKey, '2025-02-24');
      final cur = StatsPeriod.containing(PeriodType.month, now);
      expect(cur.switchType(PeriodType.week, now).startKey, '2026-10-05');
    });
  });

  group('PeriodStats comparison', () {
    test('previous period 0 gives no percentage (no divide by zero)', () {
      expect(PeriodStats.change(100, 0), isNull);
      expect(PeriodStats.change(150, 100), 50);
      expect(PeriodStats.change(50, 100), -50);
    });
  });
}
