import '../models/data_models/song.dart';
import 'metadata_fallback.dart';

/// Explore mood chips (sc_kham_pha). P11-04: no AI guessing — a song belongs
/// to a mood only when its genre tag contains one of the keywords below
/// (lower-case, Vietnamese diacritics removed). A song may match several
/// moods; songs without a genre tag match none.
enum Mood {
  calm('mood_calm', [
    'ballad',
    'acoustic',
    'chill',
    'jazz',
    'soul',
    'r&b',
    'rnb',
    'blues',
    'bolero',
    'tru tinh',
    'folk',
    'bossa',
    'soft',
    'easy listening',
    'singer-songwriter',
    'love song',
    'nhac tre',
  ]),
  focus('mood_focus', [
    'instrumental',
    'classical',
    'classic',
    'ambient',
    'piano',
    'lofi',
    'lo-fi',
    'soundtrack',
    'ost',
    'score',
    'new age',
    'meditation',
    'study',
    'cinematic',
    'orchestral',
    'post-rock',
    'khong loi',
  ]),
  energetic('mood_energetic', [
    'edm',
    'electronic',
    'electro',
    'dance',
    'house',
    'techno',
    'trance',
    'dubstep',
    'drum and bass',
    'dnb',
    'rock',
    'metal',
    'punk',
    'hip hop',
    'hip-hop',
    'hiphop',
    'rap',
    'trap',
    'remix',
    'pop',
    'k-pop',
    'kpop',
    'reggaeton',
    'latin',
    'funk',
    'disco',
    'vinahouse',
  ]);

  const Mood(this.labelKey, this.keywords);
  final String labelKey;
  final List<String> keywords;

  bool matches(Song s) {
    final g = s.genre;
    if (g == null || g.isEmpty) return false;
    final n = MetadataFallback.normalize(g);
    return keywords.any((k) => _containsWord(n, k));
  }

  /// Keyword must start and end at a word boundary, so "pop" does not match
  /// "popcorn" and "ost" does not match "post".
  static bool _containsWord(String text, String word) {
    var i = text.indexOf(word);
    while (i >= 0) {
      final before = i == 0 ? ' ' : text[i - 1];
      final end = i + word.length;
      final after = end >= text.length ? ' ' : text[end];
      if (!_isWordChar(before) && !_isWordChar(after)) return true;
      i = text.indexOf(word, i + 1);
    }
    return false;
  }

  static bool _isWordChar(String c) => RegExp(r'[a-z0-9]').hasMatch(c);
}
