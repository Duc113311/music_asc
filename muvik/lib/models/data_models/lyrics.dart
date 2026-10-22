/// One lyric line; [time] is null for unsynced (plain) lyrics.
class LyricLine {
  const LyricLine(this.text, [this.time]);
  final String text;
  final Duration? time;
}

/// Lyrics of a song. [synced] lyrics carry LRC time stamps and follow the
/// playback position; plain lyrics are just scrollable text.
class Lyrics {
  const Lyrics(this.lines, {required this.synced});
  final List<LyricLine> lines;
  final bool synced;

  static final RegExp _stamp = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
  static final RegExp _meta = RegExp(r'^\[[a-zA-Z]{2,}:.*\]$');

  /// Parses LRC when the text has time stamps, otherwise plain lines.
  static Lyrics? parse(String? raw) {
    if (raw == null) return null;
    final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = <LyricLine>[];
    var synced = false;
    for (final line in text.split('\n')) {
      final stamps = _stamp.allMatches(line).toList();
      if (stamps.isEmpty) {
        final t = line.trim();
        if (t.isEmpty || _meta.hasMatch(t)) continue; // [ar:..] [ti:..] tags
        lines.add(LyricLine(t));
        continue;
      }
      synced = true;
      final body = line.substring(stamps.last.end).trim();
      for (final m in stamps) {
        final min = int.parse(m.group(1)!);
        final sec = int.parse(m.group(2)!);
        final frac = m.group(3);
        final ms = frac == null
            ? 0
            : int.parse(frac.padRight(3, '0').substring(0, 3));
        lines.add(
          LyricLine(
            body,
            Duration(minutes: min, seconds: sec, milliseconds: ms),
          ),
        );
      }
    }
    if (lines.isEmpty) return null;
    if (synced) {
      // Lines without a stamp (stray text) have no place in a synced view.
      final stamped = lines.where((l) => l.time != null).toList()
        ..sort((a, b) => a.time!.compareTo(b.time!));
      return Lyrics(stamped, synced: true);
    }
    return Lyrics(lines, synced: false);
  }

  /// Index of the line being sung at [position]; -1 before the first line.
  int indexAt(Duration position) {
    if (!synced) return -1;
    var lo = 0, hi = lines.length - 1, ans = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (lines[mid].time! <= position) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }
}
