import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';

import '../models/data_models/song.dart';
import '../models/ui_models/repeat_mode.dart';
import '../services/application/audio_handler.dart';
import '../services/application/equalizer_service.dart';
import '../services/application/sleep_timer_service.dart';
import '../utils/toast_utils.dart';
import '../values/route_name.dart';

/// Observes the shared audio handler and forwards commands. Holds no player
/// of its own, so opening screens never creates a second engine (P07-17).
class PlaybackController extends GetxController {
  static PlaybackController get to => Get.find();

  final MuvikAudioHandler handler = Get.find();
  final SleepTimerService sleepTimer = Get.find();
  final EqualizerService equalizer = Get.find();

  final Rx<PlayerViewState> state = const PlayerViewState().obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<SleepTimerState> sleep = const SleepTimerState().obs;
  final Rx<EqualizerState> eq = const EqualizerState().obs;

  StreamSubscription<PlayerEvent>? _events;
  StreamSubscription<bool>? _notificationClicks;

  @override
  void onInit() {
    super.onInit();
    handler.view.addListener(_onView);
    handler.position.addListener(_onPosition);
    sleepTimer.state.addListener(_onSleep);
    equalizer.state.addListener(_onEq);
    _onView();
    _onPosition();
    _onSleep();
    _onEq();
    // Tapping the media notification opens Now Playing once (P17-06).
    _notificationClicks = AudioService.notificationClicked.listen((clicked) {
      if (clicked) openNowPlaying();
    });
    _events = handler.events.listen((e) {
      if (e.type == PlayerEventType.error && e.error != null) {
        ToastUtils.error(e.error!.messageKey.tr);
      }
    });
  }

  @override
  void onClose() {
    handler.view.removeListener(_onView);
    handler.position.removeListener(_onPosition);
    sleepTimer.state.removeListener(_onSleep);
    equalizer.state.removeListener(_onEq);
    _events?.cancel();
    _notificationClicks?.cancel();
    super.onClose();
  }

  void _onView() => state.value = handler.view.value;
  void _onPosition() => position.value = handler.position.value;
  void _onSleep() => sleep.value = sleepTimer.state.value;
  void _onEq() => eq.value = equalizer.state.value;

  Song? get currentSong => state.value.currentSong;
  bool get hasSong => state.value.hasSong;

  /// Plays a snapshot of [list] from [song]. Unavailable songs are skipped;
  /// a list with nothing playable creates no session (spec §5).
  Future<void> playFrom(
    List<Song> list,
    Song song, {
    bool openPlayer = false,
  }) async {
    final cur = currentSong;
    if (cur != null && cur.id == song.id && state.value.sourceLoaded) {
      // Same song already in this session: just open the player (spec §6.2).
      if (!state.value.playing) await handler.play();
      if (openPlayer) openNowPlaying();
      return;
    }
    if (!song.available) {
      ToastUtils.error('error_file_unavailable'.tr);
      return;
    }
    final playable = list.where((s) => s.available).toList();
    final start = playable.indexWhere((s) => s.id == song.id);
    await handler.playSongs(
      playable.map((s) => s.id!).toList(),
      startIndex: start < 0 ? 0 : start,
    );
    if (openPlayer) openNowPlaying();
  }

  Future<void> playAll(List<Song> list, {bool shuffle = false}) async {
    final playable = list.where((s) => s.available).toList();
    if (playable.isEmpty) {
      ToastUtils.error('error_nothing_playable'.tr);
      return;
    }
    await handler.playSongs(
      playable.map((s) => s.id!).toList(),
      startIndex: 0,
      shuffle: shuffle,
    );
  }

  Future<void> togglePlay() async {
    if (!hasSong) return;
    if (state.value.playing) {
      await handler.pause();
    } else {
      await handler.play();
    }
  }

  Future<void> next() => handler.skipToNext();
  Future<void> previous() => handler.skipToPrevious();
  Future<void> seek(Duration d) => handler.seek(d);
  Future<void> stop() => handler.stop();

  Future<void> setShuffle(bool on) => handler.setShuffle(on);
  Future<void> setRepeat(RepeatMode m) => handler.setRepeat(m);

  Future<void> addNext(List<Song> songs) async {
    final ids = songs.where((s) => s.available).map((s) => s.id!).toList();
    if (ids.isEmpty) return;
    if (!hasSong) {
      await handler.playSongs(ids);
      return;
    }
    await handler.addNext(ids);
    ToastUtils.success('toast_added_next'.tr);
  }

  Future<void> addToQueue(List<Song> songs) async {
    final ids = songs.where((s) => s.available).map((s) => s.id!).toList();
    if (ids.isEmpty) return;
    if (!hasSong) {
      await handler.playSongs(ids);
      return;
    }
    await handler.addEnd(ids);
    ToastUtils.success('toast_added_queue'.tr);
  }

  void openNowPlaying() {
    if (!hasSong) return;
    const blocked = {
      RouteName.player,
      RouteName.splash,
      RouteName.onboarding,
      RouteName.setup,
    };
    if (blocked.contains(Get.currentRoute)) return;
    Get.toNamed(RouteName.player);
  }
}
