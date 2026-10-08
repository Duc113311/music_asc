import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/services/application/listening_tracker.dart';

void main() {
  const qualify = 30000;
  late ListeningTracker t;
  setUp(() => t = ListeningTracker(qualifyMs: qualify));

  group('ListeningTracker (P19-04)', () {
    test('qualifies after 30 s of real listening, only once', () {
      final start = DateTime(2026, 10, 7, 10);
      t.start(1, 200000, start);
      t.addListened(29000, start.add(const Duration(seconds: 29)));
      expect(t.active!.qualified, isFalse);
      t.addListened(1000, start.add(const Duration(seconds: 30)));
      expect(t.active!.qualified, isTrue);
      expect(t.active!.qualifiedDateKey, '2026-10-07');
      t.addListened(60000, start.add(const Duration(seconds: 90)));
      expect(t.active!.qualified, isTrue);
      expect(t.active!.listenedMs, 90000);
    });

    test('short track counts only when it ends naturally', () {
      final now = DateTime(2026, 10, 7, 10);
      t.start(1, 20000, now);
      t.addListened(20000, now.add(const Duration(seconds: 20)));
      expect(t.active!.qualified, isFalse);
      final ended = t.completeNaturally(now.add(const Duration(seconds: 20)));
      expect(ended!.qualified, isTrue);
    });

    test('short track skipped before the end does not count', () {
      final now = DateTime(2026, 10, 7, 10);
      t.start(1, 20000, now);
      t.addListened(10000, now.add(const Duration(seconds: 10)));
      final ended = t.end(now.add(const Duration(seconds: 10)), 'skipped');
      expect(ended!.qualified, isFalse);
    });

    test('pause/resume does not create a new session (same active object)', () {
      final now = DateTime(2026, 10, 7, 10);
      t.start(1, 200000, now);
      final s = t.active;
      t.addListened(10000, now.add(const Duration(seconds: 10)));
      // paused: no time added; resumed later
      t.addListened(25000, now.add(const Duration(minutes: 5)));
      expect(identical(t.active, s), isTrue);
      expect(s!.listenedMs, 35000);
      expect(s.qualified, isTrue);
    });

    test('seeking adds nothing — only elapsed audible time counts', () {
      final now = DateTime(2026, 10, 7, 10);
      t.start(1, 300000, now);
      // User seeks to 4:00 but only 5 s were audible.
      t.addListened(5000, now.add(const Duration(seconds: 5)));
      expect(t.active!.listenedMs, 5000);
      expect(t.active!.qualified, isFalse);
    });

    test('a replay (repeat) is a new session', () {
      final now = DateTime(2026, 10, 7, 10);
      t.start(1, 40000, now);
      t.addListened(40000, now.add(const Duration(seconds: 40)));
      final first = t.completeNaturally(now.add(const Duration(seconds: 40)));
      t.start(1, 40000, now.add(const Duration(seconds: 40)));
      expect(first!.ended, isTrue);
      expect(identical(t.active, first), isFalse);
      expect(t.active!.listenedMs, 0);
    });

    test('listening across midnight is split into two days', () {
      final end = DateTime(2026, 10, 8, 0, 0, 20);
      t.start(1, 300000, DateTime(2026, 10, 7, 23, 59, 30));
      t.addListened(50000, end);
      final days = t.active!.perDayMs;
      expect(days['2026-10-07'], 30000);
      expect(days['2026-10-08'], 20000);
      expect(t.active!.qualifiedDateKey, '2026-10-08');
      expect(t.takeDirtyDays(), {'2026-10-07', '2026-10-08'});
    });

    test('ending twice is a no-op (duplicate callbacks)', () {
      final now = DateTime(2026, 10, 7, 10);
      t.start(1, 100000, now);
      expect(t.end(now, 'stopped'), isNotNull);
      expect(t.end(now, 'stopped'), isNull);
      expect(t.completeNaturally(now), isNull);
    });
  });
}
