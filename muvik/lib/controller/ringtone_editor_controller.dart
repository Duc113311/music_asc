import 'dart:async';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/data_models/song.dart';
import '../models/ui_models/ringtone_range.dart';
import '../presentation/common_components/primary_dialog.dart';
import '../services/native/media_library_channel.dart';
import '../services/native/ringtone_channel.dart';
import '../utils/app_log.dart';
import '../utils/toast_utils.dart';
import 'playback_controller.dart';

/// "Cắt nhạc chuông" editor: waveform, the chosen range, a preview of exactly
/// that range, and saving it (optionally as the phone's default sound).
class RingtoneEditorController extends GetxController {
  RingtoneEditorController(this.song);

  final Song song;

  final Rx<RingtoneRange> range = RingtoneRange.initial(0).obs;
  final RxList<double> peaks = <double>[].obs;
  final RxBool loadingWave = true.obs;
  final RxBool waveFailed = false.obs;
  final Rx<RingtoneType> type = RingtoneType.ringtone.obs;
  final RxBool busy = false.obs;
  final RxBool previewing = false.obs;

  /// Playhead (absolute ms in the song) while previewing, else null.
  final RxnInt playheadMs = RxnInt();

  AudioPlayer? _player;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void onInit() {
    super.onInit();
    // Until the real duration is known, trust the library's.
    range.value = RingtoneRange.initial(song.durationMs);
    _loadWaveform();
  }

  @override
  void onClose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _player?.dispose();
    super.onClose();
  }

  Future<void> _loadWaveform() async {
    loadingWave.value = true;
    waveFailed.value = false;
    try {
      final w = await RingtoneChannel.waveform(song.uri)
          .timeout(const Duration(seconds: 90));
      if (w.durationMs > 0 && w.durationMs != range.value.durationMs) {
        range.value = RingtoneRange.initial(w.durationMs);
      }
      peaks.assignAll(w.peaks);
    } catch (e) {
      AppLog.info('RingtoneEditor.waveform: $e');
      waveFailed.value = true;
    } finally {
      loadingWave.value = false;
    }
  }

  // ------------------------------------------------------------ range

  /// Any change of the range stops a running preview (it plays the old range).
  void _changed(RingtoneRange r) {
    if (r == range.value) return;
    if (previewing.value) unawaited(stopPreview());
    range.value = r;
  }

  void setStart(int ms) => _changed(range.value.withStart(ms));
  void setEnd(int ms) => _changed(range.value.withEnd(ms));
  void shiftBy(int deltaMs) => _changed(range.value.shifted(deltaMs));
  void setRange(RingtoneRange r) => _changed(r);

  void setType(RingtoneType t) => type.value = t;

  // ------------------------------------------------------------ preview

  Future<void> togglePreview() async {
    if (previewing.value) {
      await stopPreview();
      return;
    }
    // The main player must not play over the preview.
    if (Get.isRegistered<PlaybackController>()) {
      final pc = PlaybackController.to;
      if (pc.state.value.playing) await pc.handler.pause();
    }
    final r = range.value;
    final p = _player ??= AudioPlayer();
    try {
      await p.setAudioSource(AudioSource.uri(Uri.parse(song.uri)));
      await p.setClip(
        start: Duration(milliseconds: r.startMs),
        end: Duration(milliseconds: r.endMs),
      );
      _posSub?.cancel();
      _stateSub?.cancel();
      // With a clip the position counts from the clip's start.
      _posSub = p.positionStream.listen(
        (pos) => playheadMs.value = r.startMs + pos.inMilliseconds,
      );
      _stateSub = p.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed) {
          unawaited(stopPreview());
        }
      });
      previewing.value = true;
      unawaited(p.play());
    } catch (e) {
      AppLog.info('RingtoneEditor.preview: $e');
      previewing.value = false;
      playheadMs.value = null;
      ToastUtils.error('ringtone_failed'.tr);
    }
  }

  Future<void> stopPreview() async {
    previewing.value = false;
    playheadMs.value = null;
    try {
      await _player?.stop();
    } catch (_) {}
  }

  // ------------------------------------------------------------ saving

  /// Cuts and saves the clip. With [makeDefault] it also becomes the phone's
  /// sound of the chosen [type]; that needs "Modify system settings", which
  /// the user allows on a system page (opened here, once).
  Future<void> save({required bool makeDefault}) async {
    if (busy.value) return;
    await stopPreview();

    // Android 9 and older write the file themselves and need storage access.
    final sdk = await MediaLibraryChannel.sdkInt();
    if (sdk > 0 && sdk < 29) {
      final st = await Permission.storage.request();
      if (!st.isGranted) {
        ToastUtils.error('ringtone_storage_denied'.tr);
        return;
      }
    }

    if (makeDefault && !await RingtoneChannel.canWriteSettings()) {
      final open = await showConfirmDialog(
        title: 'ringtone_perm_title'.tr,
        message: 'ringtone_perm_msg'.tr,
        confirmLabel: 'ringtone_perm_open'.tr,
      );
      if (open) {
        await RingtoneChannel.openWriteSettings();
        ToastUtils.show('ringtone_perm_return'.tr);
      }
      return;
    }

    busy.value = true;
    try {
      final r = range.value;
      final clip = await RingtoneChannel.cut(
        uri: song.uri,
        startMs: r.startMs,
        endMs: r.endMs,
        name: '${song.displayTitle} (Muvik)',
        type: type.value,
      );
      if (makeDefault) {
        await RingtoneChannel.setDefault(clip.uri, type.value);
        ToastUtils.success('ringtone_done_${type.value.key}'.tr);
      } else {
        ToastUtils.success('ringtone_saved'.tr);
      }
    } on RingtoneException catch (e) {
      AppLog.info('RingtoneEditor.save: $e');
      if (e.needsWriteSettings) {
        ToastUtils.show('ringtone_perm_return'.tr);
      } else {
        ToastUtils.error('ringtone_failed'.tr);
      }
    } catch (e, st) {
      AppLog.error('RingtoneEditor.save', e, st);
      ToastUtils.error('ringtone_failed'.tr);
    } finally {
      busy.value = false;
    }
  }
}
