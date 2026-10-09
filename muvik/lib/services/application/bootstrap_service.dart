import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../configs/pref_const.dart';
import '../../configs/pref_defaults.dart';
import '../storage/database_helper.dart';
import '../storage/pref_store.dart';
import 'audio_handler.dart';
import 'auth_service.dart';
import 'equalizer_service.dart';
import 'library_data_service.dart';
import 'library_scan_service.dart';
import 'listening_stats_service.dart';
import 'playlist_service.dart';
import 'sleep_timer_service.dart';
import 'statistics_service.dart';
import '../../utils/app_log.dart';

/// Initializes data and audio in a fixed order (P06-01):
/// prefs/theme/locale (main) → DB → library → audio handler → stats/timer/EQ
/// → permission/sources. Auth runs detached and never blocks local listening.
/// Safe to re-run after a failure: every service is created at most once.
class BootstrapService {
  BootstrapService._();

  static Future<void>? _running;
  static bool _done = false;
  static bool get isReady => _done;

  static Future<void> run() {
    if (_done) return Future.value();
    return _running ??= _run().whenComplete(() => _running = null);
  }

  static T _ensure<T>(T Function() create) => Get.isRegistered<T>()
      ? Get.find<T>()
      : Get.put<T>(create(), permanent: true);

  static Future<void> _run() async {
    await DatabaseHelper().database.timeout(const Duration(seconds: 15));

    final library = _ensure(LibraryDataService.new);
    await library.reload();

    if (!Get.isRegistered<MuvikAudioHandler>()) {
      final handler = await AudioService.init(
        builder: () => MuvikAudioHandler(library: library),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.asctechsoft.muvik.playback',
          androidNotificationChannelName: 'Muvik',
          androidNotificationIcon: 'drawable/ic_stat_muvik',
          androidStopForegroundOnPause: true,
        ),
      ).timeout(const Duration(seconds: 15));
      Get.put(handler, permanent: true);
      await handler.init();

      final eq = _ensure(EqualizerService.new)..loadPrefs();
      handler.audioSessionId.addListener(
        () => eq.attach(handler.audioSessionId.value),
      );
      unawaited(eq.attach(handler.audioSessionId.value));

      final sleep = _ensure(
        () => SleepTimerService(
          isPlaying: () => handler.isPlaying,
          pausePlayback: handler.pause,
        ),
      )..restore();
      handler.sleepTimer = sleep;

      await _ensure(() => ListeningStatsService(handler: handler)).init();
    }

    _ensure(() => StatisticsService(library: library));
    _ensure(() => PlaylistService(library: library));

    final scan = _ensure(() => LibraryScanService(library: library));
    await scan.checkPermission();
    await scan.refreshSources();

    final auth = _ensure(AuthService.new);
    unawaited(
      auth.init().catchError((Object e) {
        AppLog.info('Auth init ignored: ${e.runtimeType}');
      }),
    );

    _ensure(LibraryController.new);
    _ensure(PlaybackController.new);
    _done = true;
    _backfillGenres(scan);
  }

  /// Libraries scanned before DB v2 have no genre; rescan once in the
  /// background (same as "Quét lại", nothing is deleted).
  static void _backfillGenres(LibraryScanService scan) {
    final due =
        PrefStore.getBool(
          PrefConst.setupCompleted,
          PrefDefaults.setupCompleted,
        ) &&
        !PrefStore.getBool(
          PrefConst.genreBackfillDone,
          PrefDefaults.genreBackfillDone,
        ) &&
        scan.permission.value == AudioPermissionStatus.granted;
    if (!due) return;
    unawaited(
      scan.scan().then((s) async {
        if (s.isFinished) {
          await PrefStore.setBool(PrefConst.genreBackfillDone, true);
        }
      }),
    );
  }
}
