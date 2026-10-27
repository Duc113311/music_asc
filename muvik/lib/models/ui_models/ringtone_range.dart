import 'dart:math' as math;

/// The part of a song chosen for a ringtone, in milliseconds. Immutable; every
/// change returns a new, always valid range: inside the song and between
/// [minMs] and [maxMs] long (a song shorter than [minMs] can only be taken
/// whole).
class RingtoneRange {
  const RingtoneRange._(this.startMs, this.endMs, this.durationMs);

  static const int minMs = 3000;
  static const int maxMs = 180000;

  /// First suggested length of a clip.
  static const int defaultMs = 30000;

  final int startMs;
  final int endMs;
  final int durationMs;

  int get lengthMs => endMs - startMs;

  /// Shortest allowed clip for this song.
  int get _minLen => math.min(minMs, durationMs);

  /// Longest allowed clip for this song.
  int get _maxLen => math.min(maxMs, durationMs);

  /// A [defaultMs] clip starting a little way into the song (the intro is
  /// rarely the best part); the whole song when it is short.
  factory RingtoneRange.initial(int durationMs) {
    final d = math.max(0, durationMs);
    final len = math.min(defaultMs, d);
    final start = d > len + 15000 ? 15000 : 0;
    return RingtoneRange._(start, start + len, d);
  }

  RingtoneRange withStart(int ms) {
    // Keep the end; the start can go as far back as maxLen allows and as far
    // forward as minLen allows.
    final lo = math.max(0, endMs - _maxLen);
    final hi = endMs - _minLen;
    return RingtoneRange._(ms.clamp(lo, math.max(lo, hi)), endMs, durationMs);
  }

  RingtoneRange withEnd(int ms) {
    final lo = startMs + _minLen;
    final hi = math.min(durationMs, startMs + _maxLen);
    return RingtoneRange._(startMs, ms.clamp(lo, math.max(lo, hi)), durationMs);
  }

  /// Moves the whole clip by [deltaMs], keeping its length, inside the song.
  RingtoneRange shifted(int deltaMs) {
    final len = lengthMs;
    final start = (startMs + deltaMs).clamp(0, math.max(0, durationMs - len)).toInt();
    return RingtoneRange._(start, start + len, durationMs);
  }

  /// "0:07.5" style time for the readouts.
  static String format(int ms) {
    final total = math.max(0, ms);
    final m = total ~/ 60000;
    final s = (total % 60000) ~/ 1000;
    final t = (total % 1000) ~/ 100;
    return '$m:${s.toString().padLeft(2, '0')}.$t';
  }

  @override
  bool operator ==(Object other) =>
      other is RingtoneRange &&
      other.startMs == startMs &&
      other.endMs == endMs &&
      other.durationMs == durationMs;

  @override
  int get hashCode => Object.hash(startMs, endMs, durationMs);

  @override
  String toString() => 'RingtoneRange($startMs-$endMs of $durationMs)';
}
