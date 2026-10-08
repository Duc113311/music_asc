import 'package:get/get.dart';

class DurationFormatter {
  DurationFormatter._();

  /// m:ss or h:mm:ss for track positions.
  static String clock(Duration d) {
    final neg = d.isNegative;
    final t = d.abs();
    final h = t.inHours;
    final m = t.inMinutes.remainder(60);
    final s = t.inSeconds.remainder(60).toString().padLeft(2, '0');
    final body = h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
    return neg ? '-$body' : body;
  }

  static String clockMs(int ms) => clock(Duration(milliseconds: ms));

  /// "12 giờ 45 phút" / "45 phút" / "30 giây" for statistics.
  static String listening(int ms) {
    final d = Duration(milliseconds: ms);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) {
      return m > 0
          ? 'fmt_hours_minutes'.trParams({'args1': '$h', 'args2': '$m'})
          : 'fmt_hours'.trParams({'args1': '$h'});
    }
    if (d.inMinutes > 0) {
      return 'fmt_minutes'.trParams({'args1': '${d.inMinutes}'});
    }
    if (ms > 0) return 'fmt_seconds'.trParams({'args1': '${d.inSeconds}'});
    return 'fmt_minutes'.trParams({'args1': '0'});
  }

  /// Total length of a list: "1 giờ 12 phút".
  static String total(int ms) => listening(ms);

  static String fileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var v = bytes.toDouble();
    var i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
  }
}
