import '../ui_models/repeat_mode.dart';
import '../ui_models/shuffle_mode.dart';

/// One slot in the play queue. `entryId` is unique per slot so the same song
/// can appear multiple times (P04-06, P07-10).
class QueueEntry {
  const QueueEntry({required this.entryId, required this.songId});

  final String entryId;
  final int songId;

  @override
  bool operator ==(Object other) =>
      other is QueueEntry && other.entryId == entryId && other.songId == songId;

  @override
  int get hashCode => Object.hash(entryId, songId);

  @override
  String toString() => 'QueueEntry($entryId:$songId)';
}

/// Persisted player state, restored paused on next launch (P07-14).
class PlaybackSnapshot {
  const PlaybackSnapshot({
    required this.entries,
    required this.canonical,
    this.currentEntryId,
    this.positionMs = 0,
    this.repeatMode = RepeatMode.off,
    this.shuffleMode = ShuffleMode.off,
    required this.updatedAt,
  });

  /// Play order.
  final List<QueueEntry> entries;

  /// Natural (un-shuffled) order.
  final List<QueueEntry> canonical;
  final String? currentEntryId;
  final int positionMs;
  final RepeatMode repeatMode;
  final ShuffleMode shuffleMode;
  final DateTime updatedAt;

  bool get isEmpty => entries.isEmpty || currentEntryId == null;

  Map<String, Object?> headerMap() => {
    'id': 1,
    'current_entry_id': currentEntryId,
    'position_ms': positionMs,
    'repeat_mode': repeatMode.key,
    'shuffle_mode': shuffleMode.key,
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
}
