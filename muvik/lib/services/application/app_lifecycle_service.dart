
import 'package:dsp_base/dsp_base.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../native/system_ui_channel.dart';

/// App-wide lifecycle hub: the single `WidgetsBindingObserver` of the app.
/// Registered permanent in `main.dart`, so it sees every transition on any
/// route (splash, onboarding, player...), not only while a given screen is
/// mounted.
///
/// What it owns itself:
/// * resumed -> re-hide the device navigation bar (immersive mode);
/// * every transition -> Crashlytics breadcrumb, so a later crash keeps the
///   "what was the app doing" context.
///
/// Screens and controllers that need to react (library refresh, stats flush,
/// nudge scheduling...) subscribe with [addResumedListener] /
/// [addBackgroundListener] and unsubscribe in `dispose`, instead of each mixing
/// in its own observer.
class AppLifecycleService extends GetxService with WidgetsBindingObserver {
  static AppLifecycleService get to => Get.find<AppLifecycleService>();

  /// Latest lifecycle state (starts as resumed: the app is in the foreground
  /// when this is created).
  final Rx<AppLifecycleState> current = AppLifecycleState.resumed.obs;

  final List<VoidCallback> _onResumed = [];
  final List<VoidCallback> _onBackground = [];

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Called each time the app returns to the foreground.
  void addResumedListener(VoidCallback listener) => _onResumed.add(listener);
  void removeResumedListener(VoidCallback listener) =>
      _onResumed.remove(listener);

  /// Called when the app goes to the background (paused) or is detached; the
  /// OS may kill the process right after, so persist pending work here.
  void addBackgroundListener(VoidCallback listener) =>
      _onBackground.add(listener);
  void removeBackgroundListener(VoidCallback listener) =>
      _onBackground.remove(listener);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    current.value = state;
    if (DspFirebaseService.isCoreReady) {
      DspCrashlytics.log('lifecycle: ${state.name}');
    }
    switch (state) {
      case AppLifecycleState.resumed:
        SystemUiChannel.hideNavigationBar();
        _notify(_onResumed);
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _notify(_onBackground);
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Copies the list first: a listener may unsubscribe itself while running.
  void _notify(List<VoidCallback> listeners) {
    for (final listener in List<VoidCallback>.of(listeners)) {
      listener();
    }
  }
}
