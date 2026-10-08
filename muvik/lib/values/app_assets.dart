/// Asset paths (ASCII snake_case). Screen mapping:
/// - img_logo_app: splash, about, rate dialog
/// - bg_on_01..03: sc_onBrg_01..03
/// - ic_step_01..03: sc_step_01..03
/// - bg_theme_dark/light: splash + theme preview backgrounds
/// - img_feed_back: sc_feedback, img_rate_app: sc_rate_app
/// - img_tai_nghe: sc_phat_qua_tai_nghe, img_empty_library: empty library states
class AppAssets {
  AppAssets._();
  static const String _webp = 'assets/images/webp';
  static const String logo = '$_webp/img_logo_app.webp';
  static const String onboarding1 = '$_webp/bg_on_01.webp';
  static const String onboarding2 = '$_webp/bg_on_02.webp';
  static const String onboarding3 = '$_webp/bg_on_03.webp';
  static const String step1 = '$_webp/ic_step_01.webp';
  static const String step2 = '$_webp/ic_step_02.webp';
  static const String step3 = '$_webp/ic_step_03.webp';
  static const String bgDark = '$_webp/bg_theme_dark.webp';
  static const String bgLight = '$_webp/bg_theme_light.webp';
  static const String feedback = '$_webp/img_feed_back.webp';
  static const String rateApp = '$_webp/img_rate_app.webp';
  static const String headphones = '$_webp/img_tai_nghe.webp';
  static const String emptyLibrary = '$_webp/img_empty_library.webp';
}
