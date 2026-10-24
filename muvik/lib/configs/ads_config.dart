/// AdMob ad unit ids. Muvik shows no ads yet (`AppConfig.adsEnabled = false`),
/// so these are Google's public sample units, safe to ship while ads are off.
/// Replace with Muvik's own units before turning ads on;
/// `DspAdsConfig.isAdTestIds` already swaps in test ids outside Product builds.
class AdsConfig {
  AdsConfig._();

  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String appOpenAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';
  static const String nativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
}
