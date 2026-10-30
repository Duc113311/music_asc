import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../configs/pref_const.dart';
import '../configs/pref_defaults.dart';
import '../services/storage/pref_store.dart';
import 'tour_steps.dart';

/// Drives the first-run tour: which step is showing and which anchors are
/// mounted. `HomeShell` starts it once; `TourOverlay` renders whatever this
/// permanent controller exposes. Same shape as smart_drink's tour, without the
/// A/B variants (Muvik has a single look).
class TourController extends GetxController {
  static TourController get to => Get.find<TourController>();

  final RxBool active = false.obs;
  final RxInt index = 0.obs;

  /// Bumped when an anchor registers so the overlay re-measures.
  final RxInt anchorGeneration = 0.obs;

  /// Anchor keys by id; `TourAnchor` registers them.
  final Map<String, GlobalKey> anchors = <String, GlobalKey>{};

  TourStep get step => tourSteps[index.value];
  int get count => tourSteps.length;
  bool get isFirst => index.value == 0;
  bool get isLast => index.value == tourSteps.length - 1;

  bool get shouldStart =>
      !PrefStore.getBool(PrefConst.tourSeen, PrefDefaults.tourSeen);

  /// Anchors register from `initState`, i.e. mid-build: the Rx bump waits for
  /// the end of the frame so the overlay's Obx never rebuilds during build.
  void registerAnchor(String id, GlobalKey key) {
    anchors[id] = key;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => anchorGeneration.value++,
    );
  }

  void unregisterAnchor(String id, GlobalKey key) {
    if (anchors[id] == key) anchors.remove(id);
  }

  /// Resolves once [id] is registered, or false after [timeout].
  Future<bool> waitForAnchor(
    String id, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!anchors.containsKey(id)) {
      if (DateTime.now().isAfter(deadline)) return false;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return true;
  }

  /// Global rect of the anchor, or null while it is not laid out.
  Rect? anchorRect(String id) {
    final box = anchors[id]?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Set by `HomeShell`: opens a bottom-nav tab.
  void Function(int tab)? selectTab;

  bool _moving = false;

  /// Starts the tour if it has not been seen. [force] replays it.
  Future<bool> start({bool force = false}) async {
    if (active.value || (!force && !shouldStart)) return false;
    selectTab?.call(tourSteps.first.tab);
    if (!await waitForAnchor(tourSteps.first.anchorId)) return false;
    index.value = 0;
    active.value = true;
    return true;
  }

  Future<void> next() => _go(1);

  Future<void> previous() => _go(-1);

  /// Moves to the next showable step in [dir]: opens its tab and waits for its
  /// anchor. A step whose anchor never shows (e.g. an empty library) is
  /// skipped; running out of steps going forward ends the tour.
  Future<void> _go(int dir) async {
    if (!active.value || _moving) return;
    _moving = true;
    try {
      var i = index.value + dir;
      while (i >= 0 && i < tourSteps.length) {
        final s = tourSteps[i];
        selectTab?.call(s.tab);
        if (await waitForAnchor(
          s.anchorId,
          timeout: const Duration(seconds: 2),
        )) {
          index.value = i;
          return;
        }
        i += dir;
      }
      if (dir > 0) {
        active.value = false;
        await PrefStore.setBool(PrefConst.tourSeen, true);
      }
    } finally {
      _moving = false;
    }
  }

  /// Ends the tour (done or skipped); it is not shown again.
  Future<void> finish() async {
    active.value = false;
    await PrefStore.setBool(PrefConst.tourSeen, true);
  }
}
