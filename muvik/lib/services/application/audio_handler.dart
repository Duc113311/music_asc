import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../configs/app_config.dart';
import '../../configs/pref_const.dart';
import '../../configs/pref_defaults.dart';
import '../../models/data_models/playback_snapshot.dart';
import '../../models/data_models/song.dart';
import '../../models/ui_models/app_error.dart';
import '../../models/ui_models/repeat_mode.dart';
import '../../models/ui_models/shuffle_mode.dart';
import '../../repository/playback_repository.dart';
import '../native/media_library_channel.dart';
import '../native/system_ui_channel.dart';
import '../storage/database_helper.dart';
import '../storage/pref_store.dart';
import 'library_data_service.dart';
import 'play_queue.dart';
import 'sleep_timer_service.dart';
import '../../utils/app_log.dart';

/// Immutable view of the player for the app UI.
@immutable
class PlayerViewState {
  const PlayerViewState({
    this.entries = const [],
    this.index = -1,
    this.currentSong,
    this.playing = false,
    this.loading = false,
    this.repeat = RepeatMode.off,
    this.shuffle = false,
    this.duration,
    this.sourceLoaded = false,
  });

  final List<QueueEntry> entries;
  final int index;
  final Song? currentSong;
  final bool playing;
  final bool loading;
  final RepeatMode repeat;
  final bool shuffle;

  /// Known duration; null locks seeking (P07-06).
  final Duration? duration;
  final bool sourceLoaded;

  QueueEntry? get current =>
      (index >= 0 && index < entries.length) ? entries[index] : null;
  List<QueueEntry> get upcoming =>
      index < 0 ? entries : entries.sublist(index + 1);
  bool get hasSong => currentSong != null;
}

enum PlayerEventType { trackStarted, trackCompleted, trackLeft, stopped, error }

class PlayerEvent {
  const PlayerEvent(
    this.type, {
    this.songId,
    this.durationMs = 0,
    this.generation = 0,
    this.error,
  });
  final PlayerEventType type;
  final int? songId;
  final int durationMs;
  final int generation;
  final AppErrorCode? error;
}

/// The one audio engine + queue for the whole app (P01-09, P07-01). UI,
/// notification, lock screen and headset buttons all call into this handler.
class MuvikAudioHandler extends BaseAudioHandler with SeekHandler {
  MuvikAudioHandler({required this.library, PlaybackRepository? repository})
      : _repo = repository ?? PlaybackRepository();

  final LibraryDataService library;
  final PlaybackRepository _repo;
  final AudioPlayer _player = AudioPlayer(handleInterruptions: false);
  final PlayQueue _queue = PlayQueue();

  final ValueNotifier<PlayerViewState> view = ValueNotifier(
    const PlayerViewState(),
  );
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final StreamController<PlayerEvent> _events =
      StreamController<PlayerEvent>.broadcast();
  Stream<PlayerEvent> get events => _events.stream;

  /// Audible = playing and ready (not buffering/paused); drives statistics.
  final ValueNotifier<bool> audible = ValueNotifier(false);

  /// Android audio session id for the equalizer.
  final ValueNotifier<int?> audioSessionId = ValueNotifier(null);

  SleepTimerService? sleepTimer;

  int _loadToken = 0;
  String? _loadedEntryId;
  Duration _pendingPosition = Duration.zero;
  bool _loading = false;
  int _consecutiveFailures = 0;
  int _generation = 0;
  bool _pausedByInterruption = false;
  bool _pausedByNoisy = false;
  bool _handlingCompletion = false;
  Song? _currentSong;
  Timer? _snapshotTimer;
  bool _queueDirty = false;
  final List<StreamSubscription<dynamic>> _subs = [];

  bool get isPlaying => _player.playing;
  int get generation => _generation;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _subs.add(session.interruptionEventStream.listen(_onInterruption));
    _subs.add(session.becomingNoisyEventStream.listen((_) => _onNoisy()));
    _subs.add(session.devicesChangedEventStream.listen(_onDevicesChanged));

    _subs.add(
      _player.playbackEventStream.listen(
        (_) => _broadcast(),
        onError: _onPlayerStreamError,
      ),
    );
    _subs.add(_player.playingStream.listen((_) => _broadcast()));
    _subs.add(_player.processingStateStream.listen(_onProcessingState));
    _subs.add(
      _player.positionStream.listen((p) {
        if (_loadedEntryId != null) position.value = p;
      }),
    );
    _subs.add(
      _player.durationStream.listen((d) {
        _publish();
        final item = mediaItem.value;
        if (d != null && item != null && item.duration != d) {
          mediaItem.add(item.copyWith(duration: d));
        }
      }),
    );
    _subs.add(
      _player.androidAudioSessionIdStream.listen(
        (id) => audioSessionId.value = id,
      ),
    );

    await _restore();
  }

  // ------------------------------------------------------------ restore/save

  Future<void> _restore() async {
    try {
      final snap = await _repo.load();
      if (snap == null || snap.isEmpty) {
        _queue.repeat = RepeatMode.fromKey(
          PrefStore.getString(PrefConst.repeatMode, PrefDefaults.repeatMode),
        );
        _publish();
        return;
      }
      _queue.restore(snap);
      _pendingPosition = Duration(milliseconds: snap.positionMs);
      position.value = _pendingPosition;
      final cur = _queue.current;
      if (cur != null) {
        final song = (await library.resolve([cur.songId]))[cur.songId];
        _currentSong = song;
        if (song != null) mediaItem.add(_mediaItem(song, cur));
      }
    } catch (e, st) {
      AppLog.error('AudioHandler.restore', e, st);
    }
    _publish();
    _broadcast();
  }

  Future<void> _saveSnapshot({bool force = false}) async {
    try {
      final cur = _queue.current;
      final snap = PlaybackSnapshot(
        entries: _queue.entries,
        canonical: _queue.canonical,
        currentEntryId: cur?.entryId,
        positionMs:
            (_loadedEntryId != null ? _player.position : _pendingPosition)
                .inMilliseconds,
        repeatMode: _queue.repeat,
        shuffleMode: _queue.shuffle ? ShuffleMode.on : ShuffleMode.off,
        updatedAt: DateTime.now(),
      );
      final db = await DatabaseHelper().database;
      final writeQueue = _queueDirty || force;
      await db.transaction((txn) async {
        await _repo.writeHeader(snap, exec: txn);
        if (writeQueue) await _repo.replaceQueue(snap, exec: txn);
      });
      if (writeQueue) _queueDirty = false;
    } catch (e, st) {
      AppLog.error('AudioHandler.saveSnapshot', e, st);
    }
  }

  void _queueChanged() {
    _queueDirty = true;
    _publish();
    _saveSnapshot();
  }

  void _startSnapshotTimer() {
    _snapshotTimer ??= Timer.periodic(
      AppConfig.snapshotThrottle,
      (_) => _saveSnapshot(),
    );
  }

  void _stopSnapshotTimer() {
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
  }

  // ------------------------------------------------------------ public API

  /// Plays a snapshot of [songIds] starting at [startIndex].
  Future<void> playSongs(
    List<int> songIds, {
    int startIndex = 0,
    bool shuffle = false,
  }) async {
    if (songIds.isEmpty) return;
    _leaveCurrent();
    _queue.load(songIds, startIndex: startIndex, shuffle: shuffle);
    _queueChanged();
    await _loadCurrent(play: true, position: Duration.zero);
  }

  /// Opens the entry if it's already current, otherwise jumps to it.
  Future<void> playEntry(String entryId) async {
    if (_queue.current?.entryId == entryId) {
      if (!_player.playing) await play();
      return;
    }
    _leaveCurrent();
    if (!_queue.jumpToEntry(entryId)) return;
    if (_stopIfSleepBoundary()) return;
    _publish();
    await _loadCurrent(play: true, position: Duration.zero);
  }

  @override
  Future<void> play() async {
    if (_queue.current == null) return;
    if (_loadedEntryId != _queue.current!.entryId) {
      await _loadCurrent(play: true, position: _pendingPosition);
      return;
    }
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
      _generation++;
      _emitTrackStarted();
    }
    _startSnapshotTimer();
    unawaited(_player.play());
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _stopSnapshotTimer();
    await _saveSnapshot();
  }

  /// "Dừng phát": ends the session and saves; the current song stays in the
  /// mini player, paused (P07-15).
  @override
  Future<void> stop() async {
    _pendingPosition =
        _loadedEntryId != null ? _player.position : _pendingPosition;
    _events.add(const PlayerEvent(PlayerEventType.stopped));
    _stopSnapshotTimer();
    await _player.stop();
    _loadedEntryId = null;
    position.value = _pendingPosition;
    await _saveSnapshot();
    _publish();
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    final d = view.value.duration;
    if (d == null && _loadedEntryId != null) return;
    var p = position < Duration.zero ? Duration.zero : position;
    if (d != null && p > d) p = d;
    if (_loadedEntryId != null) {
      await _player.seek(p);
    } else {
      _pendingPosition = p;
      this.position.value = p;
    }
    await _saveSnapshot();
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    final next = _queue.peekNext(userInitiated: true);
    if (next == null) return;
    final wasPlaying = _player.playing;
    _leaveCurrent();
    if (_stopIfSleepBoundary()) return;
    _queue.moveNext(userInitiated: true);
    _publish();
    await _loadCurrent(play: wasPlaying, position: Duration.zero);
  }

  /// >3 s into the track restarts it; otherwise goes to the previous entry
  /// (P07-07).
  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    final pos = _loadedEntryId != null ? _player.position : _pendingPosition;
    if (pos > AppConfig.previousRestartThreshold ||
        _queue.peekPrevious() == null) {
      await seek(Duration.zero);
      return;
    }
    final wasPlaying = _player.playing;
    _leaveCurrent();
    if (_stopIfSleepBoundary()) return;
    _queue.movePrevious();
    _publish();
    await _loadCurrent(play: wasPlaying, position: Duration.zero);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final entries = _queue.entries;
    if (index < 0 || index >= entries.length) return;
    await playEntry(entries[index].entryId);
  }

  Future<void> addNext(List<int> songIds) async {
    for (final id in songIds.reversed) {
      _queue.addNext(id);
    }
    _queueChanged();
  }

  Future<void> addEnd(List<int> songIds) async {
    for (final id in songIds) {
      _queue.addEnd(id);
    }
    _queueChanged();
  }

  Future<bool> removeEntry(String entryId) async {
    final ok = _queue.remove(entryId);
    if (ok) _queueChanged();
    return ok;
  }

  /// Re-inserts an entry removed via the queue sheet (Undo snackbar).
  Future<void> reinsertAfterCurrent(int songId, int upcomingIndex) async {
    _queue.addEnd(songId);
    final upcoming = _queue.upcoming.length;
    _queue.reorderUpcoming(upcoming - 1, upcomingIndex.clamp(0, upcoming - 1));
    _queueChanged();
  }

  Future<void> reorderUpcoming(int oldIndex, int newIndex) async {
    _queue.reorderUpcoming(oldIndex, newIndex);
    _queueChanged();
  }

  Future<int> clearUpcoming() async {
    final n = _queue.clearUpcoming();
    _queueChanged();
    return n;
  }

  Future<void> setShuffle(bool on) async {
    _queue.setShuffle(on);
    await PrefStore.setString(
      PrefConst.shuffleMode,
      on ? ShuffleMode.on.key : ShuffleMode.off.key,
    );
    _queueChanged();
    _broadcast();
  }

  Future<void> setRepeat(RepeatMode mode) async {
    _queue.repeat = mode;
    await PrefStore.setString(PrefConst.repeatMode, mode.key);
    _publish();
    _broadcast();
    await _saveSnapshot();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) =>
      setShuffle(shuffleMode != AudioServiceShuffleMode.none);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) {
    switch (repeatMode) {
      case AudioServiceRepeatMode.one:
        return setRepeat(RepeatMode.one);
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        return setRepeat(RepeatMode.all);
      case AudioServiceRepeatMode.none:
        return setRepeat(RepeatMode.off);
    }
  }

  /// A song left the library (excluded/unavailable). Its queue entries are
  /// dropped; if it is current, playback moves on or stops (P07-16).
  Future<void> onSongRemoved(int songId) async {
    final isCurrent = _queue.current?.songId == songId;
    _queue.removeSong(songId);
    if (!isCurrent) {
      _queueChanged();
      return;
    }
    final next = _queue.peekNext(userInitiated: true);
    final wasPlaying = _player.playing;
    if (next == null || _queue.entries[next].songId == songId) {
      await _player.stop();
      _queue.clear();
      _loadedEntryId = null;
      _currentSong = null;
      mediaItem.add(null);
      _queueChanged();
      await super.stop();
      return;
    }
    final removedId = _queue.current!.entryId;
    _leaveCurrent();
    _queue.moveNext(userInitiated: true);
    _queue.remove(removedId);
    _queueChanged();
    await _loadCurrent(play: wasPlaying, position: Duration.zero);
  }

  /// Library metadata/favorite changed: refresh the current song object.
  Future<void> refreshCurrentSong() async {
    final cur = _queue.current;
    if (cur == null) return;
    final s = await library.get(cur.songId);
    if (s == null) return;
    _currentSong = s;
    _publish();
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    if (!PrefStore.getBool(
      PrefConst.headphoneButtonsEnabled,
      PrefDefaults.headphoneButtonsEnabled,
    )) {
      return;
    }
    await super.click(button);
  }

  @override
  Future<void> onTaskRemoved() async {
    // Keep the (dismissible) notification once a song is loaded, so the
    // controls survive swiping the app away; only an empty player stops.
    if (!_player.playing && _loadedEntryId == null) await stop();
  }

  // ------------------------------------------------------------ loading

  /// How long a track may take to open before it counts as unplayable.
  static const Duration _loadTimeout = Duration(seconds: 12);

  Future<void> _loadCurrent({
    required bool play,
    required Duration position,
  }) async {
    final entry = _queue.current;
    if (entry == null) return;
    final token = ++_loadToken;
    _loading = true;
    _publish();
    final song = (await library.resolve([entry.songId]))[entry.songId];
    if (token != _loadToken) return;
    _currentSong = song;
    if (song == null || !song.available) {
      _loading = false;
      await _handleFailure(AppErrorCode.fileUnavailable, play);
      return;
    }
    mediaItem.add(_mediaItem(song, entry));
    _publish();
    try {
      // A file the decoder never finishes opening (broken header, a very short
      // or truncated MP3...) must not leave the notification spinning forever
      // when the previous track ended with the screen off: give up after
      // [_loadTimeout], report it and go on to the next song.
      await _player
          .setAudioSource(
            AudioSource.uri(Uri.parse(song.uri)),
            initialPosition: position,
          )
          .timeout(
            _loadTimeout,
            onTimeout: () =>
                throw TimeoutException('load timed out', _loadTimeout),
          );
    } catch (e) {
      AppLog.info('AudioHandler.load ${song.uri}: $e');
      if (token != _loadToken) return;
      _loading = false;
      await _handleFailure(AppErrorCode.playbackFailed, play);
      return;
    }
    if (token != _loadToken) return;
    _loadedEntryId = entry.entryId;
    _pendingPosition = Duration.zero;
    _consecutiveFailures = 0;
    _loading = false;
    this.position.value = position;
    _publish();
    if (play) {
      _generation++;
      _emitTrackStarted();
      _startSnapshotTimer();
      unawaited(_player.play());
    }
    unawaited(_saveSnapshot());
    unawaited(_updateArtwork(song, entry));
  }

  /// Unplayable entry: report and skip, but never loop more than one round of
  /// the queue (P07-12).
  Future<void> _handleFailure(AppErrorCode code, bool autoplay) async {
    _consecutiveFailures++;
    final exhausted = _consecutiveFailures >= _queue.length;
    _events.add(
      PlayerEvent(
        PlayerEventType.error,
        error: exhausted ? AppErrorCode.queueAllFailed : code,
      ),
    );
    final next = _queue.peekNext(userInitiated: true);
    if (!autoplay || exhausted || next == null) {
      _consecutiveFailures = 0;
      await _player.stop();
      _loadedEntryId = null;
      _publish();
      _broadcast();
      return;
    }
    _queue.moveNext(userInitiated: true);
    _publish();
    await _loadCurrent(play: true, position: Duration.zero);
  }

  void _onProcessingState(ProcessingState s) {
    _updateAudible();
    if (s == ProcessingState.completed) unawaited(_onCompleted());
  }

  Future<void> _onCompleted() async {
    if (_handlingCompletion || _loadedEntryId == null) return;
    _handlingCompletion = true;
    // The next track is opened from Dart; keep the CPU awake meanwhile.
    unawaited(SystemUiChannel.holdCpu());
    try {
      _events.add(
        PlayerEvent(
          PlayerEventType.trackCompleted,
          songId: _currentSong?.id,
          generation: _generation,
        ),
      );
      // Sleep timer outranks repeat/autoplay (P13-06).
      if (sleepTimer?.consumeStopAtTrackBoundary() ?? false) {
        await _player.pause();
        await _player.seek(Duration.zero);
        _stopSnapshotTimer();
        await _saveSnapshot();
        return;
      }
      final before = _queue.index;
      final next = _queue.moveNext(userInitiated: false);
      if (next == null) {
        // End of queue with repeat off: stop naturally on the last track.
        await _player.pause();
        await _player.seek(Duration.zero);
        _stopSnapshotTimer();
        await _saveSnapshot();
        _publish();
        return;
      }
      if (_queue.index == before) {
        await _player.seek(Duration.zero);
        _generation++;
        _emitTrackStarted();
        unawaited(_player.play());
        return;
      }
      _publish();
      await _loadCurrent(play: true, position: Duration.zero);
    } finally {
      _handlingCompletion = false;
    }
  }

  /// The listener leaves the current track before it ends (skip, new queue).
  void _leaveCurrent() {
    if (_loadedEntryId != null) {
      _events.add(
        PlayerEvent(
          PlayerEventType.trackLeft,
          songId: _currentSong?.id,
          generation: _generation,
        ),
      );
    }
  }

  bool _stopIfSleepBoundary() {
    if (sleepTimer?.consumeStopAtTrackBoundary() ?? false) {
      unawaited(pause());
      return true;
    }
    return false;
  }

  void _emitTrackStarted() {
    final s = _currentSong;
    if (s == null) return;
    _events.add(
      PlayerEvent(
        PlayerEventType.trackStarted,
        songId: s.id,
        durationMs: _player.duration?.inMilliseconds ?? s.durationMs,
        generation: _generation,
      ),
    );
  }

  void _onPlayerStreamError(Object e, StackTrace st) {
    AppLog.info('AudioHandler player error: $e');
    unawaited(_handleFailure(AppErrorCode.playbackFailed, _player.playing));
  }

  // ------------------------------------------------------------ OS integration

  void _onInterruption(AudioInterruptionEvent e) {
    if (e.begin) {
      switch (e.type) {
        case AudioInterruptionType.duck:
          _player.setVolume(0.3);
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          if (_player.playing) {
            _pausedByInterruption = e.type == AudioInterruptionType.pause;
            unawaited(pause());
          }
      }
    } else {
      switch (e.type) {
        case AudioInterruptionType.duck:
          _player.setVolume(1.0);
        case AudioInterruptionType.pause:
          // Resume only what a transient interruption (e.g. a call) paused.
          if (_pausedByInterruption) unawaited(play());
          _pausedByInterruption = false;
        case AudioInterruptionType.unknown:
          _pausedByInterruption = false;
      }
    }
  }

  void _onNoisy() {
    if (!PrefStore.getBool(
      PrefConst.headphonePauseOnDisconnect,
      PrefDefaults.headphonePauseOnDisconnect,
    )) {
      return;
    }
    if (_player.playing) {
      _pausedByNoisy = true;
      unawaited(pause());
    }
  }

  void _onDevicesChanged(AudioDevicesChangedEvent e) {
    if (!_pausedByNoisy) return;
    if (!PrefStore.getBool(
      PrefConst.headphoneResumeOnConnect,
      PrefDefaults.headphoneResumeOnConnect,
    )) {
      return;
    }
    final headset = e.devicesAdded.any((d) => isHeadsetDevice(d.type));
    if (headset) {
      _pausedByNoisy = false;
      unawaited(play());
    }
  }

  /// The only place reading `AudioDeviceType`, which audio_session marks
  /// @experimental: if its values change, only this list needs updating.
  /// Unknown types count as "not a headset" (speaker behaviour).
  // ignore: experimental_member_use
  static bool isHeadsetDevice(AudioDeviceType t) =>
      t == AudioDeviceType.wiredHeadset ||
      t == AudioDeviceType.wiredHeadphones ||
      t == AudioDeviceType.bluetoothA2dp ||
      t == AudioDeviceType.bluetoothSco ||
      t == AudioDeviceType.bluetoothLe ||
      t == AudioDeviceType.usbAudio;

  MediaItem _mediaItem(Song s, QueueEntry e) => MediaItem(
        id: s.uri,
        title: s.displayTitle,
        artist: s.artistOrNull,
        album: s.albumOrNull,
        duration: s.durationMs > 0 ? s.duration : null,
        extras: {'songId': s.id, 'entryId': e.entryId},
      );

  Future<void> _updateArtwork(Song s, QueueEntry e) async {
    try {
      final dir = Directory('${(await getTemporaryDirectory()).path}/art');
      final file = File('${dir.path}/${s.id}.jpg');
      if (!await file.exists()) {
        final bytes = await MediaLibraryChannel.getArtwork(s.uri, size: 512);
        if (bytes == null) return;
        await dir.create(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
      }
      if (_queue.current?.entryId != e.entryId) return;
      final item = mediaItem.value;
      if (item != null) {
        mediaItem.add(item.copyWith(artUri: Uri.file(file.path)));
      }
    } catch (err) {
      AppLog.info('AudioHandler.artwork: $err');
    }
  }

  void _updateAudible() {
    audible.value = _player.playing &&
        _player.processingState == ProcessingState.ready &&
        _loadedEntryId != null;
  }

  void _publish() {
    view.value = PlayerViewState(
      entries: _queue.entries,
      index: _queue.index,
      currentSong: _currentSong,
      playing: _player.playing && _loadedEntryId != null,
      loading: _loading ||
          (_loadedEntryId != null &&
              (_player.processingState == ProcessingState.loading ||
                  _player.processingState == ProcessingState.buffering)),
      repeat: _queue.repeat,
      shuffle: _queue.shuffle,
      duration: _player.duration ??
          ((_currentSong?.durationMs ?? 0) > 0 ? _currentSong!.duration : null),
      sourceLoaded: _loadedEntryId != null,
    );
  }

  void _broadcast() {
    _updateAudible();
    _publish();
    final playing = _player.playing && _loadedEntryId != null;
    final loaded = _loadedEntryId != null;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: !loaded
            ? AudioProcessingState.idle
            : const {
                ProcessingState.idle: AudioProcessingState.idle,
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[_player.processingState]!,
        playing: playing,
        updatePosition: loaded ? _player.position : _pendingPosition,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _queue.index < 0 ? null : _queue.index,
        repeatMode: switch (_queue.repeat) {
          RepeatMode.off => AudioServiceRepeatMode.none,
          RepeatMode.all => AudioServiceRepeatMode.all,
          RepeatMode.one => AudioServiceRepeatMode.one,
        },
        shuffleMode: _queue.shuffle
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ),
    );
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _stopSnapshotTimer();
    await _player.dispose();
    await _events.close();
  }
}
