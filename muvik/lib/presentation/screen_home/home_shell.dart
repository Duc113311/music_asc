import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../services/application/listening_stats_service.dart';
import '../../utils/toast_utils.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/mini_player.dart';
import '../screen_dashboard/dashboard_tab.dart';
import '../screen_explore/explore_tab.dart';
import '../screen_library/library_tab.dart';
import '../screens_settings/settings_tab.dart';

/// Shell with 4 lazily built tabs kept alive in an IndexedStack, so scroll
/// position and filters survive tab switches (P08-01). Re-tapping the current
/// tab scrolls it to the top (spec §4.1).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  final Set<int> _built = {0};
  final List<ScrollController> _scrolls = List.generate(
    4,
    (_) => ScrollController(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cold start from the media notification: show Now Playing (P17-06).
    if (AudioService.notificationClicked.value) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => PlaybackController.to.openNowPlaying(),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final s in _scrolls) {
      s.dispose();
    }
    ToastUtils.bottomInset.value = 0;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LibraryController.to.scanService.refreshOnResume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Persist pending listening time before the OS may kill the UI process.
      Get.find<ListeningStatsService>().flush();
    }
  }

  void _select(int i) {
    if (i == _index) {
      final s = _scrolls[i];
      if (s.hasClients) {
        s.animateTo(0, duration: AppMotion.overlay, curve: AppMotion.curve);
      }
      return;
    }
    setState(() {
      _index = i;
      _built.add(i);
    });
  }

  Widget _tab(int i) => switch (i) {
    0 => DashboardTab(
      scrollController: _scrolls[0],
      onOpenLibrary: () => _select(1),
    ),
    1 => LibraryTab(scrollController: _scrolls[1]),
    2 => ExploreTab(scrollController: _scrolls[2]),
    _ => SettingsTab(scrollController: _scrolls[3]),
  };

  @override
  Widget build(BuildContext context) {
    final pc = PlaybackController.to;
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(
              index: _index,
              children: [
                for (var i = 0; i < 4; i++)
                  _built.contains(i) ? _tab(i) : const SizedBox.shrink(),
              ],
            ),
            // With extendBody the body's bottom padding equals the nav bar.
            Builder(
              builder: (context) => Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.paddingOf(context).bottom + 8,
                child: const MiniPlayer(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Obx(() {
          // Toasts sit above the nav bar and mini player.
          final inset =
              AppSizes.navBar + (pc.hasSong ? AppSizes.miniPlayer + 16 : 0);
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => ToastUtils.bottomInset.value = inset,
          );
          return _NavBar(index: _index, onSelect: _select);
        }),
      ),
    );
  }
}

/// sc_navibar: exactly 4 tabs — Trang chủ, Thư viện, Khám phá, Cài đặt.
class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'tab_home'),
    (Icons.library_music_outlined, Icons.library_music_rounded, 'tab_library'),
    (Icons.explore_outlined, Icons.explore_rounded, 'tab_explore'),
    (Icons.settings_outlined, Icons.settings_rounded, 'tab_settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.navBar,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    label: _items[i].$3.tr,
                    excludeSemantics: true,
                    child: InkResponse(
                      onTap: () => onSelect(i),
                      child: Center(
                        child: AnimatedContainer(
                          duration: AppMotion.state,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: i == index
                                ? c.surfaceSelected
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppRadius.input,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                i == index ? _items[i].$2 : _items[i].$1,
                                color: i == index ? c.primary : c.iconDefault,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _items[i].$3.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.navigation.copyWith(
                                  color: i == index
                                      ? c.primary
                                      : c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
