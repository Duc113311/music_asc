import 'package:get/get.dart';

import '../models/ui_models/period_type.dart';
import '../services/application/listening_stats_service.dart';
import '../services/application/statistics_service.dart';

/// Week/Month/Year statistics. Changing type keeps an anchor date; arrows move
/// by one period and never into a fully future period (P16-17, P16-18).
class StatisticsController extends GetxController {
  final StatisticsService _service = Get.find();
  final ListeningStatsService _stats = Get.find();

  final Rx<StatsPeriod> period = StatsPeriod.containing(
    PeriodType.week,
    DateTime.now(),
  ).obs;
  final Rxn<PeriodStats> stats = Rxn<PeriodStats>();
  final RxBool loading = true.obs;
  final RxBool failed = false.obs;
  final RxnInt selectedBucket = RxnInt();

  int _token = 0;

  @override
  void onInit() {
    super.onInit();
    _stats.revision.addListener(load);
    load();
  }

  @override
  void onClose() {
    _stats.revision.removeListener(load);
    super.onClose();
  }

  bool get canGoNext => !period.value.next().isFuture(DateTime.now());

  Future<void> load() async {
    final token = ++_token;
    loading.value = stats.value == null;
    failed.value = false;
    try {
      // Flush pending listening so the current period is up to date.
      await _stats.flush();
      final r = await _service.load(period.value);
      if (token != _token) return;
      stats.value = r;
    } catch (_) {
      if (token == _token) failed.value = true;
    } finally {
      if (token == _token) loading.value = false;
    }
  }

  void setType(PeriodType t) {
    if (t == period.value.type) return;
    _apply(period.value.switchType(t, DateTime.now()));
  }

  void previous() => _apply(period.value.previous());

  void next() {
    if (canGoNext) _apply(period.value.next());
  }

  /// Applied from the calendar dialogs; Cancel never calls this (P16-16).
  void applyPeriod(StatsPeriod p) {
    if (p.isFuture(DateTime.now())) return;
    _apply(p);
  }

  void _apply(StatsPeriod p) {
    period.value = p;
    selectedBucket.value = null;
    stats.value = null;
    load();
  }

  void selectBucket(int? i) =>
      selectedBucket.value = i == selectedBucket.value ? null : i;
}
