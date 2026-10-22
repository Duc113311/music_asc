import 'package:flutter/widgets.dart';
import '../presentation/common_components/cards.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../controller/feedback_controller.dart';
import '../controller/onboarding_controller.dart';
import '../controller/playlist_detail_controller.dart';
import '../controller/search_controller.dart';
import '../controller/settings_controller.dart';
import '../controller/setup_controller.dart';
import '../controller/statistics_controller.dart';
import '../presentation/screen_debug/component_preview_screen.dart';
import '../presentation/screen_home/home_shell.dart';
import '../presentation/screen_library/song_list_screen.dart';
import '../presentation/screen_player/now_playing_screen.dart';
import '../presentation/screen_search/search_screen.dart';
import '../presentation/screen_splash/splash_screen.dart';
import '../presentation/screen_statistics/statistics_artist_screen.dart';
import '../presentation/screen_statistics/statistics_screen.dart';
import '../presentation/screen_statistics/statistics_songs_screen.dart';
import '../presentation/screens_onboarding/onboarding_screen.dart';
import '../presentation/screens_playlist/playlist_detail_screen.dart';
import '../presentation/screens_playlist/playlist_form_screen.dart';
import '../presentation/screens_settings/equalizer_screen.dart';
import '../presentation/screens_settings/feedback_screen.dart';
import '../presentation/screens_settings/headphones_screen.dart';
import '../presentation/screens_settings/permissions_screen.dart';
import '../presentation/screens_settings/playback_quality_screen.dart';
import '../presentation/screens_settings/scan_library_screen.dart';
import '../presentation/screens_settings/sleep_timer_screen.dart';
import '../presentation/screens_settings/theme_screen.dart';
import '../presentation/screens_setup/setup_screen.dart';
import 'route_name.dart';

/// Routes + bindings. Settings/Library/Playback controllers are permanent;
/// onboarding, setup, search, playlist, statistics and feedback controllers
/// are route-scoped and disposed with their route (P02-06).
class AppPages {
  AppPages._();

  /// Every route gets [_TransitionMiddleware] so "Hiệu ứng chuyển màn" can
  /// switch animations off app-wide.
  static final List<GetPage<dynamic>> pages = [
    for (final p in _pages)
      p.copy(middlewares: [...?p.middlewares, _TransitionMiddleware()]),
  ];

  static final List<GetPage<dynamic>> _pages = [
    GetPage(name: RouteName.splash, page: () => const SplashScreen()),
    GetPage(
      name: RouteName.onboarding,
      page: () => const OnboardingScreen(),
      binding: BindingsBuilder(() {
        Get.put(OnboardingController());
      }),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: RouteName.setup,
      page: () => const SetupScreen(),
      binding: BindingsBuilder(() {
        Get.put(SetupController());
      }),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: RouteName.home,
      page: () => const HomeShell(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: RouteName.player,
      page: () => const NowPlayingScreen(),
      transition: Transition.downToUp,
      fullscreenDialog: true,
    ),
    GetPage(
      name: RouteName.search,
      page: () => const SearchScreen(),
      binding: BindingsBuilder(() {
        Get.put(MusicSearchController());
      }),
    ),
    GetPage(name: RouteName.songList, page: () => const SongListScreen()),
    GetPage(
      name: RouteName.playlistDetail,
      page: () => const PlaylistDetailScreen(),
      binding: BindingsBuilder(() {
        Get.put(PlaylistDetailController());
      }),
    ),
    GetPage(
      name: RouteName.playlistForm,
      page: () => const PlaylistFormScreen(),
    ),
    GetPage(
      name: RouteName.statistics,
      page: () => const StatisticsScreen(),
      binding: BindingsBuilder(() {
        Get.put(StatisticsController());
      }),
    ),
    GetPage(
      name: RouteName.statisticsSongs,
      page: () => const StatisticsSongsScreen(),
    ),
    GetPage(
      name: RouteName.statisticsArtist,
      page: () => const StatisticsArtistScreen(),
    ),
    GetPage(name: RouteName.scanLibrary, page: () => const ScanLibraryScreen()),
    GetPage(name: RouteName.sleepTimer, page: () => const SleepTimerScreen()),
    GetPage(name: RouteName.equalizer, page: () => const EqualizerScreen()),
    GetPage(
      name: RouteName.playbackQuality,
      page: () => const PlaybackQualityScreen(),
    ),
    GetPage(name: RouteName.headphones, page: () => const HeadphonesScreen()),
    GetPage(name: RouteName.theme, page: () => const ThemeScreen()),
    GetPage(name: RouteName.permissions, page: () => const PermissionsScreen()),
    GetPage(
      name: RouteName.feedback,
      page: () => const FeedbackScreen(),
      binding: BindingsBuilder(() {
        Get.put(FeedbackController());
      }),
    ),
    if (kDebugMode)
      GetPage(
        name: RouteName.componentPreview,
        page: () => const ComponentPreviewScreen(),
      ),
  ];
}

/// Replaces the route animation with none while screen transitions are off.
class _TransitionMiddleware extends GetMiddleware {
  @override
  Widget onPageBuilt(Widget page) => AppBackground(child: page);

  @override
  GetPage<dynamic>? onPageCalled(GetPage<dynamic>? page) {
    if (page == null ||
        !Get.isRegistered<SettingsController>() ||
        SettingsController.to.screenTransitions.value) {
      return page;
    }
    return page.copy(
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    );
  }
}
