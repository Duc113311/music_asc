import 'dart:math';

import '../../models/data_models/playback_snapshot.dart';
import '../../models/ui_models/repeat_mode.dart';

/// Pure queue model: play order, natural order, current index, repeat/shuffle.
/// Every position-based operation uses entry ids, never song ids (P07-10).
class PlayQueue {
  PlayQueue({Random? random, String Function()? idGenerator})
    : _random = random ?? Random(),
      _newId = idGenerator ?? _defaultId;

  final Random _random;
  final String Function() _newId;

  static int _counter = 0;
  static String _defaultId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${(_counter++).toRadixString(36)}';

  List<QueueEntry> _entries = [];
  List<QueueEntry> _canonical = [];
  int _index = -1;
  bool _shuffle = false;
  RepeatMode repeat = RepeatMode.off;

  List<QueueEntry> get entries => List.unmodifiable(_entries);
  List<QueueEntry> get canonical =>
      List.unmodifiable(_shuffle ? _canonical : _entries);
  int get index => _index;
  bool get shuffle => _shuffle;
  bool get isEmpty => _entries.isEmpty;
  int get length => _entries.length;

  QueueEntry? get current =>
      (_index >= 0 && _index < _entries.length) ? _entries[_index] : null;

  /// Entries after the current one, in play order.
  List<QueueEntry> get upcoming => _index < 0
      ? List.unmodifiable(_entries)
      : List.unmodifiable(_entries.sublist(_index + 1));

  /// Snapshot of [songIds] taken when the user taps a row: later filter or
  /// playlist edits never change this queue (P07-04).
  void load(List<int> songIds, {int startIndex = 0, bool? shuffle}) {
    final list = [
      for (final id in songIds) QueueEntry(entryId: _newId(), songId: id),
    ];
    _entries = list;
    _canonical = List.of(list);
    _index = list.isEmpty ? -1 : startIndex.clamp(0, list.length - 1);
    _shuffle = false;
    if (shuffle ?? false) setShuffle(true);
  }

  void restore(PlaybackSnapshot s) {
    _entries = List.of(s.entries);
    _canonical = s.canonical.isEmpty
        ? List.of(s.entries)
        : List.of(s.canonical);
    _shuffle = s.shuffleMode.enabled;
    repeat = s.repeatMode;
    _index = _entries.indexWhere((e) => e.entryId == s.currentEntryId);
    if (_index < 0 && _entries.isNotEmpty) _index = 0;
  }

  void clear() {
    _entries = [];
    _canonical = [];
    _index = -1;
  }

  bool jumpToEntry(String entryId) {
    final i = _entries.indexWhere((e) => e.entryId == entryId);
    if (i < 0) return false;
    _index = i;
    return true;
  }

  /// Next entry index or null when playback should stop.
  /// [userInitiated] Next always moves on even in repeat-one (P07-08).
  int? peekNext({required bool userInitiated}) {
    if (_entries.isEmpty) return null;
    if (!userInitiated && repeat == RepeatMode.one) return _index;
    if (_index < _entries.length - 1) return _index + 1;
    if (repeat == RepeatMode.all ||
        (userInitiated && repeat == RepeatMode.one)) {
      return 0;
    }
    return null;
  }

  QueueEntry? moveNext({required bool userInitiated}) {
    final n = peekNext(userInitiated: userInitiated);
    if (n == null) return null;
    _index = n;
    return current;
  }

  /// Previous entry index or null (caller restarts current track instead).
  int? peekPrevious() {
    if (_entries.isEmpty) return null;
    if (_index > 0) return _index - 1;
    if (repeat == RepeatMode.all) return _entries.length - 1;
    return null;
  }

  QueueEntry? movePrevious() {
    final p = peekPrevious();
    if (p == null) return null;
    _index = p;
    return current;
  }

  /// "Phát tiếp theo": insert right after the current entry.
  QueueEntry addNext(int songId) {
    final e = QueueEntry(entryId: _newId(), songId: songId);
    if (_entries.isEmpty) {
      _entries = [e];
      _canonical = [e];
      _index = 0;
      return e;
    }
    _entries.insert(_index + 1, e);
    if (_shuffle) {
      final ci = _canonical.indexWhere((x) => x.entryId == current?.entryId);
      _canonical.insert(ci + 1, e);
    }
    return e;
  }

  /// "Thêm hàng chờ": append at the end.
  QueueEntry addEnd(int songId) {
    final e = QueueEntry(entryId: _newId(), songId: songId);
    _entries.add(e);
    if (_shuffle) _canonical.add(e);
    if (_index < 0) _index = 0;
    return e;
  }

  /// Removes an upcoming/past entry. The current entry cannot be removed here.
  bool remove(String entryId) {
    final i = _entries.indexWhere((e) => e.entryId == entryId);
    if (i < 0 || i == _index) return false;
    _entries.removeAt(i);
    if (i < _index) _index--;
    _canonical.removeWhere((e) => e.entryId == entryId);
    return true;
  }

  /// Reorders within the upcoming list (indexes relative to [upcoming]).
  /// The current entry never moves, so playback is not interrupted (P07-11).
  void reorderUpcoming(int oldIndex, int newIndex) {
    final base = _index + 1;
    final from = base + oldIndex;
    var to = base + newIndex;
    if (from < base || from >= _entries.length) return;
    to = to.clamp(base, _entries.length - 1);
    final e = _entries.removeAt(from);
    _entries.insert(to, e);
    if (!_shuffle) _canonical = List.of(_entries);
  }

  /// "Xóa phần chờ": drops everything after the current entry.
  int clearUpcoming() {
    if (_index < 0) return 0;
    final removed = _entries.sublist(_index + 1);
    _entries = _entries.sublist(0, _index + 1);
    final ids = removed.map((e) => e.entryId).toSet();
    _canonical.removeWhere((e) => ids.contains(e.entryId));
    return removed.length;
  }

  /// Removes every entry of [songId] except the current one; returns count.
  int removeSong(int songId) {
    final cur = current;
    final before = _entries.length;
    _entries.removeWhere(
      (e) => e.songId == songId && e.entryId != cur?.entryId,
    );
    _canonical.removeWhere(
      (e) => e.songId == songId && e.entryId != cur?.entryId,
    );
    _index = cur == null
        ? -1
        : _entries.indexWhere((e) => e.entryId == cur.entryId);
    return before - _entries.length;
  }

  /// Shuffle keeps the current entry playing and shuffles the rest after it;
  /// turning it off restores the natural order (P07-09).
  void setShuffle(bool on) {
    if (on == _shuffle) return;
    final cur = current;
    if (on) {
      _canonical = List.of(_entries);
      final others = _entries.where((e) => e.entryId != cur?.entryId).toList()
        ..shuffle(_random);
      _entries = [?cur, ...others];
      _index = _entries.isEmpty ? -1 : 0;
    } else {
      _entries = List.of(_canonical);
      _index = cur == null
          ? (_entries.isEmpty ? -1 : 0)
          : _entries.indexWhere((e) => e.entryId == cur.entryId);
    }
    _shuffle = on;
  }
}
