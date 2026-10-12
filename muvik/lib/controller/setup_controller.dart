import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../configs/pref_const.dart';
import '../configs/pref_defaults.dart';
import '../models/data_models/music_source.dart';
import '../models/ui_models/scan_state.dart';
import '../services/application/library_scan_service.dart';
import '../services/storage/pref_store.dart';
import '../values/route_name.dart';
import 'library_controller.dart';

/// Three-step setup (permission → sources/scan → result). The step is saved so
/// an interrupted setup reopens at the same step (P06-08).
class SetupController extends GetxController with WidgetsBindingObserver {
  final LibraryScanService _scan = Get.find();
  LibraryController get library => LibraryController.to;

  final RxInt step = 0.obs;
  final Rx<AudioPermissionStatus> permission = AudioPermissionStatus.denied.obs;

  /// The user tapped "Cho phép" and was refused at least once.
  final RxBool askedOnce = false.obs;
  final RxBool requesting = false.obs;
  final RxSet<int> selected = <int>{}.obs;
  final RxList<MusicSource> sources = <MusicSource>[].obs;
  final Rx<ScanState> scanState = const ScanState().obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    step.value = PrefStore.getInt(
      PrefConst.setupStep,
      PrefDefaults.setupStep,
    ).clamp(0, 2);
    _scan.sources.addListener(_onSources);
    _scan.state.addListener(_onScan);
    _scan.permission.addListener(_onPermission);
    _onPermission();
    _onSources();
    _onScan();
    _scan.refreshSources();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _scan.sources.removeListener(_onSources);
    _scan.state.removeListener(_onScan);
    _scan.permission.removeListener(_onPermission);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from system settings: re-check and continue if granted.
    if (state == AppLifecycleState.resumed && step.value == 0) {
      _scan.checkPermission().then((s) async {
        if (s == AudioPermissionStatus.granted) {
          await _scan.refreshSources();
          goTo(1);
        }
      });
    }
  }

  void _onPermission() => permission.value = _scan.permission.value;
  void _onScan() => scanState.value = _scan.state.value;

  void _onSources() {
    sources.assignAll(_scan.sources.value);
    // Preselect sources the user enabled earlier (or defaults).
    if (selected.isEmpty) {
      selected.addAll(
        sources.where((s) => s.enabled && s.accessible).map((s) => s.id!),
      );
    }
    selected.removeWhere(
      (id) => !sources.any((s) => s.id == id && s.accessible),
    );
  }

  void goTo(int s) {
    step.value = s;
    PrefStore.setInt(PrefConst.setupStep, s);
  }

  // ---------- step 1 ----------

  Future<void> requestPermission() async {
    if (requesting.value) return;
    requesting.value = true;
    try {
      if (permission.value == AudioPermissionStatus.permanentlyDenied) {
        await _scan.openSystemSettings();
        return;
      }
      final s = await _scan.requestPermission();
      if (s == AudioPermissionStatus.granted) {
        await _askNotifications();
        await _scan.refreshSources();
        goTo(1);
      } else {
        askedOnce.value = true;
      }
    } finally {
      requesting.value = false;
    }
  }

  /// Android 13+ hides the playback notification (lock screen and shade
  /// controls) until this is granted; refusal is harmless.
  Future<void> _askNotifications() async {
    try {
      await Permission.notification.request();
    } catch (_) {}
  }

  /// "Để sau": continue with current access; folders can still be picked.
  Future<void> later() async {
    await PrefStore.setBool(PrefConst.permissionDeferred, true);
    await _askNotifications();
    goTo(1);
  }

  // ---------- step 2 ----------

  List<MusicSource> get selectableSources =>
      sources.where((s) => s.accessible).toList();

  bool get allSelected =>
      selectableSources.isNotEmpty &&
      selectableSources.every((s) => selected.contains(s.id));

  void toggle(MusicSource s) {
    if (!s.accessible) return;
    if (!selected.remove(s.id)) selected.add(s.id!);
  }

  /// "Chọn tất cả" covers only sources with granted access (P05-04).
  void toggleAll() {
    if (allSelected) {
      selected.clear();
    } else {
      selected.addAll(selectableSources.map((s) => s.id!));
    }
  }

  Future<void> pickFolder() async {
    final s = await _scan.addFolderSource();
    if (s != null) selected.add(s.id!);
  }

  Future<void> startScan() async {
    if (selected.isEmpty) return;
    await _scan.setSourcesEnabled(selected.toSet());
    final r = await _scan.scan(onlySourceIds: selected.toSet());
    if (r.status == ScanStatus.success || r.status == ScanStatus.partial) {
      goTo(2);
    }
  }

  void cancelScan() => _scan.cancel();

  // ---------- step 3 ----------

  Future<void> finish() async {
    await PrefStore.setBool(PrefConst.setupCompleted, true);
    // Setup scans with the genre-aware schema; no backfill needed later.
    await PrefStore.setBool(PrefConst.genreBackfillDone, true);
    await PrefStore.setInt(PrefConst.setupStep, 0);
    Get.offAllNamed(RouteName.home);
  }

  void chooseAgain() => goTo(1);

  Future<void> rescan() async {
    goTo(1);
    await startScan();
  }
}
