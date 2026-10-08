/// Date helpers. Date keys are local 'YYYY-MM-DD' strings (P04-10).
class AppDateUtils {
  AppDateUtils._();

  static String todayKey([DateTime? now]) =>
      formatDateKey(now ?? DateTime.now());

  static String formatDateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_pad2(d.month)}-${_pad2(d.day)}';

  static String formatMonthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_pad2(d.month)}';

  static DateTime parseDateKey(String key) {
    final p = key.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Calendar-day addition that is safe across DST changes.
  static DateTime addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  /// Start of the next local day after [t].
  static DateTime nextMidnight(DateTime t) =>
      DateTime(t.year, t.month, t.day + 1);

  static String _pad2(int v) => v.toString().padLeft(2, '0');
}
