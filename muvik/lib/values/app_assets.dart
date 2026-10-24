/// Asset paths (ASCII snake_case). Screen mapping:
/// - img_logo_muvik_v4 (png): splash, about, rate dialog; also the source of the launcher icons
/// - bg_on_01..03 (webp): backgrounds of sc_onBrg_01..03
/// - ic_step_01..03: sc_step_01..03
/// - bg_theme_dark/light: splash backgrounds
/// - img_theme_cover: cover art in the sc_theme player mockups
/// - img_sleep_sunset: art of the sc_hen_gio_tat stop-time card
/// - img_feedback_hero: chat bubbles of the Gửi phản hồi mockup
/// - img_scan_hero: sunset behind the sc_quet_thu_vien progress ring
/// - img_explore_*: art of the three sc_kham_pha suggestion cards
/// - img_feed_back: sc_feedback, img_rate_app: sc_rate_app
/// - img_tai_nghe: sc_phat_qua_tai_nghe, img_empty_library: empty library states
class AppAssets {
  AppAssets._();
  static const String _webp = 'assets/images/webp';
  // Home hero slides (1706x922, artwork on the right, dark on the left for text).
  static const String homeSlide1 = '$_webp/slide_1.webp';
  static const String homeSlide2 = '$_webp/slide_2.webp';
  static const String homeSlide3 = '$_webp/slide_3.webp';
  static const String logo = 'assets/images/png/img_logo_muvik_v4.png';
  static const String onboarding1 = '$_webp/bg_on_01.webp';
  static const String onboarding2 = '$_webp/bg_on_02.webp';
  static const String onboarding3 = '$_webp/bg_on_03.webp';
  static const String step1 = '$_webp/ic_step_01.webp';
  static const String step2 = '$_webp/ic_step_02.webp';
  static const String step3 = '$_webp/ic_step_03.webp';
  static const String exploreReplay = '$_webp/img_explore_replay.webp';
  static const String exploreLeast = '$_webp/img_explore_least.webp';
  static const String exploreRandom = '$_webp/img_explore_random.webp';
  static const String scanHero = '$_webp/img_scan_hero.webp';
  static const String feedbackHero = '$_webp/img_feedback_hero.webp';
  static const String sleepSunset = '$_webp/img_sleep_sunset.webp';
  static const String themeCover = '$_webp/img_theme_cover.webp';
  static const String bgDark = '$_webp/bg_theme_dark.webp';
  static const String bgLight = '$_webp/bg_theme_light.webp';
  static const String feedback = '$_webp/img_feed_back.webp';
  static const String rateApp = '$_webp/img_rate_app.webp';
  static const String headphones = '$_webp/img_tai_nghe.webp';
  static const String emptyLibrary = '$_webp/img_empty_library.webp';
}
