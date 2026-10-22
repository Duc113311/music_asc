import 'dart:collection';

import '../../models/data_models/lyrics.dart';
import '../native/media_library_channel.dart';

/// Loads lyrics embedded in the audio file, with a small cache so swiping
/// back and forth (or replaying a song) does not re-read the file.
class LyricsService {
  LyricsService._();

  static const _maxEntries = 24;
  static final LinkedHashMap<String, Lyrics?> _cache = LinkedHashMap();
  static final Map<String, Future<Lyrics?>> _pending = {};

  static Future<Lyrics?> load(String uri) {
    if (_cache.containsKey(uri)) {
      final v = _cache.remove(uri);
      _cache[uri] = v;
      return Future.value(v);
    }
    return _pending[uri] ??= MediaLibraryChannel.getLyrics(uri).then((raw) {
      final lyrics = Lyrics.parse(raw);
      _cache[uri] = lyrics;
      while (_cache.length > _maxEntries) {
        _cache.remove(_cache.keys.first);
      }
      return lyrics;
    }).whenComplete(() => _pending.remove(uri));
  }
}
