import 'package:dsp_base/dsp_base.dart';

import '../configs/ads_config.dart';

/// Shared App Open ad instance, same shape as smart_drink. Nothing loads it
/// while `AppConfig.adsEnabled` is false; when ads are turned on, call
/// `AppAds.openAd.load()` after `DspBase.start` and show it from the splash.
class AppAds {
  AppAds._();

  static final openAd = DspAppOpenAdService(
    adUnitId: AdsConfig.appOpenAdUnitId,
  );
}
