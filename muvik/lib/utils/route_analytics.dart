import 'package:dsp_base/dsp_base.dart';
import 'package:get/get.dart';

import 'app_log.dart';

/// Logs a screen_view for every named-route navigation from one place instead
/// of instrumenting each screen. Same approach as smart_drink.
///
/// Wired into `GetMaterialApp.routingCallback` in `main.dart`. GetX fires the
/// callback more than once per navigation, so this dedupes on the route string
/// and skips overlays (bottom sheets/dialogs) that reuse the current route.
/// Tabs inside the home shell are not routes; they are not logged here.
class RouteAnalytics {
  RouteAnalytics._();

  static String? _lastLoggedRoute;

  static void onRouting(Routing? routing) {
    if (routing == null) return;
    if (routing.isBottomSheet == true || routing.isDialog == true) return;
    final route = routing.current;
    if (route.isEmpty || route == _lastLoggedRoute) return;
    _lastLoggedRoute = route;

    if (!DspFirebaseService.isCoreReady || !Get.isRegistered<DspAnalytics>()) {
      return;
    }
    DspAnalytics.to.logScreenView(route).catchError((Object e) {
      AppLog.info('screen_view $route skipped: $e');
    });
  }
}
