import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/models/data_models/song.dart';
import 'package:muvik/utils/explore_collections.dart';

Song song(int i, {String? genre, String? artist, int ms = 200000, String folder = 'Music', String file = 'a.mp3'}) =>
    Song(
      id: i,
      sourceId: 1,
      identity: '$i',
      uri: 'u$i',
      title: 't$i',
      artist: artist,
      genre: genre,
      durationMs: ms,
      folderPath: folder,
      fileName: file,
      firstSeenAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

void main() {
  test('finds TikTok songs by folder or file name, even a single one', () {
    final r = ExploreCollections.build([
      song(1, folder: 'Download/TikTok'),
      song(2, file: 'snaptik_123.mp3'),
      song(3),
    ]);
    final t = r.firstWhere((c) => c.kind == ExploreKind.tiktok);
    expect(t.songs.map((s) => s.id), unorderedEquals([1, 2]));
  });

  test('genre/artist groups need enough songs and keep display names', () {
    final songs = [
      for (var i = 0; i < 6; i++) song(i, genre: 'Pop', artist: 'Sơn Tùng'),
      for (var i = 10; i < 13; i++) song(i, genre: 'Jazz', artist: 'Few'),
    ];
    final r = ExploreCollections.build(songs);
    final g = r.where((c) => c.kind == ExploreKind.genre).toList();
    expect(g.length, 1);
    expect(g.single.param, 'Pop');
    final a = r.where((c) => c.kind == ExploreKind.artist).toList();
    expect(a.single.param, 'Sơn Tùng');
  });

  test('quick / long split by duration; empty library gives nothing', () {
    final songs = [
      for (var i = 0; i < 5; i++) song(i, ms: 120000),
      for (var i = 10; i < 13; i++) song(i, ms: 8 * 60000),
    ];
    final kinds = ExploreCollections.build(songs).map((c) => c.kind).toSet();
    expect(kinds, containsAll([ExploreKind.quick, ExploreKind.long]));
    expect(ExploreCollections.build(const []), isEmpty);
  });
}
