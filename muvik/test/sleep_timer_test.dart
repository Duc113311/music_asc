import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/configs/pref_const.dart';
import 'package:muvik/services/application/sleep_timer_service.dart';
import 'package:muvik/services/storage/pref_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late bool playing;
  late int pauses;
  late SleepTimerService s;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PrefStore.init();
    await PrefStore.setInt(PrefConst.sleepDeadline, 0);
    playing = true;
    pauses = 0;
    s = SleepTimerService(
      isPlaying: () => playing,
      pausePlayback: () async => pauses++,
    );
  });

  tearDown(() => s.dispose());

  group('SleepTimerService (P19-06)', () {
    test('stores a deadline and computes remaining from it', () async {
      final now = DateTime(2026, 10, 7, 22);
      await s.start(const Duration(minutes: 30), waitTrackEnd: false, now: now);
      expect(s.state.value.deadline, now.add(const Duration(minutes: 30)));
      expect(
        s.state.value.remaining(now.add(const Duration(minutes: 10))),
        const Duration(minutes: 20),
      );
      expect(PrefStore.getInt(PrefConst.sleepDeadline, 0), greaterThan(0));
    });

    test('rejects 0 and more than 12 h', () async {
      expect(
        () => s.start(Duration.zero, waitTrackEnd: false),
        throwsArgumentError,
      );
      expect(
        () => s.start(const Duration(hours: 13), waitTrackEnd: false),
        throwsArgumentError,
      );
    });

    test(
      'due while playing pauses immediately without wait-track-end',
      () async {
        await s.start(const Duration(minutes: 1), waitTrackEnd: false);
        await s.onDeadline();
        expect(pauses, 1);
        expect(s.state.value.active, isFalse);
      },
    );

    test('due while paused stays paused and clears', () async {
      playing = false;
      await s.start(const Duration(minutes: 1), waitTrackEnd: true);
      await s.onDeadline();
      expect(pauses, 0);
      expect(s.state.value.active, isFalse);
    });

    test(
      'wait-track-end blocks auto-advance until the boundary, once',
      () async {
        await s.start(const Duration(minutes: 1), waitTrackEnd: true);
        await s.onDeadline();
        expect(pauses, 0);
        expect(s.blocksAutoAdvance, isTrue);
        expect(s.consumeStopAtTrackBoundary(), isTrue);
        expect(s.consumeStopAtTrackBoundary(), isFalse);
        expect(s.state.value.active, isFalse);
      },
    );

    test('new timer replaces the old one; cancel clears storage', () async {
      final now = DateTime(2026, 10, 7, 22);
      await s.start(const Duration(minutes: 15), waitTrackEnd: false, now: now);
      await s.start(const Duration(minutes: 45), waitTrackEnd: false, now: now);
      expect(s.state.value.deadline, now.add(const Duration(minutes: 45)));
      await s.cancel();
      expect(s.state.value.active, isFalse);
      expect(PrefStore.getInt(PrefConst.sleepDeadline, -1), 0);
    });

    test('restore: past deadline is cleared, future one resumes', () async {
      final now = DateTime(2026, 10, 7, 22);
      await PrefStore.setInt(
        PrefConst.sleepDeadline,
        now.subtract(const Duration(minutes: 1)).toUtc().millisecondsSinceEpoch,
      );
      s.restore(now: now);
      expect(s.state.value.active, isFalse);
      expect(PrefStore.getInt(PrefConst.sleepDeadline, -1), 0);

      final future = now.add(const Duration(minutes: 20));
      await PrefStore.setInt(
        PrefConst.sleepDeadline,
        future.toUtc().millisecondsSinceEpoch,
      );
      s.restore(now: now);
      expect(s.state.value.deadline, future);
    });
  });
}
