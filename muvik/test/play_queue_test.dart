import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/models/data_models/playback_snapshot.dart';
import 'package:muvik/models/ui_models/repeat_mode.dart';
import 'package:muvik/models/ui_models/shuffle_mode.dart';
import 'package:muvik/services/application/play_queue.dart';

PlayQueue newQueue() {
  var n = 0;
  return PlayQueue(random: Random(1), idGenerator: () => 'e${n++}');
}

List<int> ids(List<QueueEntry> e) => e.map((x) => x.songId).toList();

void main() {
  group('PlayQueue (P19-03)', () {
    test('load snapshots ids and starts at the tapped index', () {
      final q = newQueue()..load([10, 20, 30], startIndex: 1);
      expect(q.current!.songId, 20);
      expect(ids(q.upcoming), [30]);
    });

    test('same song can appear several times with distinct entry ids', () {
      final q = newQueue()..load([1, 2]);
      q.addEnd(1);
      q.addNext(1);
      expect(ids(q.entries), [1, 1, 2, 1]);
      expect(q.entries.map((e) => e.entryId).toSet().length, 4);
    });

    test('remove uses entry id, never removes the current entry', () {
      final q = newQueue()..load([1, 2, 1]);
      final dup = q.entries[2];
      expect(q.remove(q.current!.entryId), isFalse);
      expect(q.remove(dup.entryId), isTrue);
      expect(ids(q.entries), [1, 2]);
    });

    test('reorder upcoming keeps the current entry in place', () {
      final q = newQueue()..load([1, 2, 3, 4], startIndex: 1);
      final cur = q.current;
      q.reorderUpcoming(1, 0); // [3,4] -> [4,3]
      expect(q.current, cur);
      expect(ids(q.upcoming), [4, 3]);
    });

    test('clear upcoming keeps current and history', () {
      final q = newQueue()..load([1, 2, 3, 4], startIndex: 1);
      expect(q.clearUpcoming(), 2);
      expect(ids(q.entries), [1, 2]);
      expect(q.current!.songId, 2);
    });

    test('repeat off: natural end of last entry stops', () {
      final q = newQueue()..load([1, 2], startIndex: 1);
      expect(q.peekNext(userInitiated: false), isNull);
    });

    test('repeat all wraps to the first entry', () {
      final q = newQueue()
        ..load([1, 2], startIndex: 1)
        ..repeat = RepeatMode.all;
      expect(q.moveNext(userInitiated: false)!.songId, 1);
    });

    test('repeat one replays only on natural end; Next still advances', () {
      final q = newQueue()
        ..load([1, 2, 3])
        ..repeat = RepeatMode.one;
      expect(q.peekNext(userInitiated: false), 0);
      expect(q.moveNext(userInitiated: true)!.songId, 2);
    });

    test('previous goes back, or wraps only with repeat all', () {
      final q = newQueue()..load([1, 2, 3]);
      expect(q.peekPrevious(), isNull);
      q.repeat = RepeatMode.all;
      expect(q.peekPrevious(), 2);
      q.repeat = RepeatMode.off;
      q.moveNext(userInitiated: true);
      expect(q.movePrevious()!.songId, 1);
    });

    test('shuffle keeps current first and restores natural order when off', () {
      final q = newQueue()..load([1, 2, 3, 4, 5], startIndex: 2);
      q.setShuffle(true);
      expect(q.index, 0);
      expect(q.current!.songId, 3);
      expect(ids(q.entries).toSet(), {1, 2, 3, 4, 5});
      q.setShuffle(false);
      expect(ids(q.entries), [1, 2, 3, 4, 5]);
      expect(q.current!.songId, 3);
    });

    test('entries added while shuffled survive turning shuffle off', () {
      final q = newQueue()..load([1, 2, 3]);
      q.setShuffle(true);
      q.addNext(9);
      q.setShuffle(false);
      expect(ids(q.entries), [1, 9, 2, 3]);
    });

    test('removeSong drops every entry of a song except current', () {
      final q = newQueue()..load([5, 6, 5, 7]);
      expect(q.removeSong(5), 1);
      expect(ids(q.entries), [5, 6, 7]);
      expect(q.current!.songId, 5);
    });

    test('restore from snapshot keeps both orders and current entry', () {
      final q = newQueue()..load([1, 2, 3], startIndex: 1);
      q.setShuffle(true);
      final snap = PlaybackSnapshot(
        entries: q.entries,
        canonical: q.canonical,
        currentEntryId: q.current!.entryId,
        repeatMode: RepeatMode.all,
        shuffleMode: ShuffleMode.on,
        updatedAt: DateTime(2026),
      );
      final r = newQueue()..restore(snap);
      expect(r.current!.songId, 2);
      expect(r.shuffle, isTrue);
      expect(r.repeat, RepeatMode.all);
      r.setShuffle(false);
      expect(ids(r.entries), [1, 2, 3]);
    });
  });
}
