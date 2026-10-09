import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/models/data_models/song.dart';
import 'package:muvik/utils/mood_rules.dart';

Song _s(String? genre) => Song(
  sourceId: 1,
  identity: genre ?? 'none',
  uri: 'content://x',
  title: 't',
  folderPath: 'Music',
  fileName: 't.mp3',
  firstSeenAt: DateTime(2026),
  updatedAt: DateTime(2026),
  genre: genre,
);

void main() {
  test('genre keywords map to moods', () {
    expect(Mood.calm.matches(_s('Acoustic')), isTrue);
    expect(Mood.calm.matches(_s('Nhạc Trữ Tình')), isTrue);
    expect(Mood.focus.matches(_s('Lo-Fi Beats')), isTrue);
    expect(Mood.focus.matches(_s('Classical')), isTrue);
    expect(Mood.energetic.matches(_s('EDM')), isTrue);
    expect(Mood.energetic.matches(_s('K-Pop')), isTrue);
  });

  test('keywords match whole words only', () {
    expect(Mood.energetic.matches(_s('Popcorn')), isFalse);
    expect(Mood.focus.matches(_s('Post-Rock')), isTrue);
    expect(Mood.focus.matches(_s('Postman')), isFalse);
  });

  test('songs without a genre match no mood', () {
    for (final m in Mood.values) {
      expect(m.matches(_s(null)), isFalse);
      expect(m.matches(_s('')), isFalse);
    }
  });
}
