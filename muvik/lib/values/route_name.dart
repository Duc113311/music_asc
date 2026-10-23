/// All route paths. Never use literals in widgets/controllers (P02-05).
/// Figma key → route mapping is documented in docs/screen_map.md.
class RouteName {
  RouteName._();

  static const String splash = '/splash'; // sc_splash
  static const String onboarding = '/onboarding'; // sc_onBrg_01..03
  static const String setup = '/setup'; // sc_step_01..03
  static const String home =
      '/home'; // shell + sc_navibar (sc_home, library, sc_kham_pha, sc_cat_dat)
  static const String player = '/player'; // Sc_phat_nhac
  static const String search = '/search';
  static const String songList = '/songs'; // album/artist/folder/list detail
  static const String playlistDetail = '/playlist';
  static const String playlistForm =
      '/playlist/form'; // sc_bthShet_tao_playlist (full form)
  static const String statisticsSongs = '/statistics/songs';
  static const String statisticsArtist = '/statistics/artist';
  static const String scanLibrary = '/settings/scan'; // sc_quet_thu_vien
  static const String sleepTimer = '/settings/sleep-timer'; // sc_hen_gio_tat
  static const String equalizer = '/settings/equalizer'; // sc_bo_chinh_am
  static const String playbackQuality =
      '/settings/quality'; // sc_chat_luong_phat
  static const String headphones =
      '/settings/headphones'; // sc_phat_qua_tai_nghe
  static const String theme = '/settings/theme'; // sc_theme
  static const String permissions = '/settings/permissions';
  static const String feedback = '/settings/feedback'; // sc_feedback
  static const String componentPreview = '/debug/components';
}
