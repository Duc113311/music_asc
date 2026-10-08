import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../configs/app_config.dart';
import '../../configs/pref_const.dart';
import '../../configs/pref_defaults.dart';
import '../storage/pref_store.dart';

@immutable
class SleepTimerState {
  const SleepTimerState({
    this.deadline,
    this.waitTrackEnd = false,
    this.waitingForTrackEnd = false,
  });

  /// Wall-clock deadline; null when no timer is set.
  final DateTime? deadline;
  final bool waitTrackEnd;

  /// Deadline passed while playing with "wait for track end": playback stops
  /// when the entry current at the deadline ends or is left.
  final bool waitingForTrackEnd;

  bool get active => deadline != null || waitingForTrackEnd;

  Duration remaining(DateTime now) {
    final d = deadline;
    if (d == null) return Duration.zero;
    final r = d.difference(now);
    return r.isNegative ? Duration.zero : r;
  }
}

/// Lives with the audio handler, not with any screen (P13-03).
///
/// Rules (P13-04..P13-09):
/// - The countdown is derived from a stored deadline; pausing never extends it.
/// - A new timer replaces the old one; there is never more than one.
/// - Timer > repeat/autoplay: once due, nothing auto-advances.
/// - With "wait for track end", the entry playing at the deadline finishes,
///   then playback pauses. If the user skips during the wait, playback pauses
///   at that moment instead of starting another track.
/// - Due while paused: stays paused and the timer is cleared.
/// - On restore, a deadline already in the past is cleared immediately — the
///   old duration is never restarted. Changing the device clock moves the
///   wall-clock deadline accordingly; the in-process timer still fires based
///   on the monotonic clock, whichever comes first.
class SleepTimerService {
  SleepTimerService({required this.isPlaying, required this.pausePlayback});

  /// Reads the player's playing flag.
  final bool Function() isPlaying;

  /// Pauses playback (used when the timer is due).
  final Future<void> Function() pausePlayback;

  final ValueNotifier<SleepTimerState> state = ValueNotifier(
    const SleepTimerState(),
  );

  Timer? _timer;

  void restore({DateTime? now}) {
    final t = now ?? DateTime.now();
    final ms = PrefStore.getInt(
      PrefConst.sleepDeadline,
      PrefDefaults.sleepDeadline,
    );
    final wait = PrefStore.getBool(
      PrefConst.sleepWaitTrackEnd,
      PrefDefaults.sleepWaitTrackEnd,
    );
    if (ms <= 0) return;
    final deadline = DateTime.fromMillisecondsSinceEpoch(
      ms,
      isUtc: true,
    ).toLocal();
    if (!deadline.isAfter(t)) {
      _clearStored();
      return;
    }
    state.value = SleepTimerState(deadline: deadline, waitTrackEnd: wait);
    _schedule(deadline.difference(t));
  }

  Future<void> start(
    Duration duration, {
    required bool waitTrackEnd,
    DateTime? now,
  }) async {
    final minutes = duration.inMinutes;
    if (minutes < AppConfig.sleepMinMinutes ||
        minutes > AppConfig.sleepMaxMinutes) {
      throw ArgumentError.value(duration, 'duration', 'out of range');
    }
    final t = now ?? DateTime.now();
    final deadline = t.add(duration);
    await PrefStore.setInt(
      PrefConst.sleepDeadline,
      deadline.toUtc().millisecondsSinceEpoch,
    );
    await PrefStore.setBool(PrefConst.sleepWaitTrackEnd, waitTrackEnd);
    await PrefStore.setInt(PrefConst.sleepLastMinutes, minutes);
    state.value = SleepTimerState(
      deadline: deadline,
      waitTrackEnd: waitTrackEnd,
    );
    _schedule(duration);
  }

  Future<void> cancel() async {
    _timer?.cancel();
    _timer = null;
    await _clearStored();
    state.value = const SleepTimerState();
  }

  void _schedule(Duration d) {
    _timer?.cancel();
    _timer = Timer(d, onDeadline);
  }

  @visibleForTesting
  Future<void> onDeadline() async {
    _timer = null;
    final s = state.value;
    await _clearStored();
    if (s.waitTrackEnd && isPlaying()) {
      state.value = const SleepTimerState(
        waitingForTrackEnd: true,
        waitTrackEnd: true,
      );
      return;
    }
    state.value = const SleepTimerState();
    if (isPlaying()) await pausePlayback();
  }

  /// Called by the audio handler before it would auto-advance or when the
  /// user leaves the current entry. Returns true if playback must stop now.
  bool consumeStopAtTrackBoundary() {
    if (!state.value.waitingForTrackEnd) return false;
    state.value = const SleepTimerState();
    return true;
  }

  /// True while the deadline has passed and we only wait for the track end;
  /// the handler must not apply repeat-one in this state.
  bool get blocksAutoAdvance => state.value.waitingForTrackEnd;

  Future<void> _clearStored() async {
    await PrefStore.setInt(PrefConst.sleepDeadline, 0);
  }

  void dispose() {
    _timer?.cancel();
    state.dispose();
  }
}
